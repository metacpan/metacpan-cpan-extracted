package Test::Raider::Scenario;
# ABSTRACT: Run scenario files: a scripted model drives the real raider and its real tools

use strict;
use warnings;
use utf8;
use Exporter 'import';
use Test2::V0;
use Path::Tiny;
use YAML::PP;
use Test::Raider::MockAI qw( mock_app );
use Test::Raider::SlowAI qw( slow_app );
use Test::Raider::FakeProc qw( fake_proc );
use Test::Raider::Git qw( have_git git_in );
use Test::Raider::LocalHTTP;
use IO::Async::Loop;
use Langertha::Raider::Loadguard;

our @EXPORT_OK = qw( run_scenario_files );

# The engine of t/200_scenarios.t (t/scenarios/*.yml) and
# t/181_claude_log_scenarios.t (t/scenarios/claude-logs/*.yml, drafted from
# Claude Code sessions by maint/claude-log-to-scenario, then curated):
#
#   use Test::Raider::Scenario qw( run_scenario_files );
#   run_scenario_files( sort glob "$FindBin::Bin/scenarios/*.yml" );
#   done_testing;
#
# Each file becomes one subtest; the caller plans (done_testing). Needs
# Langertha::Engine::Virtual (Langertha 0.504 or later): the test skips
# before it loads this module when that is missing.
#
# Each F<t/scenarios/NN-name.yml> is one step of what raider has to do end to
# end. The model is scripted (Test::Raider::MockAI); the application, the raid
# loop and the stock tools are real, working inside a fresh temporary root.
#
#   title:   what the scenario shows
#   files:   { path => content }        written to the root before the run
#   git:     true                       the root is a git repository: after `files:` are
#            written, git init (branch main), a local user, and everything
#            committed (Test::Raider::Git: no global or system git
#            configuration is read). The scenario is skipped when git is
#            missing. The root is the repository root, so a Claude-layout
#            scenario (.claude/ in `files:`) puts its worktrees in
#            ROOT/.claude/worktrees, a native one in ROOT/.raider/worktrees.
#   age:     { path => seconds }        how long ago the file was last modified (default: now)
#   http:    { /path => { status, type, body, location } }  a local web server
#            (Test::Raider::LocalHTTP) on the application's loop; {{HTTP}} in
#            the strings of `script:` (and in a location) is its base URL,
#            {{HTTP_OTHER}} the same server under another host name
#   proc:    { memory_full, swap, cpus, processes }  a fake /proc the loadguard gate measures
#            (Test::Raider::FakeProc); with it the gate is on, without it off
#   env:     { LOADGUARD_* => value }   the environment of that gate
#   ask:     [ answer, ... ]            the person at the keyboard; ask_user gets these in order
#            (without the key nobody can answer)
#   home:    { path => content }        written to the home: every scenario runs
#            with $HOME at a fresh temporary directory and no
#            $CLAUDE_CONFIG_DIR, so none sees the real ~/.raider or ~/.claude;
#            %ENV is restored after each scenario. In the content of both,
#            and in the strings of `script:`, {{HOME}} and {{ROOT}} stand for
#            the two directories, {{PERL}} for the perl running the tests and
#            {{MCP_TEST_SERVER}} for t/lib/mcp-test-server.pl (a stdio MCP
#            server, ADR 0029).
#   executable: [ path, ... ]           files of `files:` (or of `home:`, as ~/path)
#            made executable -- hook scripts
#   run_prompt: true                    run each prompt as Application->run_prompt
#            (the whole run: hooks before the prompt and after the answer,
#            ADR 0022) instead of Application->run; the answer is its response
#   app:     { argument => value }      more arguments for the application
#            (e.g. bare: 1, claude: 1)
#   permission_mode: the mode as --permission-mode would give it (ADR 0021).
#            Without the key a scenario runs in bypassPermissions: scenarios
#            test tools, not approvals, unless they say otherwise. `null`
#            gives none, so the mode comes from the config files and the
#            Claude settings (else default). Without `approve:` nobody approves
#            anything: a call the policy asks about is refused, as in a
#            one-shot run.
#   approve: [ once | session | no | 'no: reason', ... ]  the person approving
#            tool calls, one answer per question in order (as the REPL's 1/2/3);
#            when the list runs out the answer is no
#   mcp_answers: { server => approve | all | reject }  the person answering, before the
#            first prompt, about the project MCP servers that wait for an approval
#            (Application->ask_mcp_approvals, as the REPL asks; ADR 0029); a server
#            not named gets no answer and stays off
#   review:  [ yes | no | 'no: feedback', ... ]  the person reviewing plans of
#            exit_plan_mode, in order (without the key nobody reviews)
#   delay, sub_delay: seconds the main model (delay) and every subagent's model
#            (sub_delay) take to answer, on the application's loop
#            (Test::Raider::SlowAI instead of MockAI): work that runs on the loop
#            meanwhile -- a background subagent -- really runs in between. The
#            script is still consumed in the order the requests are answered.
#   wait_background: true               run each prompt with run_prompt( wait_background => 1 )
#            as a non-interactive run does (ADR 0027 section 3): the run does not
#            end before its background subagents, and goes on with their
#            notifications. Implies run_prompt.
#   prompt:  the user prompt (or `prompts:`, a list run one after the other on
#            the same raider, so the conversation carries over). A prompt
#            `/NAME ARGS` that names a user-invocable skill or custom command
#            runs as raider's /NAME (ADR 0030): Application->slash_run_request,
#            then run_prompt with its run options; a render that aborts sends
#            nothing and gives the outcome { status: 'not sent', error }
#   between: { N => { files => {...}, home => {...}, remove => [ path, ... ], remove_home => [...], reload => true } }
#            done before prompt N (0-based): files written or removed in the
#            root (or the home), then with reload the application reads its
#            context and permissions again (/reload)
#   script:  the model's answers, one per request:
#              - tool_calls: [ [ tool_name, { arguments } ], ... ]
#              - text: the final answer (or the answer of a tool's own model
#                call, e.g. web_fetch with a prompt)
#              - error: [ status, message ]   the request fails with that HTTP status
#            either of the first two with usage: { prompt_tokens, completion_tokens } reported
#   expect:
#     answer:      the final answer, exactly
#     outcome:     { status, error } of the last run_prompt (error: a regex)
#     files:       { path => content }  must exist afterwards with this content
#     absent:      [ path, ... ]        must not exist afterwards
#     branches:    { present: [ name, ... ], absent: [ name, ... ] }  local git branches
#                  of the root afterwards (needs `git: true`)
#     requests:    [ { index: N, contains: text, absent: text } ] -- the text of the
#                  conversation the model saw in request N (0-based); with
#                  offers: [ tool, ... ] the tools that request offered, exactly (any
#                  order), with lacks: [ tool, ... ] tools it must not offer, with
#                  tool_text: text the descriptions of the offered tools must contain, with
#                  tail: [ { role, contains }, ... ] its last messages, in order
#                  (the role on the wire: user, assistant, tool). A
#                  subagent's requests count in the same sequence, in the order made
#                  (the caller's agent call, the subagent's requests, the caller's next)
#     request_count: how many model requests were made in all
#     events:      [ { type => ..., fields } ] events of the application, in order; each
#                  is matched (as a subset) by the next event of its type
#     usage:       { input_tokens, output_tokens, calls, ... } the token ledger
#                  (Application->usage_stats) at the end, matched as a subset
#     questions:   [ { question => ..., options => [...] } ] what ask_user put to the person
#     permissions: [ { tool, rule, reason, ... } ] the calls the person was asked to approve,
#                  each matched as a subset (rule: what "for this session" would add)
#     plans:       [ text, ... ] the plans put to the person
#     todos:       [ { content, status } ] the task list at the end
#     tools:       one entry per tool call, in order:
#                    name:   the tool
#                    error:  true if the call must have failed (default false)
#                    text:   regex the result text must match; {{ROOT}} in it (and in
#                            not_text) is the root, quoted so it matches literally
#                    not_text: regex it must not match
#
# A new scenario is a new file; nothing here changes. Only the scenarios in
# `skip:` (a reason string) are skipped, so a known gap stays visible.

my $yaml  = YAML::PP->new( boolean => 'JSON::PP' );

# The stdio MCP server of the tests ({{MCP_TEST_SERVER}}, run with {{PERL}}).
my $MCP_TEST_SERVER = path(__FILE__)->parent->parent->parent->child('mcp-test-server.pl')->realpath->stringify;

sub run_scenario_files {
  my ( @files ) = @_;
  run_scenario_file($_) for @files;
  return;
}

sub run_scenario_file {
  my ( $file ) = @_;
  my $s    = $yaml->load_file($file);
  my $name = path($file)->basename;
  subtest "$name: " . ( $s->{title} // '' ) => sub {
    skip_all $s->{skip} if $s->{skip};
    skip_all 'needs git' if $s->{git} && !have_git();
    local %ENV = %ENV;
    my @tmp  = ( Path::Tiny->tempdir, Path::Tiny->tempdir );   # held: removed at the end
    my ( $root, $home ) = map { $_->realpath } @tmp;
    $ENV{HOME} = "$home";
    delete $ENV{CLAUDE_CONFIG_DIR};
    # A local web server for web_fetch, on the loop the application uses (held: stops at the end).
    my $http = $s->{http} ? Test::Raider::LocalHTTP->new( loop => IO::Async::Loop->new, routes => $s->{http} ) : undef;
    my $fill = sub {
      ( my $t = $_[0] ) =~ s/\{\{HOME\}\}/$home/g; $t =~ s/\{\{ROOT\}\}/$root/g;
      $t =~ s/\{\{PERL\}\}/$^X/g; $t =~ s/\{\{MCP_TEST_SERVER\}\}/$MCP_TEST_SERVER/g;
      $http ? $http->fill($t) : $t;
    };
    $root->child($_)->touchpath->spew_utf8( $fill->( $s->{files}{$_} ) ) for keys %{ $s->{files} // {} };
    $home->child($_)->touchpath->spew_utf8( $fill->( $s->{home}{$_} ) ) for keys %{ $s->{home} // {} };
    if ( $s->{git} ) {
      git_in( $root, qw( init -q -b main ) );
      git_in( $root, qw( config user.name Tester ) );
      git_in( $root, qw( config user.email tester@example.com ) );
      git_in( $root, qw( config commit.gpgsign false ) );
      git_in( $root, qw( add -A ) );
      git_in( $root, qw( commit -q --allow-empty -m initial ) );
    }
    ( m{\A~/(.+)\z}s ? $home->child($1) : $root->child($_) )->chmod(0755) for @{ $s->{executable} // [] };

    for my $path ( keys %{ $s->{age} // {} } ) {
      my $t = time - $s->{age}{$path};
      utime $t, $t, "$root/$path";
    }
    my ( @events, @questions, @gate, $proc_dir, @asked, @plans );
    if ( my $proc = $s->{proc} ) {
      $proc_dir = fake_proc(%$proc);    # kept for the whole scenario
      push @gate, loadguard => Langertha::Raider::Loadguard->new( proc_dir => "$proc_dir", env => $s->{env} // {} );
    }
    my @answers = @{ $s->{ask} // [] };
    my @approve = @{ $s->{approve} // [] };
    my @review  = @{ $s->{review} // [] };
    my $answer_of = sub {
      my ( $a ) = @_;
      return { answer => 'no' } unless defined $a;
      return { answer => 'no', reason => $1 } if $a =~ /\Ano:\s*(.*)\z/s;
      return { answer => $a };
    };
    # {{ROOT}} in an expected pattern: the root, quoted.
    my $in_root = sub { my ( $t ) = @_; $t =~ s/\{\{ROOT\}\}/quotemeta $root/ge if defined $t; $t };
    my $deep_fill;
    $deep_fill = sub {
      my ( $v ) = @_;
      return ref $v eq 'HASH' ? { map { $_ => $deep_fill->( $v->{$_} ) } keys %$v }
           : ref $v eq 'ARRAY' ? [ map { $deep_fill->($_) } @$v ]
           : defined $v && !ref $v ? $fill->($v)
           : $v;
    };
    my $make = ( $s->{delay} || $s->{sub_delay} ) ? \&slow_app : \&mock_app;
    my $app = $make->(
      ( $s->{delay} || $s->{sub_delay} ? ( delay => $s->{delay} // 0, sub_delay => $s->{sub_delay} // 0 ) : () ),
      root => "$root", script => $deep_fill->( $s->{script} // [] ), @gate,
      permission_mode => exists $s->{permission_mode} ? $s->{permission_mode} : 'bypassPermissions',
      %{ $s->{app} // {} },
      on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
      $s->{ask} ? ( on_ask_user => sub { push @questions, { question => $_[0], options => $_[1] }; shift @answers } ) : (),
      $s->{approve} ? ( on_permission_request => sub { push @asked, $_[0]; $answer_of->( shift @approve ) } ) : (),
      $s->{review} ? ( on_plan_review => sub {
        push @plans, $_[0];
        my $r = shift(@review) // 'no';
        return $r =~ /\A(?:yes|y)\z/ ? { approve => 1 } : { approve => 0, $r =~ /\Ano:\s*(.*)\z/s ? ( feedback => $1 ) : () };
      } ) : (),
    );
    # The person answering about pending project MCP servers before the first prompt (ADR 0029).
    if ( my $mcp_answers = $s->{mcp_answers} ) {
      $app->ask_mcp_approvals( sub { $mcp_answers->{ $_[0]{name} } } );
    }
    my @prompts = $s->{prompts} ? @{ $s->{prompts} } : ( $s->{prompt} // 'go' );
    my ( $answer, $outcome );
    for my $i ( 0 .. $#prompts ) {
      if ( my $b = ( $s->{between} // {} )->{$i} ) {
        $root->child($_)->touchpath->spew_utf8( $fill->( $b->{files}{$_} ) ) for keys %{ $b->{files} // {} };
        $home->child($_)->touchpath->spew_utf8( $fill->( $b->{home}{$_} ) ) for keys %{ $b->{home} // {} };
        $root->child($_)->remove for @{ $b->{remove} // [] };
        $home->child($_)->remove for @{ $b->{remove_home} // [] };
        $app->reload_context if $b->{reload};
      }
      my $p = $prompts[$i];
      $answer = eval {
        my @wait = $s->{wait_background} ? ( wait_background => 1 ) : ();
        # /NAME ARGS of a user-invocable catalogue entry: raider's /NAME run.
        # /mcp__SERVER__PROMPT ARGS: a prompt of a configured MCP server (ADR 0029 Addendum 1).
        my ( $cmd, $cmd_args ) = $p =~ m{\A/(\S+)\s*(.*?)\s*\z}s;
        if ( defined $cmd
             && ( my $req = $cmd =~ /\Amcp__/ ? $app->mcp_prompt_request( $cmd, length $cmd_args ? $cmd_args : undef )
                                              : $app->slash_run_request( $cmd, length $cmd_args ? $cmd_args : undef ) ) ) {
          if ( defined $req->{error} ) {
            $outcome = { status => 'not sent', error => $req->{error} };
            return undef;
          }
          $outcome = $app->run_prompt( delete $req->{prompt}, %$req, @wait );
          return $outcome->{response};
        }
        return '' . $app->run($p) unless $s->{run_prompt} || $s->{wait_background};
        $outcome = $app->run_prompt( $p, @wait );
        return $outcome->{response};
      };
    }
    my $failed = $@;
    $app->stop_background;    # no subagent outlives its scenario
    is( $failed, '', 'the raid finishes' );
    my $expect = $s->{expect} // {};

    is( $answer, $expect->{answer}, 'final answer' ) if exists $expect->{answer};
    if ( my $want = $expect->{outcome} ) {
      is( $outcome->{status}, $want->{status}, 'run status' ) if exists $want->{status};
      like( $outcome->{error} // '', qr/$want->{error}/s, 'run error' ) if defined $want->{error};
    }

    for my $p ( sort keys %{ $expect->{files} // {} } ) {
      ok( $root->child($p)->is_file, "$p exists" )
        && is( $root->child($p)->slurp_utf8, $expect->{files}{$p}, "$p content" );
    }
    ok( !$root->child($_)->exists, "$_ absent" ) for @{ $expect->{absent} // [] };
    if ( my $want = $expect->{branches} ) {
      my %have = map { ( s/\A[*+ ]+//r => 1 ) } split /\n/, git_in( $root, qw( branch --list ) );
      ok( $have{$_}, "branch $_ exists" ) for @{ $want->{present} // [] };
      ok( !$have{$_}, "branch $_ absent" ) for @{ $want->{absent} // [] };
    }

    for my $r ( @{ $expect->{requests} // [] } ) {
      my $req = $app->mock_engine->requests->[ $r->{index} ];
      ok( $req, "request $r->{index} was made" ) or next;
      my $seen = join "\n", map {
        my $c = $_->{content};
        ref $c ? join( ' ', map { $_->{text} // '' } @$c ) : ( $c // '' )
      } @{ $req->{body}{messages} // [] };
      like( $seen, qr/\Q$r->{contains}\E/, "request $r->{index} contains '$r->{contains}'" ) if defined $r->{contains};
      unlike( $seen, qr/\Q$r->{absent}\E/, "request $r->{index} lacks '$r->{absent}'" ) if defined $r->{absent};
      my %offered = map { ( $_->{function}{name} // $_->{name} // '' ) => 1 } @{ $req->{tools} // [] };
      is( [ sort keys %offered ], [ sort @{ $r->{offers} } ], "request $r->{index} offers exactly @{ $r->{offers} }" )
        if $r->{offers};
      ok( !$offered{$_}, "request $r->{index} does not offer $_" ) for @{ $r->{lacks} // [] };
      if ( defined $r->{tool_text} ) {
        my $texts = join "\n", map { $_->{function}{description} // $_->{description} // '' } @{ $req->{tools} // [] };
        like( $texts, qr/\Q$r->{tool_text}\E/, "request $r->{index} tool texts contain '$r->{tool_text}'" );
      }
      if ( my $tail = $r->{tail} ) {
        my @msgs = @{ $req->{body}{messages} // [] };
        @msgs = @msgs > @$tail ? @msgs[ -@$tail .. -1 ] : @msgs;
        is( scalar @msgs, scalar @$tail, "request $r->{index} has the tail's messages" );
        for my $i ( 0 .. $#$tail ) {
          my ( $w, $m ) = ( $tail->[$i], $msgs[$i] // {} );
          is( $m->{role}, $w->{role}, "request $r->{index}, tail message $i: role" ) if defined $w->{role};
          my $c = $m->{content};
          my $text = ref $c ? join( ' ', map { $_->{text} // '' } @$c ) : ( $c // '' );
          like( $text, qr/\Q$w->{contains}\E/, "request $r->{index}, tail message $i contains '$w->{contains}'" )
            if defined $w->{contains};
        }
      }
    }

    is( scalar @{ $app->mock_engine->requests }, $expect->{request_count}, 'number of model requests' )
      if defined $expect->{request_count};

    if ( my $want = $expect->{events} ) {
      my @pool = @events;
      for my $w (@$want) {
        shift @pool while @pool && $pool[0]{type} ne $w->{type};
        my $e = shift @pool;
        ok( $e, "event $w->{type}" ) && like( $e, $w, "event $w->{type}: fields" );
      }
    }
    like( $app->usage_stats, $expect->{usage}, 'token ledger (usage_stats)' ) if $expect->{usage};
    is( \@questions, $expect->{questions}, 'questions put to the person' ) if $expect->{questions};
    if ( my $want = $expect->{permissions} ) {
      is( scalar @asked, scalar @$want, 'number of approvals asked for' );
      like( $asked[$_], $want->[$_], "approval $_ asked for" ) for 0 .. $#$want;
    }
    is( \@plans, $expect->{plans}, 'plans put to the person' ) if $expect->{plans};
    is( [ map { +{ content => $_->{content}, status => $_->{status} } } @{ $app->todos } ], $expect->{todos}, 'the task list' )
      if $expect->{todos};

    if ( my $want = $expect->{tools} ) {
      my @got = @{ $app->mock_engine->results };
      is( scalar @got, scalar @$want, 'number of tool calls' );
      for my $i ( 0 .. $#$want ) {
        my $w = $want->[$i];
        my $g = $got[$i] or next;
        my $text = join "\n", map { $_->{text} // '' } @{ $g->{result}{content} // [] };
        my $tag  = "tool $i ($w->{name})";
        is( $g->{tool_call}{name}, $w->{name}, "$tag: name" );
        is( !!$g->{result}{isError}, !!$w->{error}, "$tag: " . ( $w->{error} ? 'fails' : 'succeeds' ) );
        like( $text, qr/${\ $in_root->( $w->{text} ) }/s, "$tag: result text" ) if defined $w->{text};
        unlike( $text, qr/${\ $in_root->( $w->{not_text} ) }/s, "$tag: result text excludes" ) if defined $w->{not_text};
      }
    }
  };
}

1;
