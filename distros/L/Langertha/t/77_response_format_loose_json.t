use strict;
use warnings;
use utf8;
use Test2::Bundle::More;

# decode_loose_json is now a Role method, callable via $engine->decode_loose_json($text).
# The test composes the role into a throwaway class so we can call it as a method.
{
  package T;
  use Moose;
  with 'Langertha::Role::ResponseFormat';
  __PACKAGE__->meta->make_immutable;
}

my $t = T->new;
sub decode { $t->decode_loose_json(@_) }

is_deeply( decode('{"a":1}'), { a => 1 }, 'plain JSON' );

is_deeply(
  decode("```json\n{\"a\":1,\"b\":\"x\"}\n```"),
  { a => 1, b => 'x' },
  'fenced ```json``` block',
);

is_deeply(
  decode("Sure! Here you go:\n```\n{\"a\":2}\n```\nHope that helps."),
  { a => 2 },
  'plain ``` fence with surrounding prose',
);

is_deeply(
  decode("The answer is {\"a\":3,\"b\":[1,2]} cheers."),
  { a => 3, b => [1,2] },
  'first {...} substring extracted from prose',
);

is( decode(undef), undef, 'undef in -> undef out' );
is( decode(''),    undef, 'empty in -> undef out' );
is( decode('totally not json'), undef, 'unparseable -> undef' );

# --- karr k161: two regression guards, both run under a hard OS-level timeout ---
#
# Both new bugs manifest through decode_loose_json's own eval-guarded strategies,
# and one of them (A2) is an INFINITE LOOP. A test for "does not hang" must not be
# able to hang the suite itself. `alarm` cannot do that here: decode_loose_json
# wraps each decode attempt in `eval { decode_json(...) }`, which swallows a
# $SIG{ALRM} die, and alarm is one-shot -- so an alarm-based guard against the
# regressed loop would be swallowed and hang forever. So each call runs in a
# forked child with a SIGKILL deadline (SIGKILL cannot be caught or swallowed);
# the child serializes its result back over a pipe. A regressed hang is then a
# clean, loud test failure, not a wedged run.
#
# A1 (utf8): decode_loose_json receives already-decoded Perl-Unicode content
# (hence `use utf8` above -- these literals carry the utf8 flag). JSON::MaybeXS's
# `decode_json` is the utf8 variant that expects bytes; a Perl-Unicode string
# must be UTF-8-encoded first, or it dies "Wide character in subroutine entry"
# on the first non-ASCII byte, the inner eval swallows the death, every strategy
# returns undef, and a provider's structured result (e.g. the synthetic ToolCall
# on the Perplexity forced-tool path) is silently lost. These assertions want the
# real hash back, so they fail against the un-fixed code -- encoding WHY encode_utf8.
#
# A2 (hang): the trailing-junk trim loop used `s/\}[^}]*$/\}/ or last`, a no-op
# (matches the final '}' and rewrites it to itself) whenever the candidate ends
# at '}' -- always true for the greedy `(\{.*\})` capture. The substitution still
# reports success, so `or last` never fired and the loop spun forever, wedging the
# async event loop on the forced-tool fallback path. Per its POD the method must
# return undef when all strategies fail -- never hang.

use POSIX ();
use Config;

SKIP: {
  skip 'fork required for the OS-level no-hang guard', 14 unless $Config{d_fork};

  # Run decode_loose_json in a child with a hard SIGKILL deadline. Returns
  # ( $completed_bool, $decoded_value ); $completed is false when the child had
  # to be killed (i.e. decode_loose_json failed to terminate).
  my $bounded_decode = sub {
    my ( $text, $secs ) = @_;
    pipe( my $rd, my $wr ) or die "pipe: $!";
    my $pid = fork;
    defined $pid or die "fork: $!";
    if ( !$pid ) {
      # Child: no TAP output, just hand the result back as JSON and _exit so no
      # END/DESTROY machinery runs in the fork.
      close $rd;
      my $r = $t->decode_loose_json($text);
      syswrite $wr,
        JSON::MaybeXS->new( utf8 => 1, canonical => 1 )->encode( { v => $r } );
      close $wr;
      POSIX::_exit(0);
    }
    close $wr;
    my $deadline = time + $secs;
    my $reaped   = 0;
    while ( time <= $deadline ) {
      $reaped = waitpid( $pid, POSIX::WNOHANG() );
      last if $reaped == $pid;
      select undef, undef, undef, 0.02;
    }
    if ( $reaped != $pid ) {           # still running past the deadline -> hang
      kill 'KILL', $pid;
      waitpid $pid, 0;
      close $rd;
      return ( 0, undef );
    }
    my $out = do { local $/; <$rd> };
    close $rd;
    my $decoded = eval { JSON::MaybeXS->new( utf8 => 1 )->decode($out) };
    return ( 1, ref $decoded eq 'HASH' ? $decoded->{v} : undef );
  };

  # (a) non-ASCII structured output survives the bytes<->Perl-Unicode boundary,
  #     through every strategy (whole-text, ```json``` fence, first {...} substring).
  my @non_ascii = (
    [ '{"city":"Düsseldorf","country":"Deutschland"}',
      { city => 'Düsseldorf', country => 'Deutschland' }, 'Umlauts, whole text' ],
    [ '{"emoji":"🚀","status":"ok"}',
      { emoji => '🚀', status => 'ok' }, 'emoji (astral plane), whole text' ],
    [ "```json\n{\"greeting\":\"你好\",\"lang\":\"zh\"}\n```",
      { greeting => '你好', lang => 'zh' }, 'CJK in ```json``` fence' ],
    [ 'Sure: {"note":"Grüße — 😀"} done.',
      { note => 'Grüße — 😀' }, 'mixed non-ASCII in {...} substring' ],
  );
  for my $case (@non_ascii) {
    my ( $text, $want, $label ) = @$case;
    my ( $completed, $got ) = $bounded_decode->( $text, 5 );
    ok( $completed, "non-ASCII decode terminates: $label" );
    is_deeply( $got, $want, "non-ASCII parsed via encode_utf8: $label" );
  }

  # (b) malformed / unbalanced input terminates with undef -- never hangs.
  for my $bad ( '{{"a":1}', 'prose {"a":1}}extra', 'blah {"x":[1,2}}' ) {
    my ( $completed, $got ) = $bounded_decode->( $bad, 5 );
    ok( $completed, "unbalanced input terminates (no infinite trim loop): $bad" )
      or diag("HANG: decode_loose_json did not return within timeout for: $bad");
    is( $got, undef, "unbalanced input -> undef: $bad" );
  }
}

# Override-friendliness: a subclass can override the method.
{
  package T2;
  use Moose;
  extends 'T';
  override decode_loose_json => sub { return { overridden => 1 } };
  __PACKAGE__->meta->make_immutable;
}
is_deeply( T2->new->decode_loose_json('whatever'), { overridden => 1 },
  'subclass override of decode_loose_json' );

done_testing;
