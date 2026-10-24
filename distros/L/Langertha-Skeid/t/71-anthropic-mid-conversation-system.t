use strict;
use warnings;
use Test::More;
use Test::Mojo;
use MIME::Base64 qw(encode_base64);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# A system message inside `messages` on /v1/messages (k100). Claude Code sends one after the
# conversation started -- [user, system, ...] -- and a chat template that wants its system
# message first (Qwen3 on vLLM: "System message must be at the beginning.") or strictly
# alternating roles (Gemma) answers 400 when it is forwarded as an OpenAI system message at
# that position. So the node sees at most one system message, at index 0, made of the top-level
# `system` and the system messages before the first turn; a later one travels as
# <system-reminder> text of the adjacent user turn and never moves into the system message,
# which would change the prompt prefix on every turn. The assertions are on the messages the
# node receives.

my @upstream;
my $skeid = Langertha::Skeid->new(
  route_wait_timeout_ms => 100,
  route_wait_poll_ms    => 5,
  store_usage_event     => sub { return { ok => 1 } },
);
my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$app->log->level('fatal');
$app->routes->post('/__up/v1/chat/completions' => sub {
  my ($c) = @_;
  push @upstream, $c->req->json;
  $c->render(json => {
    id => 'c1', object => 'chat.completion', model => 'm',
    choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }],
    usage => { prompt_tokens => 1, completion_tokens => 1, total_tokens => 2 },
  });
});

my $t = Test::Mojo->new($app);
my $up = $t->ua->server->nb_url->clone->path('/__up/v1');
$skeid->add_node(id => 'n1', url => "$up", model => 'm', engine => 'openai', healthy => 1, max_conns => 2);

sub reminder { return "<system-reminder>\n" . $_[0] . "\n</system-reminder>" }

# The messages the node received for an Anthropic request. Whatever the case, a system message
# is the first message or it is not there, and the answers to an assistant's tool calls follow
# it with nothing in between.
sub forwarded {
  my ($name, %body) = @_;
  @upstream = ();
  $t->post_ok('/v1/messages' => json => { model => 'm', max_tokens => 16, %body })
    ->status_is(200, "$name: answered");
  is scalar(@upstream), 1, "$name: one upstream call" or return [];
  my $messages = $upstream[0]{messages};
  is_deeply [ grep { $messages->[$_]{role} eq 'system' } 1 .. $#$messages ], [],
    "$name: no system message after the first message";
  my ($open, $split) = (0, 0);
  for my $m (@$messages) {
    if ($m->{role} eq 'tool') { $open-- }
    else {
      $split++ if $open > 0;
      $open = $m->{role} eq 'assistant' ? scalar(@{ $m->{tool_calls} || [] }) : 0;
    }
  }
  is $split, 0, "$name: nothing between tool calls and their answers";
  return $messages;
}

my $PNG = encode_base64("\x89PNG\r\n\x1a\n\0\0\0\rIHDR", '');
my $image      = { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $PNG } };
my $image_part = { type => 'image_url', image_url => { url => "data:image/png;base64,$PNG" } };
my $tool_use   = { role => 'assistant', content => [
  { type => 'tool_use', id => 'toolu_1', name => 'ls', input => { path => '/' } } ] };
my $tool_calls = { role => 'assistant', tool_calls => [
  { id => 'toolu_1', type => 'function', function => { name => 'ls', arguments => '{"path":"/"}' } } ] };
my $tool_result = { role => 'user', content => [
  { type => 'tool_result', tool_use_id => 'toolu_1', content => 'bin etc' } ] };
my $tool = { role => 'tool', tool_call_id => 'toolu_1', content => 'bin etc' };

# --- after a user message: appended to it ---

is_deeply forwarded('after a user turn', system => 'S', messages => [
    { role => 'user', content => 'hi' },
    { role => 'system', content => 'Plan mode on' },
    { role => 'assistant', content => 'ok' },
    { role => 'user', content => 'next' },
  ]), [
    { role => 'system', content => 'S' },
    { role => 'user', content => "hi\n\n" . reminder('Plan mode on') },
    { role => 'assistant', content => 'ok' },
    { role => 'user', content => 'next' },
  ], 'a system message after a user turn becomes a reminder at the end of that turn';

is_deeply forwarded('block list', messages => [
    { role => 'user', content => [{ type => 'text', text => 'hi' }] },
    { role => 'system', content => [{ type => 'text', text => 'Plan ' }, { type => 'text', text => 'mode on' }] },
  ]), [
    { role => 'user', content => "hi\n\n" . reminder('Plan mode on') },
  ], 'a block list is read as its text blocks, joined like the top-level system';

is_deeply forwarded('two in a row after a user turn', messages => [
    { role => 'user', content => 'hi' },
    { role => 'system', content => 'one' },
    { role => 'system', content => 'two' },
  ]), [
    { role => 'user', content => "hi\n\n" . reminder('one') . "\n\n" . reminder('two') },
  ], 'two system messages in a row both end up in that user turn, in the order sent';

is_deeply forwarded('already wrapped', messages => [
    { role => 'user', content => 'hi' },
    { role => 'system', content => reminder('x') },
  ]), [
    { role => 'user', content => "hi\n\n" . reminder(reminder('x')) },
  ], 'the text is wrapped whatever it holds';

is_deeply forwarded('after a user turn with an image', messages => [
    { role => 'user', content => [{ type => 'text', text => 'what is this' }, $image] },
    { role => 'system', content => 'Plan mode on' },
  ]), [
    { role => 'user', content => [
      { type => 'text', text => 'what is this' }, $image_part,
      { type => 'text', text => reminder('Plan mode on') } ] },
  ], 'a user turn with image parts takes the reminder as a text part of its own, at the end';

# --- after an assistant message: in front of the next user message ---

is_deeply forwarded('before a user turn', messages => [
    { role => 'user', content => 'a' },
    { role => 'assistant', content => 'b' },
    { role => 'system', content => 'Plan mode on' },
    { role => 'user', content => 'c' },
  ]), [
    { role => 'user', content => 'a' },
    { role => 'assistant', content => 'b' },
    { role => 'user', content => reminder('Plan mode on') . "\n\nc" },
  ], 'a system message after an assistant turn goes in front of the user turn that follows';

is_deeply forwarded('before a user turn with an image', messages => [
    { role => 'user', content => 'a' },
    { role => 'assistant', content => 'b' },
    { role => 'system', content => 'one' },
    { role => 'system', content => 'two' },
    { role => 'user', content => [$image, { type => 'text', text => 'c' }] },
  ]), [
    { role => 'user', content => 'a' },
    { role => 'assistant', content => 'b' },
    { role => 'user', content => [
      { type => 'text', text => reminder('one') . "\n\n" . reminder('two') },
      $image_part, { type => 'text', text => 'c' } ] },
  ], 'in front of image parts the waiting reminders are one text part';

# --- no user turn next to it: a user message of its own ---

is_deeply forwarded('at the end after an assistant turn', messages => [
    { role => 'user', content => 'a' },
    { role => 'assistant', content => 'b' },
    { role => 'system', content => 'one' },
    { role => 'system', content => 'two' },
  ]), [
    { role => 'user', content => 'a' },
    { role => 'assistant', content => 'b' },
    { role => 'user', content => reminder('one') . "\n\n" . reminder('two') },
  ], 'with no user turn left the reminders are one user message at the end';

is_deeply forwarded('between two assistant turns', messages => [
    { role => 'user', content => 'a' },
    { role => 'assistant', content => 'b' },
    { role => 'system', content => 'Plan mode on' },
    { role => 'assistant', content => 'c' },
    { role => 'user', content => 'd' },
  ]), [
    { role => 'user', content => 'a' },
    { role => 'assistant', content => 'b' },
    { role => 'user', content => reminder('Plan mode on') },
    { role => 'assistant', content => 'c' },
    { role => 'user', content => 'd' },
  ], 'between two assistant turns it is a user message between them, not part of a later turn';

# --- tool calls and their answers stay together ---

is_deeply forwarded('between tool_use and tool_result', messages => [
    { role => 'user', content => 'a' },
    $tool_use,
    { role => 'system', content => 'Plan mode on' },
    $tool_result,
    { role => 'assistant', content => 'd' },
  ]), [
    { role => 'user', content => 'a' },
    $tool_calls,
    $tool,
    { role => 'user', content => reminder('Plan mode on') },
    { role => 'assistant', content => 'd' },
  ], 'a system message between tool calls and their results comes after the tool messages';

is_deeply forwarded('after a tool_result at the end', messages => [
    { role => 'user', content => 'a' },
    $tool_use,
    $tool_result,
    { role => 'system', content => 'Plan mode on' },
  ]), [
    { role => 'user', content => 'a' },
    $tool_calls,
    $tool,
    { role => 'user', content => reminder('Plan mode on') },
  ], 'a tool message takes no reminder: it is a user message after it';

is_deeply forwarded('before a tool_result with text', messages => [
    { role => 'user', content => 'a' },
    $tool_use,
    { role => 'system', content => 'Plan mode on' },
    { role => 'user', content => [ @{ $tool_result->{content} }, { type => 'text', text => 'and now?' } ] },
  ]), [
    { role => 'user', content => 'a' },
    $tool_calls,
    $tool,
    { role => 'user', content => reminder('Plan mode on') . "\n\nand now?" },
  ], 'the user text sent along with a tool_result takes the waiting reminder';

is_deeply forwarded('before a tool_result with images', messages => [
    { role => 'user', content => 'a' },
    $tool_use,
    { role => 'system', content => 'Plan mode on' },
    { role => 'user', content => [
      { type => 'tool_result', tool_use_id => 'toolu_1', content => [{ type => 'text', text => 'shot' }, $image] } ] },
    { role => 'system', content => 'Plan mode off' },
  ]), [
    { role => 'user', content => 'a' },
    $tool_calls,
    { role => 'tool', tool_call_id => 'toolu_1', content => '[{"text":"shot","type":"text"}]' },
    { role => 'user', content => [
      { type => 'text', text => reminder('Plan mode on') },
      { type => 'text', text => 'Images from tool result toolu_1:' }, $image_part,
      { type => 'text', text => reminder('Plan mode off') } ] },
  ], 'the user message holding a tool result\'s images takes reminders at either end';

# --- before the first turn: part of the one system message ---

is_deeply forwarded('leading, with a top-level system', system => 'S', messages => [
    { role => 'system', content => 'L1' },
    { role => 'system', content => [{ type => 'text', text => 'L' }, { type => 'text', text => '2' }] },
    { role => 'user', content => 'hi' },
    { role => 'system', content => 'later' },
  ]), [
    { role => 'system', content => "S\n\nL1\n\nL2" },
    { role => 'user', content => "hi\n\n" . reminder('later') },
  ], 'system messages before the first turn join the top-level system in one system message';

is_deeply forwarded('leading, with a top-level system block array', messages => [
    { role => 'system', content => 'L1' },
    { role => 'user', content => 'hi' },
  ], system => [{ type => 'text', text => 'A' }, { type => 'text', text => 'B' }]), [
    { role => 'system', content => "AB\n\nL1" },
    { role => 'user', content => 'hi' },
  ], 'the top-level system keeps its own joining';

is_deeply forwarded('leading, without a top-level system', messages => [
    { role => 'system', content => 'L1' },
    { role => 'system', content => 'L2' },
    { role => 'user', content => 'hi' },
  ]), [
    { role => 'system', content => "L1\n\nL2" },
    { role => 'user', content => 'hi' },
  ], 'without a top-level system they are the system message';

# --- nothing to say: no message ---

is_deeply forwarded('empty system messages', messages => [
    { role => 'system', content => '' },
    { role => 'system', content => [] },
    { role => 'user', content => 'hi' },
    { role => 'system', content => '' },
    { role => 'assistant', content => 'ok' },
    { role => 'system', content => [{ type => 'text', text => '' }] },
  ]), [
    { role => 'user', content => 'hi' },
    { role => 'assistant', content => 'ok' },
  ], 'a system message without text leaves no trace, leading or later';

# --- a request without one is translated as before ---

is_deeply forwarded('no system message in messages', system => 'S', messages => [
    { role => 'user', content => 'a' },
    $tool_use,
    { role => 'user', content => [
      { type => 'tool_result', tool_use_id => 'toolu_1', content => [{ type => 'text', text => 'shot' }, $image] },
      { type => 'text', text => 'see?' } ] },
    { role => 'assistant', content => [{ type => 'text', text => 'yes' }] },
    { role => 'user', content => [{ type => 'text', text => 'and this' }, $image] },
  ]), [
    { role => 'system', content => 'S' },
    { role => 'user', content => 'a' },
    $tool_calls,
    { role => 'tool', tool_call_id => 'toolu_1', content => '[{"text":"shot","type":"text"}]' },
    { role => 'user', content => [
      { type => 'text', text => 'Images from tool result toolu_1:' }, $image_part,
      { type => 'text', text => 'see?' } ] },
    { role => 'assistant', content => 'yes' },
    { role => 'user', content => [{ type => 'text', text => 'and this' }, $image_part] },
  ], 'a conversation without a system message: tool images and text of one message are one user message (k102)';

# k102: merge only inside one Anthropic message. Earlier turns do not change when a turn is
# added, and a reminder after a run of tool messages stays its own user message.
{
  my @turn1 = (
    { role => 'user', content => 'a' },
    $tool_use,
    { role => 'user', content => [
      { type => 'tool_result', tool_use_id => 'toolu_1', content => [{ type => 'text', text => 'shot' }, $image] },
      { type => 'text', text => 'see?' } ] },
  );
  my $first = forwarded('k102 turn 1', messages => [@turn1]);
  my $next  = forwarded('k102 turn 2', messages => [
    @turn1,
    { role => 'assistant', content => 'yes' },
    { role => 'user', content => 'more' },
  ]);
  is_deeply [ @{$next}[0 .. $#$first] ], $first, 'k102: earlier turns are forwarded unchanged';
  is scalar(grep { $_->{role} eq 'user' } @$first[ 2 .. $#$first ]), 1,
    'k102: images and text of the one message are a single user message';

  my $rem = forwarded('k102 reminder after tools', messages => [
    { role => 'user', content => 'a' },
    $tool_use,
    { role => 'user', content => [ { type => 'tool_result', tool_use_id => 'toolu_1', content => 'ok' } ] },
    { role => 'system', content => 'Plan mode on' },
  ]);
  is_deeply $rem->[-1], { role => 'user', content => reminder('Plan mode on') },
    'k102: the reminder after tool messages is its own user message, not merged';
}

# An empty top-level system string is dropped like an empty block array (k101).
for my $empty ('', []) {
  my $name = ref $empty ? 'an empty system block array' : 'an empty system string';
  is_deeply forwarded($name, system => $empty, messages => [{ role => 'user', content => 'hi' }]),
    [{ role => 'user', content => 'hi' }], "$name: no system message is forwarded";
}
is_deeply forwarded('a non-empty system string', system => 'S', messages => [{ role => 'user', content => 'hi' }]),
  [{ role => 'system', content => 'S' }, { role => 'user', content => 'hi' }],
  'a non-empty system string is forwarded as before';

done_testing;
