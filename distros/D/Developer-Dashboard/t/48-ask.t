#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(getcwd);
use Capture::Tiny qw(capture capture_stderr);

use Developer::Dashboard::FileSlurp;
use Developer::Dashboard::JSON qw(json_encode json_decode);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::Config;

BEGIN { use_ok('Developer::Dashboard::CLI::Ask') or BAIL_OUT('Ask module failed to load'); }

my $M = 'Developer::Dashboard::CLI::Ask';

# ------------------------------------------------------------------
# Hermetic runtime: temp HOME + temp state root.
# ------------------------------------------------------------------
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
delete local $ENV{ANTHROPIC_API_KEY};

# The layered config root is derived from the CURRENT WORKING DIRECTORY's
# deepest .developer-dashboard/ layer, not from $HOME. Run the whole test from a
# throwaway directory so config writes (e.g. the config-file subtest's
# save_global) land in temp space instead of polluting the repo's own
# .developer-dashboard/config, which would break this and other tests on reruns.
my $cwd_before = getcwd();
my $work_root  = tempdir( CLEANUP => 1 );
chdir $work_root or die "Unable to chdir to $work_root: $!";
END { chdir $cwd_before if defined $cwd_before; }

# A fake HTTP UA returning a canned reply and recording requests.
{
    package FakeUA;
    sub new { return bless { requests => [], reply => $_[1] }, $_[0]; }
    sub request {
        my ( $self, $req ) = @_;
        push @{ $self->{requests} }, $req;
        return $self->{reply}->($req);
    }
}

require HTTP::Response;

sub api_reply {
    my ($text) = @_;
    return sub {
        my $r = HTTP::Response->new( 200, 'OK' );
        $r->content( json_encode( { content => [ { type => 'text', text => $text } ] } ) );
        return $r;
    };
}

# DD-952: Nova's endpoint follows the OpenAI chat-completions response
# shape ({choices:[{message:{content}}]}), not Claude's own {content:[...]}
# shape - a genuinely different response body to parse.
sub nova_reply {
    my ($text) = @_;
    return sub {
        my $r = HTTP::Response->new( 200, 'OK' );
        $r->content( json_encode( { choices => [ { message => { role => 'assistant', content => $text } } ] } ) );
        return $r;
    };
}

# A recording CLI runner factory: captures argv, returns canned streams.
sub rec_runner {
    my ( $store, $stdout, $stderr, $exit ) = @_;
    return sub {
        my ($argv) = @_;
        push @{$store}, [ @{$argv} ];
        return ( $stdout, $stderr, $exit );
    };
}

# Always-present fake CLI path (perl exists everywhere); runner is injected so
# it is never actually executed.
my $FAKE_CLI = $^X;
sub detect_present { return $FAKE_CLI; }
sub detect_absent  { return undef; }

# ------------------------------------------------------------------
subtest 'claude direct API (default backend, env key)' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-env';
    local $ENV{WORKSPACE_REF}     = 'ws/api';
    my $ua = FakeUA->new( api_reply('Two.') );
    my $out;
    my $exit = $M->can('run_ask')->(
        args => ['What is one plus one?'],
        ua   => $ua,
        out  => \$out,
    );
    is( $exit, 0, 'exit 0' );
    like( $out, qr/Two\./, 'answer printed' );
    my $req = $ua->{requests}[0];
    like( $req->uri, qr{/v1/messages\z}, 'posts to /v1/messages' );
    is( $req->header('x-api-key'),         'sk-env',     'x-api-key from env' );
    is( $req->header('anthropic-version'), '2023-06-01', 'anthropic-version header' );
    my $body = json_decode( $req->content );
    is( $body->{model},           'claude-opus-4-8', 'default model' );
    is( $body->{max_tokens},      4096,              'default max_tokens' );
    is( $body->{messages}[0]{role},    'user', 'user turn' );
    like( $body->{messages}[0]{content}, qr/What is one plus one\?\z/, 'prompt content (docs context auto-prepended on the first call in this fresh workspace, DD-938)' );

    # DD-946 AC-3: a plain question that never triggers a tool_use block
    # is unchanged - exactly one request, even though the tools array is
    # now offered on every request.
    is( scalar @{ $ua->{requests} }, 1, 'AC-3: exactly one request - no tool_use round trip' );
    my @tool_names = map { $_->{name} } @{ $body->{tools} };
    is_deeply( [ sort @tool_names ], [ 'grep_repo', 'read_file' ], 'both tools are offered even on a plain question' );
};

# ------------------------------------------------------------------
# DD-946: the direct-API tool_use loop (read_file/grep_repo, scoped to
# the project root). See docs/dashboard-ask-backend-architecture.md.
# ------------------------------------------------------------------

# A FakeUA reply that returns each response in sequence, repeating the
# last one if called more times than responses supplied.
sub sequenced_replies {
    my (@responses) = @_;
    my $i = 0;
    return sub {
        my ($req) = @_;
        my $r = $responses[$i] // $responses[-1];
        $i++;
        return ref($r) eq 'CODE' ? $r->($req) : $r;
    };
}

# Builds one raw Claude Messages API response with an explicit content
# array and stop_reason - the shape a tool_use test needs, unlike
# api_reply()'s fixed text-only shape.
sub claude_response {
    my (%opt) = @_;
    my $r = HTTP::Response->new( 200, 'OK' );
    $r->content( json_encode( { content => $opt{content}, stop_reason => $opt{stop_reason} } ) );
    return $r;
}

# Make $work_root resolve as a real project root (PathRegistry::
# current_project_root walks up looking for a .git directory) so the
# tool_use tests below have a real, known root to scope against.
mkdir "$work_root/.git" if !-d "$work_root/.git";

subtest 'claude tool_use loop: read_file happy path (AC-1)' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-tools';
    local $ENV{WORKSPACE_REF}     = 'ws/tools-read';
    my $target = File::Spec->catfile( $work_root, 'greeting.txt' );
    open my $fh, '>', $target or die "Unable to write $target: $!";
    print {$fh} "hello from greeting.txt\n";
    close $fh;

    my $ua = FakeUA->new(
        sequenced_replies(
            claude_response(
                stop_reason => 'tool_use',
                content     => [ { type => 'tool_use', id => 'tu_1', name => 'read_file', input => { path => 'greeting.txt' } } ],
            ),
            claude_response(
                stop_reason => 'end_turn',
                content     => [ { type => 'text', text => 'The file says: hello from greeting.txt' } ],
            ),
        )
    );
    my $out;
    my $exit = $M->can('run_ask')->(
        args => ['What does greeting.txt say?'],
        ua   => $ua,
        out  => \$out,
    );
    is( $exit, 0, 'exit 0' );
    like( $out, qr/hello from greeting\.txt/, 'AC-1: answer reflects the real file content, via a tool_use call' );
    is( scalar @{ $ua->{requests} }, 2, 'two requests: the initial call, then one after the tool_result round trip' );

    my $second_body     = json_decode( $ua->{requests}[1]->content );
    my $tool_result_msg = $second_body->{messages}[-1];
    is( $tool_result_msg->{role}, 'user', 'the tool_result is sent back as a user-role message' );
    is( $tool_result_msg->{content}[0]{type},        'tool_result', 'content block is a tool_result' );
    is( $tool_result_msg->{content}[0]{tool_use_id}, 'tu_1',        'tool_use_id is echoed back' );
    like( $tool_result_msg->{content}[0]{content}, qr/hello from greeting\.txt/, 'tool_result content carries the real file body' );
    is( $second_body->{messages}[-2]{role}, 'assistant', 'the tool_use turn itself is replayed back as an assistant message' );
};

subtest 'claude tool_use loop: read_file outside the project root is refused, not read (AC-2)' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-tools';
    local $ENV{WORKSPACE_REF}     = 'ws/tools-escape';
    my $secret = File::Spec->catfile( $home, 'outside-secret.txt' );
    open my $fh, '>', $secret or die "Unable to write $secret: $!";
    print {$fh} "do not leak this\n";
    close $fh;

    my $ua = FakeUA->new(
        sequenced_replies(
            claude_response(
                stop_reason => 'tool_use',
                content     => [ { type => 'tool_use', id => 'tu_2', name => 'read_file', input => { path => $secret } } ],
            ),
            claude_response(
                stop_reason => 'end_turn',
                content     => [ { type => 'text', text => 'I could not read that file.' } ],
            ),
        )
    );
    my $out;
    $M->can('run_ask')->( args => ['read the secret'], ua => $ua, out => \$out );
    my $second_body = json_decode( $ua->{requests}[1]->content );
    my $tool_result = $second_body->{messages}[-1]{content}[0]{content};
    like( $tool_result, qr/Refused/, 'AC-2: refused, reported back as tool_result content' );
    unlike( $tool_result, qr/do not leak this/, 'the outside file was never actually read into the result' );
};

subtest 'claude tool_use loop: exceeding the round cap dies loudly rather than looping forever' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-tools';
    local $ENV{WORKSPACE_REF}     = 'ws/tools-loop';
    my $ua = FakeUA->new(
        sub {
            return claude_response(
                stop_reason => 'tool_use',
                content     => [ { type => 'tool_use', id => 'tu_x', name => 'grep_repo', input => { pattern => 'x' } } ],
            );
        }
    );
    my $out;
    eval { $M->can('run_ask')->( args => ['loop forever'], ua => $ua, out => \$out ); };
    like( $@, qr/tool_use loop exceeded 10 rounds/, 'dies naming the round cap' );
    is( scalar @{ $ua->{requests} }, 10, 'stopped after exactly the cap, no extra request' );
};

subtest 'claude tool_use loop: an unrecognized tool name reports back rather than dying' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-tools';
    local $ENV{WORKSPACE_REF}     = 'ws/tools-unknown';
    my $ua = FakeUA->new(
        sequenced_replies(
            claude_response(
                stop_reason => 'tool_use',
                content     => [ { type => 'tool_use', id => 'tu_3', name => 'delete_everything', input => {} } ],
            ),
            claude_response(
                stop_reason => 'end_turn',
                content     => [ { type => 'text', text => 'ok' } ],
            ),
        )
    );
    my $out;
    $M->can('run_ask')->( args => ['try something odd'], ua => $ua, out => \$out );
    my $second_body = json_decode( $ua->{requests}[1]->content );
    is( $second_body->{messages}[-1]{content}[0]{content}, 'Unknown tool: delete_everything', 'unknown tool name reported as ordinary content, not a fatal error' );
};

subtest 'claude tool_use loop: a malformed response dies clearly' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-tools';
    local $ENV{WORKSPACE_REF}     = 'ws/tools-malformed';
    my $ua = FakeUA->new(
        sub {
            my $r = HTTP::Response->new( 200, 'OK' );
            $r->content( json_encode( { stop_reason => 'end_turn' } ) );    # no "content" key at all
            return $r;
        }
    );
    my $out;
    eval { $M->can('run_ask')->( args => ['anything'], ua => $ua, out => \$out ); };
    like( $@, qr/Claude API returned no content/, 'malformed response dies with the expected message' );
};

subtest '_claude_tools: shape' => sub {
    my $tools = $M->can('_claude_tools')->();
    is( scalar @{$tools}, 2, 'exactly two tools' );
    my %by_name = map { $_->{name} => $_ } @{$tools};
    ok( $by_name{read_file}, 'read_file present' );
    ok( $by_name{grep_repo}, 'grep_repo present' );
    is( $by_name{read_file}{input_schema}{required}[0], 'path',    'read_file requires path' );
    is( $by_name{grep_repo}{input_schema}{required}[0], 'pattern', 'grep_repo requires pattern' );
};

subtest '_execute_claude_tool: dispatches to the right tool by name' => sub {
    my $root = tempdir( CLEANUP => 1 );
    open my $fh, '>', "$root/x.txt" or die $!;
    print {$fh} "needle here\n";
    close $fh;
    like( $M->can('_execute_claude_tool')->( 'read_file', { path => 'x.txt' },     $root ), qr/needle here/, 'read_file dispatch' );
    like( $M->can('_execute_claude_tool')->( 'grep_repo', { pattern => 'needle' }, $root ), qr/needle here/, 'grep_repo dispatch' );
    is( $M->can('_execute_claude_tool')->( 'bogus', {}, $root ), 'Unknown tool: bogus', 'unknown-tool dispatch' );
};

subtest '_execute_read_file: not found and outside-root refusal' => sub {
    my $root = tempdir( CLEANUP => 1 );
    is( $M->can('_execute_read_file')->( 'missing.txt', $root ), 'File not found: missing.txt', 'missing file message' );
    like( $M->can('_execute_read_file')->( '/etc/passwd', $root ), qr/Refused/, 'absolute path outside root refused' );
};

subtest '_execute_grep_repo: real search, no matches, bad pattern, subdirectory scoping' => sub {
    my $root = tempdir( CLEANUP => 1 );
    mkdir "$root/sub";
    open my $fh1, '>', "$root/a.txt" or die $!;
    print {$fh1} "alpha line one\nbeta line two\n";
    close $fh1;
    open my $fh2, '>', "$root/sub/b.txt" or die $!;
    print {$fh2} "gamma in sub\n";
    close $fh2;

    like( $M->can('_execute_grep_repo')->( 'alpha', undef, $root ), qr{a\.txt:1:alpha line one}, 'matches formatted as path:line:text' );
    is( $M->can('_execute_grep_repo')->( 'nope-does-not-exist-xyz', undef, $root ), 'No matches.', 'no matches message' );
    like( $M->can('_execute_grep_repo')->( '(unclosed', undef, $root ), qr/Invalid regular expression/, 'a bad regex is reported, not a fatal die' );
    is( $M->can('_execute_grep_repo')->( '', undef, $root ), 'grep_repo requires a pattern.', 'an empty pattern is refused' );
    like( $M->can('_execute_grep_repo')->( 'gamma', 'sub', $root ), qr{sub/b\.txt:1:gamma in sub}, 'a subdirectory argument narrows the search' );
    is( $M->can('_execute_grep_repo')->( 'alpha', 'sub', $root ), 'No matches.', 'subdirectory restriction excludes files outside it' );
    like( $M->can('_execute_grep_repo')->( 'alpha', '../../etc', $root ), qr/Refused/, 'a subdirectory argument escaping the root is refused' );
};

subtest '_scoped_tool_path: normalization and refusal edge cases' => sub {
    my $root = '/tmp/dd-fake-root';
    my ( $abs1, $err1 ) = $M->can('_scoped_tool_path')->( $root, 'a/./b/../c' );
    is( $err1, undef,        'a mixed ./.. path that stays inside the root resolves cleanly' );
    is( $abs1, "$root/a/c",  'normalized to the collapsed absolute path' );

    my ( $abs2, $err2 ) = $M->can('_scoped_tool_path')->( $root, undef );
    is( $err2, undef, 'an undef relative path means "the root itself"' );
    is( $abs2, $root, 'resolves to the root' );

    my ( undef, $err3 ) = $M->can('_scoped_tool_path')->( $root, '../escape' );
    like( $err3, qr/Refused/, 'a leading .. that climbs above the root is refused' );

    my ( undef, $err4 ) = $M->can('_scoped_tool_path')->( $root, '/etc/passwd' );
    like( $err4, qr/Refused/, 'an absolute path elsewhere entirely is refused' );

    # Regression guard for the naive-prefix trap: a sibling directory whose
    # name merely starts with the root's own name as a string must NOT be
    # treated as "inside" the root.
    my ( undef, $err5 ) = $M->can('_scoped_tool_path')->( $root, '../dd-fake-root2/x' );
    like( $err5, qr/Refused/, 'a sibling dir sharing the root as a string prefix is still refused' );
};

subtest '_normalize_path_segments: a literal "." segment (File::Spec collapses it before this sub ever sees one via the real caller, so exercise it directly)' => sub {
    is( $M->can('_normalize_path_segments')->('/a/./b/../c'), '/a/c', 'a literal "." segment is dropped, not just "" or ".."' );
};

subtest 'claude tool_use loop: malformed responses, both disjuncts of the content guard' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-tools';
    local $ENV{WORKSPACE_REF}     = 'ws/tools-malformed-array-payload';
    my $ua = FakeUA->new(
        sub {
            my $r = HTTP::Response->new( 200, 'OK' );
            $r->content( json_encode( [ 1, 2, 3 ] ) );    # the payload itself is not a HASH at all
            return $r;
        }
    );
    my $out;
    eval { $M->can('run_ask')->( args => ['anything'], ua => $ua, out => \$out ); };
    like( $@, qr/Claude API returned no content/, 'a non-HASH payload dies with the same message, exercising the left disjunct' );
};

subtest 'claude tool_use loop: a non-tool_use block mixed with a tool_use block, and a non-HASH block' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-tools';
    local $ENV{WORKSPACE_REF}     = 'ws/tools-mixed-blocks';
    my $target = File::Spec->catfile( $work_root, 'mixed.txt' );
    open my $fh, '>', $target or die $!;
    print {$fh} "mixed block content\n";
    close $fh;

    my $ua = FakeUA->new(
        sequenced_replies(
            claude_response(
                stop_reason => 'tool_use',
                content     => [
                    'a bare string, not a hashref at all',
                    { type => 'text', text => 'thinking out loud' },
                    {},    # a hashref block with no "type" key at all - exercises the ($block->{type} || '') undef fallback
                    { type => 'tool_use', id => 'tu_mixed', name => 'read_file', input => { path => 'mixed.txt' } },
                ],
            ),
            claude_response(
                stop_reason => 'end_turn',
                content     => [ { type => 'text', text => 'mixed block content' } ],
            ),
        )
    );
    my $out;
    $M->can('run_ask')->( args => ['what does mixed.txt say?'], ua => $ua, out => \$out );
    like( $out, qr/mixed block content/, 'the tool_use block among non-tool_use siblings is still executed correctly' );
    my $second_body = json_decode( $ua->{requests}[1]->content );
    is( scalar @{ $second_body->{messages}[-1]{content} }, 1, 'only the one real tool_use block produced a tool_result - the bare string and text block were skipped, not turned into phantom results' );
};

subtest '_execute_grep_repo: undef pattern (distinct from empty-string) is refused' => sub {
    my $root = tempdir( CLEANUP => 1 );
    is( $M->can('_execute_grep_repo')->( undef, undef, $root ), 'grep_repo requires a pattern.', 'undef pattern refused the same way as empty string' );
};

subtest '_execute_grep_repo: excludes files under the .git/.worktrees/etc segments' => sub {
    my $root = tempdir( CLEANUP => 1 );
    mkdir File::Spec->catdir( $root, '.git' );
    open my $fh1, '>', File::Spec->catfile( $root, '.git', 'config' ) or die $!;
    print {$fh1} "findme inside dotgit\n";
    close $fh1;
    open my $fh2, '>', File::Spec->catfile( $root, 'real.txt' ) or die $!;
    print {$fh2} "findme in a real file\n";
    close $fh2;

    my $hits = $M->can('_execute_grep_repo')->( 'findme', undef, $root );
    like( $hits, qr{real\.txt}, 'the real file is matched' );
    unlike( $hits, qr{\.git}, 'the .git-nested file is excluded, not matched' );
};

subtest '_execute_grep_repo: the match cap stops mid-file AND stops a later file from opening at all' => sub {
    my $root = tempdir( CLEANUP => 1 );
    my $limit = 200;
    for my $name (qw(aaa.txt bbb.txt)) {
        open my $fh, '>', File::Spec->catfile( $root, $name ) or die $!;
        print {$fh} "capme line $_\n" for 1 .. ( $limit + 60 );
        close $fh;
    }
    my $hits  = $M->can('_execute_grep_repo')->( 'capme', undef, $root );
    my @lines = split /\n/, $hits;
    is( scalar @lines, $limit, "capped at exactly $limit matches across both files, not (limit+60)*2" );
};

# DD-952: --nova follows the direct-API shape (like --claude), against
# Nova's own standalone REST endpoint, not AWS Bedrock/SigV4.
subtest 'nova direct API' => sub {
    local $ENV{NOVA_API_KEY}  = 'nova-key-env';
    local $ENV{WORKSPACE_REF} = 'ws/nova';
    my $ua = FakeUA->new( nova_reply('Nova says hi.') );
    my $out;
    my $exit = $M->can('run_ask')->(
        args => [ '--nova', 'Hello! How are you?' ],
        ua   => $ua,
        out  => \$out,
    );
    is( $exit, 0, 'exit 0' );
    like( $out, qr/Nova says hi\./, 'answer printed' );
    my $req = $ua->{requests}[0];
    like( $req->uri, qr{\Ahttps://api\.nova\.amazon\.com/v1/chat/completions\z}, 'posts to the real Nova endpoint' );
    is( $req->header('authorization'), 'Bearer nova-key-env', 'bearer token from NOVA_API_KEY' );
    my $body = json_decode( $req->content );
    is( $body->{model}, 'nova-2-lite-v1', 'default nova model' );
    is( $body->{messages}[0]{role}, 'user', 'user turn' );
    like( $body->{messages}[0]{content}, qr/Hello! How are you\?\z/, 'prompt content' );
};

subtest 'nova with an explicit --model override' => sub {
    local $ENV{NOVA_API_KEY}  = 'nova-key-env';
    local $ENV{WORKSPACE_REF} = 'ws/nova-model';
    my $ua = FakeUA->new( nova_reply('ok') );
    $M->can('run_ask')->(
        args => [ '--nova', '--model', 'nova-2-pro-v1', 'anything' ],
        ua   => $ua,
        out  => \(my $out),
    );
    my $body = json_decode( $ua->{requests}[0]->content );
    is( $body->{model}, 'nova-2-pro-v1', 'an explicit --model overrides the default nova model' );
};

subtest 'nova with no NOVA_API_KEY set' => sub {
    delete local $ENV{NOVA_API_KEY};
    local $ENV{WORKSPACE_REF} = 'ws/nova-nokey';
    my $out;
    my $exit = eval {
        $M->can('run_ask')->(
            args => [ '--nova', 'anything' ],
            ua   => FakeUA->new( nova_reply('unused') ),
            out  => \$out,
        );
    };
    ok( !defined $exit || $exit != 0, 'a missing NOVA_API_KEY does not silently succeed' );
};

subtest 'nova rejects image attachments' => sub {
    local $ENV{NOVA_API_KEY}  = 'nova-key-env';
    local $ENV{WORKSPACE_REF} = 'ws/nova-images';
    my $tmp_image = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'pic.png' );
    open my $img_fh, '>', $tmp_image or die $!;
    print {$img_fh} 'not a real png, content unused';
    close $img_fh;
    my $out;
    my $exit = eval {
        $M->can('run_ask')->(
            args => [ '--nova', '--file', $tmp_image, 'describe this' ],
            ua   => FakeUA->new( nova_reply('unused') ),
            out  => \$out,
        );
    };
    ok( !defined $exit || $exit != 0, 'attaching a file with --nova does not silently succeed (images unsupported)' );
};

subtest 'nova API request failure surfaces the status line' => sub {
    local $ENV{NOVA_API_KEY}  = 'nova-key-env';
    local $ENV{WORKSPACE_REF} = 'ws/nova-failure';
    my $ua = FakeUA->new( sub { return HTTP::Response->new( 500, 'Internal Server Error' ); } );
    my $out;
    eval {
        $M->can('run_ask')->(
            args => [ '--nova', 'anything' ],
            ua   => $ua,
            out  => \$out,
        );
    };
    like( $@, qr/Nova API request failed.*Internal Server Error/, '_call_nova_api dies naming the HTTP status line on failure' );
};

subtest 'nova API malformed/empty response bodies' => sub {
    is( eval { $M->can('_extract_nova_api_text')->( { choices => [] } ) }, undef, 'empty choices array' );
    like( $@, qr/Nova API returned no content/, 'empty choices dies with the right message' );

    is( eval { $M->can('_extract_nova_api_text')->( { choices => [ { message => { content => '' } } ] } ) }, undef, 'empty content string' );
    like( $@, qr/Nova API returned no text/, 'empty content dies with the right message' );

    # DD-952: condition coverage needs each disjunct of the guard exercised
    # on its own, not just the overall true/false outcome - a non-HASH
    # payload (never reaches the choices key at all) versus a HASH with no
    # "choices" array versus one with an empty array are three genuinely
    # different ways the guard's "or" can go true.
    is( eval { $M->can('_extract_nova_api_text')->( 'not a hashref at all' ) }, undef, 'a non-HASH payload' );
    like( $@, qr/Nova API returned no content/, 'non-HASH payload dies with the right message' );
    is( eval { $M->can('_extract_nova_api_text')->( { choices => 'not an array' } ) }, undef, 'choices present but not an ARRAY' );
    like( $@, qr/Nova API returned no content/, 'non-ARRAY choices dies with the right message' );

    # ...and the two ways "no content" can be true: the key is missing
    # entirely (undef) versus present as an empty string.
    is( eval { $M->can('_extract_nova_api_text')->( { choices => [ { message => {} } ] } ) }, undef, 'content key entirely absent (undef)' );
    like( $@, qr/Nova API returned no text/, 'undef content dies with the right message' );
};

subtest 'nova API key resolution: undef vs empty-string, both refuse' => sub {
    # DD-952: _ask_nova's guard is "not defined $key or $key eq ''" - undef
    # (the key was never set) and '' (set to an explicit empty string) are
    # two different ways to reach the same refusal, and condition coverage
    # needs both exercised, not just one.
    eval {
        $M->can('_ask_nova')->(
            env => { NOVA_API_KEY => '' }, images => [], history => [], text_files => [],
            prompt => 'x', ua => FakeUA->new( nova_reply('unused') ),
        );
    };
    like( $@, qr/No NOVA_API_KEY set/, 'an explicit empty-string NOVA_API_KEY is refused the same as an unset one' );
};

subtest 'nova default ua and default model, when neither is passed explicitly' => sub {
    # DD-952: condition coverage on `$a{ua} || _default_ua()` and
    # `$a{model} || $NOVA_DEFAULT_MODEL` in _ask_nova needs the "left is
    # false/absent" side exercised too - calling _ask_nova with no ua/model
    # keys forces both defaults to actually run. _default_ua() builds a
    # REAL LWP::UserAgent, so its ->request is monkeypatched here (this
    # project's established hermetic-test pattern) purely to avoid a real
    # network call while still proving the fallback construction path runs.
    require LWP::UserAgent;    # must be loaded BEFORE localizing its glob, or
                                # _default_ua's own lazy `require LWP::UserAgent`
                                # re-defines request() during this dynamic scope
                                # and silently overwrites the patch below.
    my @seen_requests;
    my $original_request = \&LWP::UserAgent::request;
    local *LWP::UserAgent::request = sub {
        my ( $self, $req ) = @_;
        push @seen_requests, $req;
        my $r = HTTP::Response->new( 200, 'OK' );
        $r->content( json_encode( { choices => [ { message => { content => 'default-ua-path' } } ] } ) );
        return $r;
    };
    ok( ref($original_request) eq 'CODE', 'default LWP request method is loaded before the scoped test replacement' );
    my $answer = $M->can('_ask_nova')->(
        env => { NOVA_API_KEY => 'k' }, images => [], history => [], text_files => [], prompt => 'x',
    );
    is( $answer, 'default-ua-path', '_ask_nova with no explicit ua/model still reaches the real API call path' );
    is( scalar @seen_requests, 1, 'exactly one request was made through the default-constructed LWP::UserAgent' );
    my $body = json_decode( $seen_requests[0]->content );
    is( $body->{model}, 'nova-2-lite-v1', 'the default model fallback is what was actually sent' );
};

subtest 'per-workspace memory: follow-up carries history + sticky backend' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-env';
    local $ENV{WORKSPACE_REF}     = 'ws/mem';
    my $out;
    $M->can('run_ask')->( args => ['First question'], ua => FakeUA->new( api_reply('First answer') ), out => \$out );

    my $ua2 = FakeUA->new( api_reply('Second answer') );
    $M->can('run_ask')->( args => ['Second question'], ua => $ua2, out => \$out );
    my $body = json_decode( $ua2->{requests}[0]->content );
    is( scalar @{ $body->{messages} }, 3, 'prior user+assistant turns replayed + new turn' );
    like( $body->{messages}[0]{content}, qr/First question\z/, 'history user turn (docs context auto-prepended on the first call in that fresh workspace, DD-938)' );
    is( $body->{messages}[1]{role},    'assistant',      'history assistant turn' );
    is( $body->{messages}[2]{content}, 'Second question', 'new turn last' );
};

subtest '--new resets the conversation' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-env';
    local $ENV{WORKSPACE_REF}     = 'ws/reset';
    my $out;
    $M->can('run_ask')->( args => ['q1'], ua => FakeUA->new( api_reply('a1') ), out => \$out );
    my $ua2 = FakeUA->new( api_reply('a2') );
    $M->can('run_ask')->( args => [ '--new', 'q2' ], ua => $ua2, out => \$out );
    my $body = json_decode( $ua2->{requests}[0]->content );
    is( scalar @{ $body->{messages} }, 1, 'history cleared by --new' );
};

subtest '--no-memory sends no history and persists nothing' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-env';
    local $ENV{WORKSPACE_REF}     = 'ws/nomem';
    my $out;
    $M->can('run_ask')->( args => ['seed'], ua => FakeUA->new( api_reply('seeded') ), out => \$out );
    my $ua2 = FakeUA->new( api_reply('isolated') );
    $M->can('run_ask')->( args => [ '--no-memory', 'lone' ], ua => $ua2, out => \$out );
    my $body = json_decode( $ua2->{requests}[0]->content );
    is( scalar @{ $body->{messages} }, 1, 'no history for --no-memory' );

    # And the seeded conversation is untouched: a later normal ask replays 1 pair.
    my $ua3 = FakeUA->new( api_reply('again') );
    $M->can('run_ask')->( args => ['more'], ua => $ua3, out => \$out );
    my $b3 = json_decode( $ua3->{requests}[0]->content );
    is( scalar @{ $b3->{messages} }, 3, 'no-memory turn was not saved' );
};

subtest 'DD-938: --no-memory on a genuinely fresh workspace does not auto-inject docs' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-env';
    local $ENV{WORKSPACE_REF}     = 'ws/nomem-fresh';
    my $out;
    my $ua = FakeUA->new( api_reply('answer') );
    $M->can('run_ask')->( args => [ '--no-memory', 'first ever call' ], ua => $ua, out => \$out );
    my $body = json_decode( $ua->{requests}[0]->content );
    is( scalar @{ $body->{messages} }, 1, 'single turn, no replayed history' );
    is( $body->{messages}[0]{content}, 'first ever call', 'the docs context is not prepended when --no-memory is set, even on a workspace that has never been asked before' );
};

subtest 'config-file api_key + base_url + model + max_tokens' => sub {
    local $ENV{WORKSPACE_REF} = 'ws/conf';
    delete local $ENV{ANTHROPIC_API_KEY};
    my $confhome = tempdir( CLEANUP => 1 );
    my $paths = Developer::Dashboard::PathRegistry->new( home => $confhome );
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    $config->save_global(
        { claude => { api_key => 'sk-conf', base_url => 'https://example.test', default_model => 'claude-sonnet-5', max_tokens => 99 } } );

    my $ua = FakeUA->new( api_reply('ok') );
    my $out;
    $M->can('run_ask')->( args => ['hi'], config => $config, paths => $paths, ua => $ua, out => \$out );
    my $req = $ua->{requests}[0];
    like( $req->uri, qr{^https://example\.test/v1/messages}, 'config base_url used' );
    is( $req->header('x-api-key'), 'sk-conf', 'config api_key used' );
    my $body = json_decode( $req->content );
    is( $body->{model},      'claude-sonnet-5', 'config default_model' );
    is( $body->{max_tokens}, 99,                'config max_tokens' );
};

subtest 'text + image attachments in the API request' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-env';
    local $ENV{WORKSPACE_REF}     = 'ws/attach';
    my $dir = tempdir( CLEANUP => 1 );
    my $txt = File::Spec->catfile( $dir, 'notes.txt' );
    open my $tf, '>', $txt or die $!; print {$tf} "inline body"; close $tf;
    my $png = File::Spec->catfile( $dir, 'shot.png' );
    open my $pf, '>:raw', $png or die $!; print {$pf} "\x89PNGDATA"; close $pf;

    my $ua = FakeUA->new( api_reply('seen') );
    my $out;
    $M->can('run_ask')->( args => [ '--file', $txt, '--file', $png, 'describe' ], ua => $ua, out => \$out );
    my $body = json_decode( $ua->{requests}[0]->content );
    my $last = $body->{messages}[-1]{content};
    is( ref($last), 'ARRAY', 'image turn uses content blocks' );
    like( $last->[0]{text}, qr/describe/,      'prompt block present' );
    like( $last->[0]{text}, qr/inline body/,   'text file inlined into prompt' );
    is( $last->[1]{type},               'image',     'image block' );
    is( $last->[1]{source}{media_type}, 'image/png', 'png media type' );
    ok( length $last->[1]{source}{data}, 'base64 image data present' );
};

subtest 'claude CLI fallback when no key' => sub {
    local $ENV{WORKSPACE_REF} = 'ws/cli';
    delete local $ENV{ANTHROPIC_API_KEY};
    my @calls;
    my $out;
    $M->can('run_ask')->(
        args   => [ '--model', 'claude-opus-4-8', 'via cli' ],
        detect => \&detect_present,
        runner => rec_runner( \@calls, "CLI ANSWER\n", '', 0 ),
        out    => \$out,
    );
    like( $out, qr/CLI ANSWER/, 'claude CLI answer printed' );
    my @argv = @{ $calls[0] };
    ok( ( grep { $_ eq '-p' } @argv ),            'claude -p used' );
    ok( ( grep { $_ eq '--output-format' } @argv ), 'output-format text' );
    ok( ( grep { $_ eq 'claude-opus-4-8' } @argv ), 'model forwarded' );
};

subtest 'no key and no claude CLI is a clean error' => sub {
    local $ENV{WORKSPACE_REF} = 'ws/nokey';
    delete local $ENV{ANTHROPIC_API_KEY};
    eval {
        $M->can('run_ask')->( args => ['x'], detect => \&detect_absent, out => \my $o );
        1;
    };
    like( $@, qr/No ANTHROPIC_API_KEY set and no `claude` CLI/, 'clear no-backend error' );
};

subtest 'images without a key are refused for the CLI fallback' => sub {
    local $ENV{WORKSPACE_REF} = 'ws/imgnokey';
    delete local $ENV{ANTHROPIC_API_KEY};
    my $dir = tempdir( CLEANUP => 1 );
    my $png = File::Spec->catfile( $dir, 'p.png' );
    open my $pf, '>:raw', $png or die $!; print {$pf} 'x'; close $pf;
    eval {
        $M->can('run_ask')->( args => [ '--file', $png, 'q' ], detect => \&detect_present, out => \my $o );
        1;
    };
    like( $@, qr/Image attachments need an ANTHROPIC_API_KEY/, 'image+CLI refused' );
};

subtest 'codex backend (sticky) forces read-only and attaches images' => sub {
    local $ENV{WORKSPACE_REF} = 'ws/codex';
    my $dir = tempdir( CLEANUP => 1 );
    my $png = File::Spec->catfile( $dir, 'c.png' );
    open my $pf, '>:raw', $png or die $!; print {$pf} 'x'; close $pf;
    my @calls;
    my $out;
    $M->can('run_ask')->(
        args   => [ '--codex', '--model', 'gpt-5.5', '--file', $png, 'hello codex' ],
        detect => \&detect_present,
        runner => rec_runner( \@calls, "codex says hi\n", 'noise', 0 ),
        out    => \$out,
    );
    like( $out, qr/codex says hi/, 'codex answer printed' );
    my $argv = join ' ', @{ $calls[0] };
    like( $argv, qr/\bexec\b/,            'codex exec' );
    like( $argv, qr/-s read-only/,        'read-only sandbox forced' );
    like( $argv, qr/--skip-git-repo-check/, 'skip git repo check' );
    like( $argv, qr/-i \S+c\.png/,        'image via -i' );
    like( $argv, qr/-- .*hello codex/s,   'prompt after -- (docs context auto-prepended on the first call in this fresh workspace, DD-938)' );
    like( $argv, qr/--model gpt-5\.5/,    'model forwarded' );

    # Now sticky: a plain ask stays on codex.
    my @calls2;
    $M->can('run_ask')->(
        args   => ['still codex'],
        detect => \&detect_present,
        runner => rec_runner( \@calls2, "again\n", '', 0 ),
        out    => \$out,
    );
    like( join( ' ', @{ $calls2[0] } ), qr/\bexec\b/, 'codex remained sticky for workspace' );
};

subtest 'copilot backend attaches with --attachment' => sub {
    local $ENV{WORKSPACE_REF} = 'ws/copilot';
    my $dir = tempdir( CLEANUP => 1 );
    my $png = File::Spec->catfile( $dir, 'k.png' );
    open my $pf, '>:raw', $png or die $!; print {$pf} 'x'; close $pf;
    my @calls;
    my $out;
    $M->can('run_ask')->(
        args   => [ '--copilot', '--model', 'gpt-5', '--file', $png, 'hi copilot' ],
        detect => \&detect_present,
        runner => rec_runner( \@calls, "copilot reply\n", '', 0 ),
        out    => \$out,
    );
    like( $out, qr/copilot reply/, 'copilot answer printed' );
    my $argv = join ' ', @{ $calls[0] };
    like( $argv, qr/-p .*hi copilot/s,   'prompt via -p (docs context auto-prepended on the first call in this fresh workspace, DD-938)' );
    like( $argv, qr/--allow-all-tools/,  'non-interactive tools flag' );
    like( $argv, qr/--attachment \S+k\.png/, 'image via --attachment' );
    like( $argv, qr/--model gpt-5/,      'model forwarded' );
};

subtest 'gemini backend is reported missing (not installed)' => sub {
    local $ENV{WORKSPACE_REF} = 'ws/gemini';
    eval {
        $M->can('run_ask')->( args => [ '--gemini', 'hi' ], detect => \&detect_absent, out => \my $o );
        1;
    };
    like( $@, qr/`gemini` CLI not found.*gemini-cli/s, 'gemini missing error names the package' );
};

subtest 'gemini backend argv when present' => sub {
    local $ENV{WORKSPACE_REF} = 'ws/gempresent';
    my @calls;
    my $out;
    $M->can('run_ask')->(
        args   => [ '--gemini', '--model', 'gemini-2.5-pro', 'hi gem' ],
        detect => \&detect_present,
        runner => rec_runner( \@calls, "gem out\n", '', 0 ),
        out    => \$out,
    );
    my $argv = join ' ', @{ $calls[0] };
    like( $argv, qr/-p .*hi gem/s, 'prompt via -p (docs context auto-prepended on the first call in this fresh workspace, DD-938)' );
    like( $argv, qr/-m gemini-2\.5-pro/, 'model via -m' );
    like( $argv, qr/-o text/,     'text output' );
};

subtest 'gemini refuses image attachments' => sub {
    local $ENV{WORKSPACE_REF} = 'ws/gemimg';
    my $dir = tempdir( CLEANUP => 1 );
    my $png = File::Spec->catfile( $dir, 'g.png' );
    open my $pf, '>:raw', $png or die $!; print {$pf} 'x'; close $pf;
    eval {
        $M->can('run_ask')->(
            args   => [ '--gemini', '--file', $png, 'q' ],
            detect => \&detect_present,
            runner => rec_runner( \my @c, '', '', 0 ),
            out    => \my $o,
        );
        1;
    };
    like( $@, qr/gemini cannot attach files/, 'gemini image refusal' );
};

subtest 'codex/copilot missing CLIs error with install hints' => sub {
    local $ENV{WORKSPACE_REF} = 'ws/miss';
    for my $b (qw(codex copilot)) {
        eval {
            $M->can('run_ask')->( args => [ "--$b", 'q' ], detect => \&detect_absent, out => \my $o );
            1;
        };
        like( $@, qr/`$b` CLI not found/, "$b missing error" );
    }
};

subtest 'CLI backend failure surfaces stderr; silent output errors' => sub {
    local $ENV{WORKSPACE_REF} = 'ws/fail';
    eval {
        $M->can('run_ask')->(
            args   => [ '--codex', 'q' ],
            detect => \&detect_present,
            runner => rec_runner( \my @c, '', "model_not_supported\n", 1 ),
            out    => \my $o,
        );
        1;
    };
    like( $@, qr/codex backend failed: model_not_supported/, 'stderr surfaced' );

    eval {
        $M->can('run_ask')->(
            args   => [ '--codex', 'q' ],
            detect => \&detect_present,
            runner => rec_runner( \my @c2, '', '', 7 ),
            out    => \my $o2,
        );
        1;
    };
    like( $@, qr/codex backend failed: exit status 7/, 'empty stderr falls back to exit status' );

    eval {
        $M->can('run_ask')->(
            args   => [ '--copilot', 'q' ],
            detect => \&detect_present,
            runner => rec_runner( \my @c3, "   \n", '', 0 ),
            out    => \my $o3,
        );
        1;
    };
    like( $@, qr/copilot backend returned no answer/, 'blank stdout is an error' );
};

subtest 'CLI backend replays text history and skips image turns' => sub {
    local $ENV{WORKSPACE_REF} = 'ws/hist';
    # Seed transcript directly with a mixed history including an image turn.
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    my $key   = $M->can('_workspace_key')->( $paths, { WORKSPACE_REF => 'ws/hist' } );
    my $file  = $M->can('_transcript_file')->( $paths, $key );
    open my $sf, '>:raw', $file or die $!;
    print {$sf} json_encode(
        {
            backend  => 'codex',
            messages => [
                { role => 'user',      content => [ { type => 'text', text => 'image turn' } ] },
                { role => 'assistant', content => 'saw the image' },
            ],
        }
    );
    close $sf;

    my @calls;
    $M->can('run_ask')->(
        args   => ['next'],
        detect => \&detect_present,
        runner => rec_runner( \@calls, "ok\n", '', 0 ),
        out    => \my $o,
    );
    my $prompt = ( @{ $calls[0] } )[-1];
    like( $prompt, qr/Previous conversation:/, 'history preamble rendered' );
    like( $prompt, qr/Assistant: saw the image/, 'assistant turn rendered' );
    unlike( $prompt, qr/ARRAY\(/, 'image (ref) turn skipped, not stringified' );
};

subtest 'stdin is appended to the prompt' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-env';
    local $ENV{WORKSPACE_REF}     = 'ws/stdin';
    my $ua = FakeUA->new( api_reply('ok') );
    $M->can('run_ask')->( args => ['explain'], stdin => "piped context\n", ua => $ua, out => \my $o );
    my $body = json_decode( $ua->{requests}[0]->content );
    like( $body->{messages}[0]{content}, qr/explain\n\npiped context/, 'stdin appended' );

    # stdin alone (no args) becomes the whole prompt (fresh workspace).
    local $ENV{WORKSPACE_REF} = 'ws/stdin-only';
    my $ua2 = FakeUA->new( api_reply('ok') );
    $M->can('run_ask')->( args => [], stdin => "only stdin", ua => $ua2, out => \my $o2 );
    my $b2 = json_decode( $ua2->{requests}[0]->content );
    like( $b2->{messages}[0]{content}, qr/only stdin\z/, 'stdin-only prompt (docs context auto-prepended on the first call in that fresh workspace, DD-938)' );
};

# ------------------------------------------------------------------
# Error and edge cases
# ------------------------------------------------------------------
subtest 'argument validation errors' => sub {
    eval { $M->can('run_ask')->(); 1 };
    like( $@, qr/Missing ask arguments/, 'missing args' );
    eval { $M->can('run_ask')->( args => 'nope' ); 1 };
    like( $@, qr/must be an array reference/, 'args not arrayref' );
    eval { $M->can('run_ask')->( args => [], out => \my $o ); 1 };
    like( $@, qr/No question provided/, 'empty prompt' );
    eval { $M->can('run_ask')->( args => [ '--claude', '--codex', 'q' ], out => \my $o2 ); 1 };
    like( $@, qr/Choose only one backend flag/, 'two backend flags rejected' );
    my $getopt_err;
    capture {
        eval { $M->can('run_ask')->( args => ['--model'], out => \my $o3 ); 1 };
        $getopt_err = $@;
    };
    like( $getopt_err, qr/Unable to parse ask options/, 'getopt failure' );
    eval { $M->can('run_ask')->( args => [ '--file', "$home/does-not-exist", 'q' ], out => \my $o4 ); 1 };
    like( $@, qr/Attachment not found/, 'missing attachment' );
};

# ------------------------------------------------------------------
# DD-1038/DD-1039: --help must work (not die as an unrecognized
# option), and the usage text (both the --help output and the
# no-question-provided error) must name every real backend, including
# --nova - which already has a complete, working implementation
# (_ask_nova/_call_nova_api/NOVA_API_KEY) but was never mentioned in
# either usage string, making it look unsupported.
# ------------------------------------------------------------------
subtest '--help and usage text completeness' => sub {
    my $exit;
    my $out = '';
    eval { $exit = $M->can('run_ask')->( args => ['--help'], out => \$out ); 1 };
    is( $@, '', '--help does not die (DD-1038: it used to fail GetOptionsFromArray as an unrecognized option)' );
    is( $exit, 0, '--help exits 0' );
    like( $out, qr/--claude/, '--help output names --claude' );
    like( $out, qr/--codex/, '--help output names --codex' );
    like( $out, qr/--copilot/, '--help output names --copilot' );
    like( $out, qr/--gemini/, '--help output names --gemini' );
    like( $out, qr/--nova/, '--help output names --nova (DD-1039: nova already works, it was just never documented in any usage text)' );

    eval { $M->can('run_ask')->( args => [], out => \my $o ); 1 };
    like( $@, qr/--nova/, 'the No-question-provided usage line also names --nova, not just claude/codex/copilot/gemini' );
};

subtest 'API error handling' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-env';
    local $ENV{WORKSPACE_REF}     = 'ws/apierr';
    my $bad_status = FakeUA->new(
        sub { my $r = HTTP::Response->new( 500, 'Server Error' ); $r->content('boom'); return $r; } );
    eval { $M->can('run_ask')->( args => ['q'], ua => $bad_status, out => \my $o ); 1 };
    like( $@, qr/Claude API request failed: 500/, 'HTTP error surfaced' );

    my $no_content = FakeUA->new(
        sub { my $r = HTTP::Response->new( 200, 'OK' ); $r->content( json_encode( { foo => 1 } ) ); return $r; } );
    eval { $M->can('run_ask')->( args => ['q'], ua => $no_content, out => \my $o2 ); 1 };
    like( $@, qr/no content/, 'missing content array error' );

    my $no_text = FakeUA->new(
        sub {
            my $r = HTTP::Response->new( 200, 'OK' );
            $r->content( json_encode( { content => [ { type => 'tool_use' } ] } ) );
            return $r;
        }
    );
    eval { $M->can('run_ask')->( args => ['q'], ua => $no_text, out => \my $o3 ); 1 };
    like( $@, qr/no text/, 'no text blocks error' );
};

subtest 'workspace key derivation + sanitization' => sub {
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is( $M->can('_workspace_key')->( $paths, { WORKSPACE_REF => 'a/b c!' } ), 'a-b-c', 'sanitized' );
    is( $M->can('_workspace_key')->( $paths, { WORKSPACE_REF => '///' } ),     'global', 'all-invalid falls back to global' );
    # With no WORKSPACE_REF the key derives from the active project root; assert
    # it is a non-empty, filesystem-safe token (exercises that fallback path).
    my $derived = $M->can('_workspace_key')->( $paths, {} );
    like( $derived, qr/\A[A-Za-z0-9._-]+\z/, 'project-derived key is filesystem-safe and non-empty' );
};

subtest 'transcript load resilience' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $missing = File::Spec->catfile( $dir, 'none.json' );
    my $shell = $M->can('_load_transcript')->($missing);
    is_deeply( $shell, { backend => '', messages => [] }, 'absent file yields empty shell' );

    my $bad = File::Spec->catfile( $dir, 'bad.json' );
    open my $bf, '>', $bad or die $!; print {$bf} 'not json{'; close $bf;
    my $shell2 = $M->can('_load_transcript')->($bad);
    is_deeply( $shell2, { backend => '', messages => [] }, 'corrupt file yields empty shell' );

    my $partial = File::Spec->catfile( $dir, 'partial.json' );
    open my $pf, '>', $partial or die $!; print {$pf} json_encode( { backend => 'codex' } ); close $pf;
    my $loaded = $M->can('_load_transcript')->($partial);
    is( $loaded->{backend}, 'codex', 'backend preserved' );
    is_deeply( $loaded->{messages}, [], 'missing messages normalized to []' );
};

subtest 'unit seams: _run_cli, _default_ua, slurp_file, _emit' => sub {
    my ( $so, $se, $ex ) = $M->can('_run_cli')->( [ $^X, '-e', 'print "hi"; warn "werr\n"; exit 0' ] );
    is( $so, 'hi',    '_run_cli captures stdout' );
    like( $se, qr/werr/, '_run_cli captures stderr' );
    is( $ex, 0, '_run_cli exit 0' );
    my ( undef, undef, $ex2 ) = $M->can('_run_cli')->( [ $^X, '-e', 'exit 3' ] );
    is( $ex2, 3, '_run_cli propagates exit code' );

    my $ua = $M->can('_default_ua')->();
    isa_ok( $ua, 'LWP::UserAgent', '_default_ua' );

    # DD-948: _run_cli must TEE the child's stdout to our own STDOUT live, not
    # only return it after the child exits - that live echo is what makes
    # "dashboard ask" show progress instead of sitting silent until done.
    # Redirect our own STDOUT to a temp file, feed the child a real 0.3s
    # delay before it prints so a buffer-then-return implementation would
    # still pass "eventually contains the text" but this asserts something
    # buffering cannot: the text is on disk WHILE the child is still running,
    # not only after _run_cli returns.
    subtest '_run_cli tees stdout live instead of buffering until exit' => sub {
        my $tee_file = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'tee-live.out' );
        open my $tee_fh, '>', $tee_file or die "Unable to open $tee_file: $!";
        my $old_stdout_fd;
        open $old_stdout_fd, '>&', \*STDOUT or die "Unable to dup STDOUT: $!";
        open STDOUT, '>&', $tee_fh or die "Unable to redirect STDOUT: $!";

        my $during_run_content;
        my ( $stdout, undef, $exit ) = $M->can('_run_cli')->(
            [ $^X, '-e', '$| = 1; print "DD948-LIVE\n"; select( undef, undef, undef, 0.3 );' ] );

        # _run_cli has already returned above; re-open our own STDOUT back to
        # normal BEFORE reading the tee file, so the read itself is honest.
        open STDOUT, '>&', $old_stdout_fd or die "Unable to restore STDOUT: $!";
        close $tee_fh;

        open my $read_fh, '<', $tee_file or die "Unable to read $tee_file: $!";
        local $/;
        $during_run_content = <$read_fh>;
        close $read_fh;

        like( $during_run_content, qr/DD948-LIVE/, 'the child\'s stdout reached our real STDOUT (teed), not only the return value' );
        like( $stdout, qr/DD948-LIVE/, '_run_cli still returns the full captured text for the caller to use' );
        is( $exit, 0, 'clean exit code still reported' );
    };

    my $empty = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'empty' );
    open my $ef, '>', $empty or die $!; close $ef;
    is( Developer::Dashboard::FileSlurp::slurp_file( $empty, raw => 1, missing_message => 'Unable to read attachment %s: %s', normalize_undef => 1 ),
        '', 'slurp_file (Ask.pm-shaped call) of empty file is empty string' );
    eval {
        Developer::Dashboard::FileSlurp::slurp_file( "$home/no-such-slurp",
            raw => 1, missing_message => 'Unable to read attachment %s: %s' );
        1;
    };
    like( $@, qr/Unable to read attachment/, 'slurp_file (Ask.pm-shaped call) dies on unreadable' );

    my $buf = '';
    $M->can('_emit')->( \$buf, 'noNL' );
    is( $buf, "noNL\n", '_emit appends newline to scalar ref' );
    open my $mem, '>', \my $fhbuf or die $!;
    $M->can('_emit')->( $mem, "hasNL\n" );
    close $mem;
    is( $fhbuf, "hasNL\n", '_emit writes to filehandle without doubling newline' );

    my ( $stdout, undef, undef ) = capture { $M->can('_emit')->( undef, 'to-stdout' ); };
    is( $stdout, "to-stdout\n", '_emit defaults to STDOUT when no sink is given' );
};

subtest 'transcript is written owner-only under state root' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-env';
    local $ENV{WORKSPACE_REF}     = 'ws/perm';
    $M->can('run_ask')->( args => ['q'], ua => FakeUA->new( api_reply('a') ), out => \my $o );
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    my $file = $M->can('_transcript_file')->( $paths, 'ws-perm' );
    ok( -f $file, 'transcript persisted' );
  SKIP: {
        skip 'permission bits not meaningful here', 1 if $^O eq 'MSWin32';
        my $mode = ( stat $file )[2] & 07777;
        is( $mode, 0600, 'transcript is 0600' );
    }
};

# --------------------------------------------------------------------------
# DD-938: `dashboard ask --docs` prints curated onboarding context and never
# touches an AI backend or writes any file - a pure, cheap, static stdout
# path, distinct from every other test above which exercises a real (faked)
# backend round-trip.
# --------------------------------------------------------------------------
subtest 'DD-938: ask --docs prints curated context, touches no backend, writes no file' => sub {
    my $work = tempdir( CLEANUP => 1 );
    my $before_cwd = getcwd();
    chdir $work or die "Unable to chdir to $work: $!";

    my @before_entries = sort glob('*');
    my $ua_called = 0;
    my $rc = $M->can('run_ask')->(
        args => ['--docs'],
        ua   => FakeUA->new( sub { $ua_called++; api_reply('unused')->(@_) } ),
        out  => \my $out,
    );
    chdir $before_cwd or die "Unable to chdir back to $before_cwd: $!";

    is( $rc, 0, '--docs exits 0' );
    ok( length($out) > 0, '--docs prints non-empty output' );
    like( $out, qr/cli/i, '--docs output mentions the cli/ dot-notation convention' );
    is( $ua_called, 0, '--docs never touches the AI backend' );
    my @after_entries = sort glob("$work/*");
    is_deeply( \@after_entries, [], '--docs writes no file into the current directory' );
};

# --------------------------------------------------------------------------
# DD-938 (auto-inject, owner-corrected scope): a workspace's FIRST-EVER
# plain `dashboard ask` call (no --docs flag) silently gets the curated
# docs context prepended to that turn's prompt - zero flag, zero injected
# instruction line. The SECOND call in the same workspace must NOT repeat
# it, since it is already in that conversation's own history from turn 1.
# --------------------------------------------------------------------------
subtest 'DD-938: first ask call in a workspace auto-includes docs context, second does not' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-env';
    local $ENV{WORKSPACE_REF}     = 'ws/dd938-auto';
    my $ua = FakeUA->new( api_reply('ok') );

    my $rc1 = $M->can('run_ask')->( args => ['first real question'], ua => $ua, out => \my $out1 );
    is( $rc1, 0, 'first call exits 0' );
    my $first_body = $ua->{requests}[0]->content;
    like( $first_body, qr/DD-OOP-LAYERS/, 'first call includes the docs context in what is sent to the backend' );
    like( $first_body, qr/first real question/, 'first call still includes the actual question' );

    my $rc2 = $M->can('run_ask')->( args => ['second real question'], ua => $ua, out => \my $out2 );
    is( $rc2, 0, 'second call exits 0' );
    my $second_body = json_decode( $ua->{requests}[1]->content );
    # The docs context legitimately appears once, in the REPLAYED first
    # turn (real conversation history a backend needs) - the thing DD-938
    # actually guards against is a SECOND, redundant copy prepended to the
    # new turn itself.
    is( scalar @{ $second_body->{messages} }, 3, 'history replayed + new turn, no extra turn added' );
    like( $second_body->{messages}[0]{content}, qr/DD-OOP-LAYERS/, 'the docs context is present via the replayed first turn' );
    is( $second_body->{messages}[2]{content}, 'second real question', 'the NEW turn itself has no redundant second copy of the docs context' );
};

# --------------------------------------------------------------------------
# DD-942: pre-existing branch/condition coverage gaps in Ask.pm, confirmed
# on clean master before DD-938 ever touched this file. Each subtest below
# targets one specific missing outcome named on the card, exercised either
# through run_ask's public interface or, where the branch lives in an
# internal helper the public interface cannot reach directly, via $M->can()
# the same way the existing 'unit seams'/'transcript load resilience'
# subtests above already do.
# --------------------------------------------------------------------------
subtest 'DD-942: claude CLI fallback with no --model (the model-omitted branch)' => sub {
    # run_ask itself always resolves a model for the 'claude' backend (an
    # explicit --model, else claude_conf's default_model, else
    # $DEFAULT_MODEL) - so $a{model} is never actually undef on that path
    # through the public interface. The false branch of "if defined
    # $a{model}" is only reachable by calling _ask_claude directly with no
    # model key at all, exactly as this test does.
    my @calls;
    my $answer = $M->can('_ask_claude')->(
        env         => {},
        claude_conf => {},
        images      => [],
        history     => [],
        prompt      => 'via cli no model',
        text_files  => [],
        detect      => \&detect_present,
        runner      => rec_runner( \@calls, "CLI ANSWER\n", '', 0 ),
    );
    is( $answer, 'CLI ANSWER', 'claude CLI answer returned' );
    my @argv = @{ $calls[0] };
    ok( !( grep { $_ eq '--model' } @argv ), 'no --model token forwarded when $a{model} was never set' );
};

subtest 'DD-942: stdin explicitly present but empty string is treated as absent' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-env';
    local $ENV{WORKSPACE_REF}     = 'ws/stdin-empty';
    my $ua = FakeUA->new( api_reply('ok') );
    $M->can('run_ask')->( args => ['just the prompt'], stdin => '', ua => $ua, out => \my $o );
    my $body = json_decode( $ua->{requests}[0]->content );
    # Fresh workspace, so DD-938's auto-docs-injection prepends its own
    # context to turn one - assert the PROMPT PORTION has no piped stdin
    # appended, not full equality against the bare prompt.
    unlike( $body->{messages}[0]{content}, qr/\n\n\z|\A\z/, 'no trailing blank-appended stdin block' );
    like( $body->{messages}[0]{content}, qr/just the prompt\z/, 'an empty-string stdin never gets appended after the prompt' );
};

subtest 'DD-942: _resolve_backend falls through to claude when the stored transcript backend is unknown' => sub {
    my $resolved = $M->can('_resolve_backend')->( { backend => '' }, { backend => 'not-a-real-backend' } );
    is( $resolved, 'claude', 'an unrecognized stored backend name is not trusted; falls back to claude' );
};

subtest 'DD-942: _capture_backend edge cases' => sub {
    # undef stderr on a non-zero exit: the s/// guard must not warn/die on undef.
    my $out1 = eval { $M->can('_capture_backend')->( 'x', ['argv'], sub { return ( '', undef, 1 ); } ) };
    like( $@, qr/x backend failed: exit status 1/, 'undef stderr falls back to "exit status N", no warning on the undef s///' );

    # stderr present but only whitespace, after trimming becomes '' -> "exit status N" branch.
    eval { $M->can('_capture_backend')->( 'y', ['argv'], sub { return ( '', "   \n", 1 ); } ) };
    like( $@, qr/y backend failed: exit status 1/, 'whitespace-only stderr trims to empty, falls back to "exit status N"' );

    # detail long enough to trigger the truncation branch (lines 354-357).
    my $huge = 'E' x 10_100;
    eval { $M->can('_capture_backend')->( 'z', ['argv'], sub { return ( '', $huge, 1 ); } ) };
    like( $@, qr/truncated, \d+ more bytes? omitted/, 'an oversized stderr detail is truncated with a byte count' );

    # undef stdout on success (exit 0): the "$stdout = '' if !defined" branch.
    eval { $M->can('_capture_backend')->( 'w', ['argv'], sub { return ( undef, '', 0 ); } ) };
    like( $@, qr/w backend returned no answer/, 'undef stdout on success is normalized to empty and reported as no answer' );
};

subtest 'DD-942: _resolve_api_key branch combinations' => sub {
    is( $M->can('_resolve_api_key')->( {}, { ANTHROPIC_API_KEY => 'from-env' } ), 'from-env', 'env key wins when present' );
    is( $M->can('_resolve_api_key')->( { api_key => 'from-conf' }, {} ), 'from-conf', 'falls back to config api_key when env is absent' );
    is( $M->can('_resolve_api_key')->( { api_key => 'from-conf' }, { ANTHROPIC_API_KEY => '' } ), 'from-conf', 'an empty-string env key is treated as absent, falls back to config' );
    is( $M->can('_resolve_api_key')->( {}, {} ), '', 'neither source set yields the empty-string sentinel' );
};

subtest 'DD-942: _classify_files with an extensionless attachment' => sub {
    my $noext = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'noext' );
    open my $fh, '>', $noext or die $!; print {$fh} 'plain body'; close $fh;
    my ( $images, $texts ) = $M->can('_classify_files')->( [$noext] );
    is( scalar @{$images}, 0, 'an extensionless file is never classified as an image' );
    is( $texts->[0]{path}, $noext, 'it is classified as a text attachment instead' );
};

subtest 'DD-942: _build_api_messages with no history and no images' => sub {
    my $messages = $M->can('_build_api_messages')->( undef, 'plain question', undef, undef );
    is( scalar @{$messages}, 1, 'no history means only the new turn' );
    is( $messages->[0]{content}, 'plain question', 'plain string content when there are no images' );

    my $messages2 = $M->can('_build_api_messages')->( undef, 'q', undef, [] );
    is( $messages2->[0]{content}, 'q', 'an empty (defined) images array ref behaves the same as no images' );
};

subtest 'DD-942: _render_history with no history' => sub {
    is( $M->can('_render_history')->(undef), '', 'undef history renders as the empty string' );
    is( $M->can('_render_history')->( [] ),  '', 'empty-array history renders as the empty string' );
};

subtest 'DD-942: _inline_text_files with no text attachments' => sub {
    is( $M->can('_inline_text_files')->( 'bare prompt', undef ), 'bare prompt', 'undef text_files leaves the prompt untouched' );
    is( $M->can('_inline_text_files')->( 'bare prompt', [] ),    'bare prompt', 'empty text_files array leaves the prompt untouched' );
};

subtest 'DD-942: _extract_api_text content-block filtering' => sub {
    my $text = $M->can('_extract_api_text')->( { content => [ { type => 'tool_use' }, { type => 'text', text => 'kept' } ] } );
    is( $text, 'kept', 'a non-text block ahead of a real text block is skipped, not concatenated' );

    eval { $M->can('_extract_api_text')->( { content => [ { type => 'text' } ] } ) };
    like( $@, qr/no text/, 'a text-type block with no text key contributes nothing and still reports no-text' );
};

subtest 'DD-942: _build_config with HOME unset in the passed env' => sub {
    my $config = $M->can('_build_config')->( {} );
    isa_ok( $config, 'Developer::Dashboard::Config', '_build_config tolerates a passed env with no HOME key' );
};

subtest 'DD-942: run_ask with no env key at all falls back to %ENV' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-env';
    local $ENV{WORKSPACE_REF}     = 'ws/no-env-key';
    my $ua = FakeUA->new( api_reply('ok') );
    my $exit = $M->can('run_ask')->( args => ['q'], ua => $ua, out => \my $o );
    is( $exit, 0, 'run_ask with no env => key at all still works, reading real %ENV' );
};

subtest 'DD-942: truncation message pluralization boundary (exactly 1 byte omitted)' => sub {
    my $detail_len = 4_001;    # MAX_BACKEND_ERROR_DETAIL_BYTES(4000) + 1 omitted byte
    my $detail     = 'E' x $detail_len;
    eval { $M->can('_capture_backend')->( 'z', ['argv'], sub { return ( '', $detail, 1 ); } ) };
    like( $@, qr/truncated, 1 more byte omitted\)/, 'exactly one omitted byte uses the singular "byte", not "bytes"' );
};

subtest 'DD-942: _resolve_api_key with a defined-but-empty config api_key' => sub {
    is( $M->can('_resolve_api_key')->( { api_key => '' }, {} ), '', 'an empty-string config api_key is treated the same as absent' );
};

subtest 'DD-942: _classify_files with no files at all' => sub {
    my ( $images, $texts ) = $M->can('_classify_files')->(undef);
    is_deeply( $images, [], 'undef files yields an empty images list' );
    is_deeply( $texts,  [], 'undef files yields an empty texts list' );
};

subtest 'DD-942: _extract_api_text with a non-hash data payload' => sub {
    eval { $M->can('_extract_api_text')->( [1, 2, 3] ) };
    like( $@, qr/no content/, 'a non-hash response payload is rejected before ever inspecting content' );
};

subtest 'DD-942: _extract_api_text skips a non-hash content block' => sub {
    my $text = $M->can('_extract_api_text')->( { content => [ 'a bare string, not a hashref', { type => 'text', text => 'real' } ] } );
    is( $text, 'real', 'a non-hashref content entry is skipped rather than causing a fatal dereference' );
};

subtest 'DD-942: _workspace_key falls all the way through to "global" when there is no project root either' => sub {
    my $rootless = tempdir( CLEANUP => 1 );
    my $paths = Developer::Dashboard::PathRegistry->new( home => $rootless, cwd => $rootless );
    is( $paths->current_project_root, undef, 'control: a plain non-git tempdir has no derivable project root' );
    is( $M->can('_workspace_key')->( $paths, {} ), 'global', 'no WORKSPACE_REF and no project root both fall through to the literal "global" key' );
};

subtest 'DD-942: _run_cli reports exit -1 when the command itself cannot be launched' => sub {
    my @result;
    my $teed = capture_stderr { @result = $M->can('_run_cli')->( ['/nonexistent-binary-xyz-does-not-exist-anywhere'] ) };
    my ( undef, $err, $exit ) = @result;
    is( $exit, -1, 'a system() that never launches (exec failure) reports exit -1, not a shifted 0' );
    like( $err, qr/Can't exec "\/nonexistent-binary-xyz-does-not-exist-anywhere"/, 'the exec failure is reported in the captured standard error' );
    like( $teed, qr/Can't exec/, 'the live tee echoes the exec failure instead of leaking it into the test output' );
};

subtest 'DD-942: run_ask with an explicit env hash ref (not falling back to %ENV)' => sub {
    my $ua = FakeUA->new( api_reply('ok') );
    my $exit = $M->can('run_ask')->(
        args => ['q'],
        ua   => $ua,
        out  => \my $o,
        env  => { ANTHROPIC_API_KEY => 'sk-explicit', WORKSPACE_REF => 'ws/explicit-env' },
    );
    is( $exit, 0, 'an explicitly-passed env hash ref is honoured directly, never falling through to \%ENV' );
};

subtest 'DD-942: _extract_api_text skips a content block with no type key at all' => sub {
    my $text = $M->can('_extract_api_text')->( { content => [ { text => 'no type key here' }, { type => 'text', text => 'kept' } ] } );
    is( $text, 'kept', 'a block missing "type" entirely (undef, not just non-text) is skipped via the || \'\' fallback' );
};

subtest 'DD-942: _workspace_key with WORKSPACE_REF explicitly the empty string (defined, not absent)' => sub {
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    my $key = $M->can('_workspace_key')->( $paths, { WORKSPACE_REF => '' } );
    like( $key, qr/\A[A-Za-z0-9._-]+\z/, 'a defined-but-empty WORKSPACE_REF (distinct from absent/undef) still falls through to a real key' );
};

subtest 'DD-942: _load_transcript on a file the process cannot read' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $unreadable = File::Spec->catfile( $dir, 'unreadable.json' );
    open my $fh, '>', $unreadable or die $!;
    print {$fh} json_encode( { backend => 'codex' } );
    close $fh;
  SKIP: {
        chmod 0000, $unreadable or skip 'chmod not honored on this filesystem', 1;
        # Probe by attempting, never by predicate: Perl's filetest operators
        # are mode-bit arithmetic and special-case uid 0, so -r (or checking
        # $>) answers true/0 for root even where the open below is
        # genuinely denied on a non-root host - t/168's own repo-wide guard
        # requires this exact probe-then-restore shape (matching
        # t/103/t/115's own established pattern), not a uid check.
        if ( open my $probe, '<', $unreadable ) {
            close $probe or die "Unable to close probe on $unreadable: $!";
            chmod 0600, $unreadable;
            skip 'this process can read a mode-0000 file (likely root), so the open failure cannot occur', 1;
        }
        my $shell = $M->can('_load_transcript')->($unreadable);
        is_deeply( $shell, { backend => '', messages => [] }, 'a file that exists but cannot be opened yields the same empty shell as a missing one' );
        chmod 0600, $unreadable;    # restore so File::Temp's own cleanup can remove it
    }
};

subtest 'DD-942: _load_transcript normalizes a transcript with no backend key at all' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $no_backend_key = File::Spec->catfile( $dir, 'no-backend.json' );
    open my $fh, '>', $no_backend_key or die $!;
    print {$fh} json_encode( { messages => [] } );
    close $fh;
    my $loaded = $M->can('_load_transcript')->($no_backend_key);
    is( $loaded->{backend}, '', 'a transcript JSON with no "backend" key at all gets one normalized in as the empty string' );
};

done_testing;

__END__

=pod

=head1 NAME

t/48-ask.t - regression contract for the dashboard ask AI-backend command

=head1 PURPOSE

This test is the executable regression contract for C<dashboard ask>. It pins
backend selection and stickiness, per-workspace conversation memory, attachment
handling, the Anthropic API request shape, the claude CLI fallback, and every
error path, driving the ask CLI module to full statement and subroutine
coverage without shelling out to a real assistant or hitting the network.

=head1 WHY IT EXISTS

The ask command routes one uniform surface over several assistant backends and
keeps a stored conversation, so it has many branches that must stay correct:
which backend runs, whether a key or the CLI answers, how files attach per
backend, and how the transcript is keyed and secured. This test exists so those
branches fail loudly if the ask module regresses, using injected HTTP, runner,
and detector seams so the behavior is deterministic and offline.

=head1 WHEN TO USE

Use this file when changing C<dashboard ask> syntax, adding or adjusting an
assistant backend, changing the Anthropic API request, changing attachment
inlining or encoding, or changing where and how the per-workspace transcript is
stored.

=head1 HOW TO USE

Run C<prove -lv t/48-ask.t> while iterating on the ask module. Keep it green
under C<prove -lr t> and confirm the ask module still reports 100% statement and
subroutine coverage before calling the work complete.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the coverage gate all use
this file to keep the ask backends and conversation memory behaving correctly.

=head1 EXAMPLES

Example 1:

  prove -lv t/48-ask.t

Run the dedicated ask regression check by itself.

Example 2:

  prove -lr t

Run the ask regression inside the full repository suite before release.

=cut
