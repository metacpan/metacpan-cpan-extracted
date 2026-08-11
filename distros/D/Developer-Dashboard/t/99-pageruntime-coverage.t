#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use POSIX qw(:sys_wait_h);
use Capture::Tiny qw(capture);

use lib 'lib';

use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::RuntimeManager ();

# A tiny class exposed to the Template Toolkit method() helper so the helper's
# class/method/can validation can be driven through all of its branches.
{
    package Local::MethodHelper;
    sub greet { return "greeted-$_[1]"; }
}

# A fake IO::Select used to drive the post-exit drain loop deterministically.
{
    package Local::PostExitSelect;
    sub new    { my ( $class, @handles ) = @_; return bless { handles => [@handles] }, $class; }
    sub handles { return @{ $_[0]{handles} }; }
    sub remove  { return 1; }
}

# A truthy object that deliberately lacks a handles() method so the close and
# post-exit helpers exercise their "select cannot enumerate handles" branch.
{
    package Local::NoHandlesObj;
    sub new { return bless {}, shift; }
}

# Hermetic runtime rooted in a throwaway home, with the deepest runtime layer
# resolved from the current working directory.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";
delete local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS};

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

# L37 both sides: aliases truthy (left) vs falsy default (right).
my $runtime          = Developer::Dashboard::PageRuntime->new( paths => $paths, aliases => { alias_x => $home } );
my $runtime_no_paths = Developer::Dashboard::PageRuntime->new();
ok( ref($runtime),          'runtime with truthy aliases constructs' );
ok( ref($runtime_no_paths), 'runtime without paths or aliases constructs' );

my $ajax_dir = File::Spec->catdir( $paths->dashboards_root, 'ajax' );
make_path($ajax_dir);

# Convenience: write a file and return its path.
sub write_file {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

# ---- prepare_page / run_code_blocks missing-page die sides (L47, L73) --------
{
    eval { Developer::Dashboard::PageRuntime->prepare_page(); 1 };
    like( $@, qr/Missing page/, 'prepare_page dies without a page (also drives class-method self construction)' );
    eval { Developer::Dashboard::PageRuntime->run_code_blocks(); 1 };
    like( $@, qr/Missing page/, 'run_code_blocks dies without a page' );
}

# ---- run_code_blocks state / codes shape branches (L75, L77) -----------------
{
    my $falsy_state = Developer::Dashboard::PageDocument->new( id => 'falsy-state' );
    $falsy_state->{state} = 0;    # L75 right side: falsy state falls back to {}
    my $r1 = $runtime->run_code_blocks( page => $falsy_state, source => 'saved', runtime_context => {} );
    is_deeply( $r1, { outputs => [], errors => [] }, 'run_code_blocks tolerates a falsy page state' );

    my $codes_hash = Developer::Dashboard::PageDocument->new( id => 'codes-hash' );
    $codes_hash->{meta}{codes} = { not => 'an-array' };    # L77 ref ne ARRAY true
    is_deeply( $runtime->run_code_blocks( page => $codes_hash ), { outputs => [], errors => [] }, 'non-array codes returns empty runtime result' );

    my $codes_empty = Developer::Dashboard::PageDocument->new( id => 'codes-empty' );
    $codes_empty->{meta}{codes} = [];    # L77 array but empty (!@$codes true)
    is_deeply( $runtime->run_code_blocks( page => $codes_empty ), { outputs => [], errors => [] }, 'empty codes array returns empty runtime result' );
}

# ---- run_code_blocks full loop: block shapes, returns, stdout/stderr ----------
{
    my $flow = Developer::Dashboard::PageDocument->new( id => 'flow', state => { existing => 1 } );
    $flow->{meta}{codes} = [
        'not-a-hash',                                # L89 true: non-hash block skipped
        { id => 'CODE0' },                           # L90 undef body -> '' ; L91 empty -> skip
        { id => 'CODE1', body => '' },               # L91 empty body true
        { id => 'CODE2', body => 'print "OUT";' },   # stdout chunk (L136)
        { id => 'CODE3', body => 'warn "ERRTEXT";' },# stderr chunk (L137 true, L134)
        { id => 'CODE4', body => 'return { merged => 1 };' },    # hash return (L117 true, L124, L128 hash)
        { id => 'CODE5', body => 'return [ 1, 2 ];' },           # array return (L128 array)
        { id => 'CODE6', body => 'return "scalarval";' },        # scalar return (L128 neither -> next)
    ];
    my $flow_result = $runtime->run_code_blocks( page => $flow, source => 'saved', runtime_context => {} );
    like( join( '', @{ $flow_result->{outputs} } ), qr/OUT/, 'run_code_blocks captures stdout output chunks' );
    like( join( '', @{ $flow_result->{errors} } ),  qr/ERRTEXT/, 'run_code_blocks captures stderr output chunks' );
    is( $flow->{state}{merged}, 1, 'run_code_blocks merges hash returns back into page state' );

    # L101 right side: run_code_blocks invoked without a source.
    my $nosrc = Developer::Dashboard::PageDocument->new( id => 'nosrc' );
    $nosrc->{meta}{codes} = [ { id => 'CODE1', body => 'print "x";' } ];
    my $nosrc_result = $runtime->run_code_blocks( page => $nosrc );
    like( join( '', @{ $nosrc_result->{outputs} } ), qr/x/, 'run_code_blocks runs without an explicit source' );
}

# ---- L117 false side: a blessed-hash state makes merge ref() ne 'HASH' --------
{
    my $blessed = bless { keep => 1 }, 'Local::BlessedState';
    my $bpage = Developer::Dashboard::PageDocument->new( id => 'blessed-merge' );
    $bpage->{state} = $blessed;
    $bpage->{meta}{codes} = [ { id => 'CODE1', body => '1;' } ];
    my $bresult = $runtime->run_code_blocks( page => $bpage, source => 'saved', runtime_context => {} );
    is_deeply( $bresult->{errors}, [], 'blessed-hash state runs cleanly while skipping the hash merge branch' );
}

# ---- __DD_STOP__ handling: message, empty, and no-newline (L110 / conditions) -
{
    my $stop_msg = Developer::Dashboard::PageDocument->new( id => 'stop-msg' );
    $stop_msg->{meta}{codes} = [ { id => 'CODE1', body => 'stop("boom-msg");' } ];
    my $sm = $runtime->run_code_blocks( page => $stop_msg, source => 'saved', runtime_context => {} );
    like( join( '', @{ $sm->{errors} } ), qr/boom-msg/, 'stop() with a message records the trailing text (defined + non-empty)' );

    my $stop_empty = Developer::Dashboard::PageDocument->new( id => 'stop-empty' );
    $stop_empty->{meta}{codes} = [ { id => 'CODE1', body => 'stop();' } ];
    my $se = $runtime->run_code_blocks( page => $stop_empty, source => 'saved', runtime_context => {} );
    is_deeply( $se->{errors}, [], 'stop() with an empty message records nothing (defined but empty)' );

    my $stop_bare = Developer::Dashboard::PageDocument->new( id => 'stop-bare' );
    $stop_bare->{meta}{codes} = [ { id => 'CODE1', body => 'die "__DD_STOP__";' } ];
    my $sb = $runtime->run_code_blocks( page => $stop_bare, source => 'saved', runtime_context => {} );
    is_deeply( $sb->{errors}, [], 'a bare __DD_STOP__ without a newline leaves the capture group undefined' );
}

# ---- _run_single_block direct calls: defaults, sandpit, source, page, env ----
{
    # No code / no state / no sandpit -> defaults + fresh sandpit created.
    my $bare = $runtime->_run_single_block();
    is( $bare->{stdout}, '', '_run_single_block defaults an undef code to empty output' );

    # Everything supplied, reusing an external sandpit (skip create + no destroy).
    my $sandpit = $runtime->_new_sandpit();
    my $full = $runtime->_run_single_block(
        code            => 'print "kept";',
        state           => { k => 1 },
        sandpit         => $sandpit,
        source          => 'saved',
        page            => 'plain-string',    # page truthy but not a ref (L285 B false)
        runtime_context => {},
    );
    like( $full->{stdout}, qr/kept/, '_run_single_block runs against a supplied sandpit' );
    $runtime->_destroy_sandpit($sandpit);

    # Page object (ref true) but non-skill source.
    my $obj_page = Developer::Dashboard::PageDocument->new( id => 'obj-page' );
    my $op = $runtime->_run_single_block( code => '1;', page => $obj_page );
    is( $op->{stderr}, '', '_run_single_block accepts a page object without a skill source' );

    # Skill source + skill page -> runtime_root / skill_name chain fully true.
    my $skill_page = Developer::Dashboard::PageDocument->new(
        id   => 'skill-page',
        meta => { skill_path => File::Spec->catdir( $home, 'skill' ), skill_name => 'myskill' },
    );
    my $sk = $runtime->_run_single_block( code => '1;', source => 'skill', page => $skill_page, runtime_context => {} );
    is( $sk->{stderr}, '', '_run_single_block resolves the skill runtime root when source is a skill page' );

    # Transient URL env matching (defined + regex match) and non-matching.
    {
        local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = '1';
        my $match = $runtime->_run_single_block( code => '1;', page => $skill_page );
        is( $match->{stderr}, '', '_run_single_block honours a matching transient-url env flag' );
    }
    {
        local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 'bogus';
        my $nomatch = $runtime->_run_single_block( code => '1;', page => $skill_page );
        is( $nomatch->{stderr}, '', '_run_single_block ignores a non-matching transient-url env flag' );
    }

    # Missing sandpit package -> die.
    eval { $runtime->_run_single_block( code => '1;', sandpit => {} ); 1 };
    like( $@, qr/Missing sandpit package/, '_run_single_block dies when the supplied sandpit lacks a package' );
}

# ---- _run_single_block AJAX_CONTEXT page_id + skill-chain short circuits ------
{
    # Page object without an id -> page_id resolves to empty (L285 id||'' right).
    my $idless = Developer::Dashboard::PageDocument->new;
    $runtime->_run_single_block( code => '1;', page => $idless );

    # source is a skill but there is no page -> chain stops at the page operand.
    $runtime->_run_single_block( code => '1;', source => 'skill' );

    # source is a skill but the page is not a reference.
    $runtime->_run_single_block( code => '1;', source => 'skill', page => 'plain' );

    # source is a skill, page is a document, but meta is not a hash.
    my $bad_meta = Developer::Dashboard::PageDocument->new( id => 'bad-meta' );
    $bad_meta->{meta} = [];
    $runtime->_run_single_block( code => '1;', source => 'skill', page => $bad_meta );

    # source is a skill with a valid meta hash but an empty skill_path and no skill_name.
    my $no_skill_path = Developer::Dashboard::PageDocument->new( id => 'no-skill-path', meta => {} );
    $runtime->_run_single_block( code => '1;', source => 'skill', page => $no_skill_path, runtime_context => {} );

    pass('_run_single_block exercises the AJAX context skill-chain short circuits');
}

# ---- _render_templates: page/layout/state/context/body/method/eval/errors ----
{
    eval { $runtime->_render_templates(); 1 };
    like( $@, qr/Missing page/, '_render_templates dies without a page' );

    # Undef layout + undef state fall back to empty hashes; body undef -> skipped.
    my $bare_page = Developer::Dashboard::PageDocument->new( id => 'bare-render' );
    $bare_page->{layout} = undef;
    $bare_page->{state}  = undef;
    $runtime->_render_templates( page => $bare_page );    # also L173 right: no runtime_context
    pass('_render_templates tolerates undef layout, state, and runtime context');

    # Empty body string -> L192 second condition.
    my $empty_body = Developer::Dashboard::PageDocument->new( id => 'empty-body', layout => { body => '' } );
    $runtime->_render_templates( page => $empty_body, runtime_context => {} );
    pass('_render_templates skips an empty body template');

    # method() helper across every validation branch.
    my $method_body =
        '[% method("Local::MethodHelper","greet","X") %]'
      . '[% method("","greet") %]'
      . '[% method("Local::MethodHelper","") %]'
      . '[% method("Local::MethodHelper","no_such_method") %]';
    my $method_page = Developer::Dashboard::PageDocument->new( id => 'method-page', state => {}, layout => { body => $method_body } );
    $runtime->_render_templates( page => $method_page, runtime_context => { a => 1 }, source => 'saved' );
    like( $method_page->{layout}{body}, qr/greeted-X/, '_render_templates method() helper calls valid class methods and skips invalid ones' );

    # eval() helper with a truthy source and no runtime context (L224 left, L223 right).
    my $eval_page = Developer::Dashboard::PageDocument->new( id => 'eval-page', state => {}, layout => { body => 'A[% eval("print q{INLINE};") %]B' } );
    $runtime->_render_templates( page => $eval_page, source => 'saved' );
    is( $eval_page->{layout}{body}, 'AINLINEB', '_render_templates eval() helper injects inline stdout' );

    # eval() helper whose block writes to stderr -> die -> template error path.
    my $eval_err = Developer::Dashboard::PageDocument->new( id => 'eval-err', state => {}, layout => { body => '[% eval("warn q{evalboom}; print q{ignored};") %]' } );
    $runtime->_render_templates( page => $eval_err, source => 'saved', runtime_context => {} );
    is( $eval_err->{layout}{body}, '', '_render_templates clears the body when an eval() block reports stderr' );
    like( join( '', @{ $eval_err->{meta}{runtime_errors} || [] } ), qr/evalboom/, '_render_templates records the eval() stderr as a runtime error (fresh runtime_errors slot)' );

    # eval() helper with no source at all -> source defaults to '' (L221 right).
    my $eval_nosrc = Developer::Dashboard::PageDocument->new( id => 'eval-nosrc', state => {}, layout => { body => 'X[% eval("print q{Y};") %]Z' } );
    $runtime->_render_templates( page => $eval_nosrc );
    is( $eval_nosrc->{layout}{body}, 'XYZ', '_render_templates eval() helper runs without an explicit source' );

    # A page that already carries runtime_errors keeps the ||= skip branch (L239 left).
    my $prior_err = Developer::Dashboard::PageDocument->new( id => 'prior-err', state => {}, layout => { body => '[% THROW boom "x" %]' } );
    $prior_err->{meta}{runtime_errors} = ['prior'];
    $runtime->_render_templates( page => $prior_err, source => 'saved', runtime_context => {} );
    ok( scalar( @{ $prior_err->{meta}{runtime_errors} } ) >= 2, '_render_templates appends to an existing runtime_errors list' );
}

# ---- prepare_page end to end (integrated code + template rendering) -----------
{
    my $prep = Developer::Dashboard::PageDocument->new( id => 'prep', state => { who => 'Team' }, layout => { body => 'Hi [% who %]' } );
    $prep->{meta}{codes} = [ { id => 'CODE1', body => 'print "code-ran";' } ];
    my $prepared = $runtime->prepare_page( page => $prep, source => 'saved', runtime_context => {} );
    like( $prepared->{layout}{body}, qr/Hi Team/, 'prepare_page renders template bodies after running code blocks' );
}

# ---- _system_context defaults --------------------------------------------------
is( $runtime->_system_context( runtime_context => {}, source => '' )->{cwd}, '.', '_system_context defaults cwd when the runtime context omits it' );

# ---- stream_code_block: defaults, sandpit reuse, no-paths, returns, die -------
{
    my $spage = Developer::Dashboard::PageDocument->new( id => 'stream-page' );

    my $out = '';
    my $r1 = $runtime->stream_code_block(
        code            => 'print "streamed";',
        page            => $spage,
        source          => 'saved',
        state           => {},
        runtime_context => {},
        stdout_writer   => sub { $out .= defined $_[0] ? $_[0] : ''; return 1 },
    );
    is( $out, 'streamed', 'stream_code_block forwards stdout chunks' );
    is( $r1->{error}, '', 'stream_code_block leaves the error empty on success' );

    # Bare call: undef code/state/context, fresh sandpit (L333/334/335 right).
    my $bare = $runtime->stream_code_block();
    is( $bare->{error}, '', 'stream_code_block runs with all arguments defaulted' );

    # Supplied sandpit -> destroy flag false, create skipped (L337 right, L384 false).
    my $sandpit = $runtime->_new_sandpit();
    my $reuse = $runtime->stream_code_block( code => '1;', sandpit => $sandpit, page => $spage );
    is( $reuse->{error}, '', 'stream_code_block reuses a supplied sandpit without destroying it' );
    $runtime->_destroy_sandpit($sandpit);

    # No-paths runtime with a non-ref page (L359 right, L358 B false).
    my $np = $runtime_no_paths->stream_code_block( code => '1;', page => 'plain' );
    is( $np->{error}, '', 'stream_code_block runs on a runtime without a path registry' );

    # Transient-url env match inside the streaming context.
    {
        local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = '1';
        my $tmatch = $runtime->stream_code_block( code => '1;', page => $spage );
        is( $tmatch->{error}, '', 'stream_code_block honours a matching transient-url env flag' );
    }

    # return_writer over hash / array / scalar returns (L379 all outcomes).
    my $written = '';
    $runtime->stream_code_block(
        code          => 'return ( { a => 1 }, [ 1, 2 ], "scalarret" );',
        page          => $spage,
        return_writer => sub { $written .= defined $_[0] ? $_[0] : ''; return 1 },
    );
    like( $written, qr/a => 1/, 'stream_code_block forwards hash returns through the return writer' );
    like( $written, qr/\[/,     'stream_code_block forwards array returns through the return writer' );

    # Code that dies populates the trailing error text (drives the error grep).
    my $errpage = Developer::Dashboard::PageDocument->new( id => 'stream-err' );
    my $errres  = $runtime->stream_code_block( code => 'die "streamdie\n";', page => $errpage );
    like( $errres->{error}, qr/streamdie/, 'stream_code_block returns trailing error text when the code dies' );

    # Non-matching transient env flag with an id-less page (L358 id right + env AtBf).
    {
        local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 'bogus';
        my $idless_stream = Developer::Dashboard::PageDocument->new;
        my $r = $runtime->stream_code_block( code => '1;', page => $idless_stream );
        is( $r->{error}, '', 'stream_code_block ignores a non-matching transient env flag and an id-less page' );
    }

    # Missing sandpit package -> die.
    eval { $runtime->stream_code_block( code => '1;', sandpit => {} ); 1 };
    like( $@, qr/Missing sandpit package/, 'stream_code_block dies when the supplied sandpit lacks a package' );
}

# ---- _drain_saved_ajax_ready_handle: argument guards + routing ---------------
{
    my ( $r, $w );
    pipe $r, $w or die "pipe: $!";
    my $sel = IO::Select->new($r);

    eval { $runtime->_drain_saved_ajax_ready_handle( select => $sel, stdout => $r ); 1 };
    like( $@, qr/Missing ready handle/, '_drain_saved_ajax_ready_handle dies without a ready handle' );

    eval { $runtime->_drain_saved_ajax_ready_handle( fh => $r, stdout => $r ); 1 };
    like( $@, qr/Missing select set/, '_drain_saved_ajax_ready_handle dies without a select set' );

    eval { $runtime->_drain_saved_ajax_ready_handle( fh => $r, select => $sel ); 1 };
    like( $@, qr/Missing stdout handle/, '_drain_saved_ajax_ready_handle dies without a stdout handle' );
    close $r;
    close $w;
}
{
    # bytes == 0 (EOF) with defaulted path + no-op writers (L548/551/552 right).
    my ( $r, $w );
    pipe $r, $w or die "pipe: $!";
    close $w;    # immediate EOF
    my $sel = IO::Select->new($r);
    is( $runtime->_drain_saved_ajax_ready_handle( fh => $r, select => $sel, stdout => $r ), 1, '_drain_saved_ajax_ready_handle closes an EOF handle and continues' );
}
{
    # stdout branch: ready fileno equals stdout fileno, writer returns undef (L571 false).
    my ( $r, $w );
    pipe $r, $w or die "pipe: $!";
    print {$w} 'stdout-chunk';
    close $w;
    my $sel = IO::Select->new($r);
    my $seen = '';
    is(
        $runtime->_drain_saved_ajax_ready_handle(
            fh            => $r,
            path          => 'p',
            select        => $sel,
            stdout        => $r,
            stdout_writer => sub { $seen .= defined $_[0] ? $_[0] : ''; return },
            stderr_writer => sub { die 'unexpected stderr writer' },
        ),
        1,
        '_drain_saved_ajax_ready_handle defaults an undef stdout-writer result to continue',
    );
    is( $seen, 'stdout-chunk', '_drain_saved_ajax_ready_handle routes matching filenos to the stdout writer' );
    close $r;
}
{
    # stderr branch: ready fileno differs from stdout fileno, writer returns undef (L574 false).
    my ( $r, $w );
    pipe $r, $w or die "pipe: $!";
    print {$w} 'stderr-chunk';
    close $w;
    my ( $sr, $sw );
    pipe $sr, $sw or die "pipe: $!";
    my $sel  = IO::Select->new($r);
    my $seen = '';
    is(
        $runtime->_drain_saved_ajax_ready_handle(
            fh            => $r,
            path          => 'p',
            select        => $sel,
            stdout        => $sr,
            stdout_writer => sub { die 'unexpected stdout writer' },
            stderr_writer => sub { $seen .= defined $_[0] ? $_[0] : ''; return },
        ),
        1,
        '_drain_saved_ajax_ready_handle defaults an undef stderr-writer result to continue',
    );
    is( $seen, 'stderr-chunk', '_drain_saved_ajax_ready_handle routes mismatched filenos to the stderr writer' );
    close $r;
    close $sr;
    close $sw;
}
{
    # stdout handle already closed -> stdout fileno undef -> stderr branch (L569 middle false).
    my ( $r, $w );
    pipe $r, $w or die "pipe: $!";
    print {$w} 'closed-stdout-chunk';
    close $w;
    my ( $sr, $sw );
    pipe $sr, $sw or die "pipe: $!";
    close $sr;
    close $sw;
    my $sel  = IO::Select->new($r);
    my $seen = '';
    $runtime->_drain_saved_ajax_ready_handle(
        fh            => $r,
        path          => 'p',
        select        => $sel,
        stdout        => $sr,
        stdout_writer => sub { die 'unexpected stdout writer' },
        stderr_writer => sub { $seen .= defined $_[0] ? $_[0] : ''; return 1 },
    );
    is( $seen, 'closed-stdout-chunk', '_drain_saved_ajax_ready_handle falls back to the stderr writer when the stdout handle is closed' );
    close $r;
}

# ---- _drain_saved_ajax_post_exit_handles (L511/512/514/516) ------------------
{
    eval { $runtime->_drain_saved_ajax_post_exit_handles(); 1 };
    like( $@, qr/Missing select set/, '_drain_saved_ajax_post_exit_handles dies without a select set' );

    # select without a handles() method (L512 false).
    is(
        $runtime->_drain_saved_ajax_post_exit_handles(
            select        => Local::NoHandlesObj->new,
            path          => 'p',
            stdout        => \*STDOUT,
            stdout_writer => sub { 1 },
            stderr_writer => sub { 1 },
        ),
        1,
        '_drain_saved_ajax_post_exit_handles returns true when the select cannot enumerate handles',
    );

    # handles() returns an undef handle (L514 leftmost false).
    is(
        $runtime->_drain_saved_ajax_post_exit_handles(
            select        => Local::PostExitSelect->new(undef),
            path          => 'p',
            stdout        => \*STDOUT,
            stdout_writer => sub { 1 },
            stderr_writer => sub { 1 },
        ),
        1,
        '_drain_saved_ajax_post_exit_handles skips undefined handles',
    );

    # A live handle drained to EOF (L514 both-true then fileno-undef, L516 not taken).
    my ( $r, $w );
    pipe $r, $w or die "pipe: $!";
    print {$w} 'post-exit-chunk';
    close $w;
    my $got = '';
    is(
        $runtime->_drain_saved_ajax_post_exit_handles(
            select        => Local::PostExitSelect->new($r),
            path          => 'p',
            stdout        => $r,
            stdout_writer => sub { $got .= defined $_[0] ? $_[0] : ''; return 1 },
            stderr_writer => sub { 1 },
        ),
        1,
        '_drain_saved_ajax_post_exit_handles drains a ready handle to EOF',
    );
    is( $got, 'post-exit-chunk', '_drain_saved_ajax_post_exit_handles forwards the drained chunk' );

    # A writer disconnect returns 0 mid-drain (L516 taken).
    my ( $r2, $w2 );
    pipe $r2, $w2 or die "pipe: $!";
    print {$w2} 'x';
    close $w2;
    is(
        $runtime->_drain_saved_ajax_post_exit_handles(
            select        => Local::PostExitSelect->new($r2),
            path          => 'p',
            stdout        => $r2,
            stdout_writer => sub { return 0 },
            stderr_writer => sub { 1 },
        ),
        0,
        '_drain_saved_ajax_post_exit_handles stops when a writer signals disconnect',
    );
    close $r2 if defined fileno($r2);
}

# ---- _saved_ajax_child_exited (L530) -----------------------------------------
{
    is_deeply( [ $runtime->_saved_ajax_child_exited(undef) ], [ 1, 0 ], '_saved_ajax_child_exited reports exit for an undefined pid' );
    is_deeply( [ $runtime->_saved_ajax_child_exited('abc') ], [ 1, 0 ], '_saved_ajax_child_exited reports exit for a non-numeric pid' );
    is_deeply( [ $runtime->_saved_ajax_child_exited(0) ],     [ 1, 0 ], '_saved_ajax_child_exited reports exit for a zero pid' );
    my @alive = $runtime->_saved_ajax_child_exited($$);
    is( $alive[0], 0, '_saved_ajax_child_exited reports a still-present pid as not exited' );
}

# ---- _close_saved_ajax_streams (L583 / L591) ---------------------------------
{
    is( $runtime->_close_saved_ajax_streams(undef), 1, '_close_saved_ajax_streams tolerates a missing select set' );
    is( $runtime->_close_saved_ajax_streams( Local::NoHandlesObj->new ), 1, '_close_saved_ajax_streams tolerates a select without a handles() method' );

    my ( $r, $w );
    pipe $r, $w or die "pipe: $!";
    my $sel = IO::Select->new($r);
    is( $runtime->_close_saved_ajax_streams( $sel, undef, $w ), 1, '_close_saved_ajax_streams closes tracked and extra handles' );
    ok( !defined fileno($r), '_close_saved_ajax_streams closes handles tracked by the select set' );
    ok( !defined fileno($w), '_close_saved_ajax_streams closes extra handles passed alongside the select set' );
}

# ---- _terminate_saved_ajax_process (L604 / L605 / live child) ----------------
{
    is( $runtime->_terminate_saved_ajax_process(0), 1, '_terminate_saved_ajax_process returns for a falsy pid' );

    my $dead = fork();
    die "fork failed: $!" if !defined $dead;
    if ( !$dead ) { POSIX::_exit(0); }
    waitpid( $dead, 0 );
    is( $runtime->_terminate_saved_ajax_process($dead), 1, '_terminate_saved_ajax_process returns for an already-reaped pid' );

    my ( $ready_r, $ready_w );
    pipe $ready_r, $ready_w or die "pipe: $!";
    my $live = fork();
    die "fork failed: $!" if !defined $live;
    if ( !$live ) {
        close $ready_r;
        $SIG{TERM} = 'IGNORE';
        syswrite $ready_w, "up";    # signal readiness only after ignoring TERM
        select undef, undef, undef, 30;
        POSIX::_exit(0);
    }
    close $ready_w;
    my $ready = '';
    sysread $ready_r, $ready, 2;    # block until the child has installed the TERM guard
    close $ready_r;
    is( $runtime->_terminate_saved_ajax_process($live), 1, '_terminate_saved_ajax_process escalates to SIGKILL for a TERM-ignoring child' );
    waitpid( $live, 0 );
    ok( !kill( 0, $live ), '_terminate_saved_ajax_process leaves the TERM-ignoring child dead' );
}

# ---- _looks_like_stream_disconnect_error (L621 / L622) -----------------------
{
    ok( $runtime->_looks_like_stream_disconnect_error(),      '_looks_like_stream_disconnect_error treats undef as disconnect-like' );
    ok( $runtime->_looks_like_stream_disconnect_error(''),    '_looks_like_stream_disconnect_error treats empty string as disconnect-like' );
    ok( $runtime->_looks_like_stream_disconnect_error("__DD_AJAX_STREAM_DISCONNECTED__\n"), '_looks_like_stream_disconnect_error recognizes the disconnect marker' );
    ok( $runtime->_looks_like_stream_disconnect_error("broken pipe\n"), '_looks_like_stream_disconnect_error recognizes broken-pipe text' );
    ok( !$runtime->_looks_like_stream_disconnect_error("some other failure\n"), '_looks_like_stream_disconnect_error rejects unrelated failures' );
}

# ---- _saved_ajax_command (L641 / L644+python / L645 / L648) -------------------
{
    eval { $runtime->_saved_ajax_command(); 1 };
    like( $@, qr/Missing saved ajax file path/, '_saved_ajax_command dies without a path' );

    {
        no warnings 'redefine';
        local *Developer::Dashboard::PageRuntime::command_in_path = sub { return $_[0] eq 'python3' ? '/usr/bin/python3' : undef };
        is( ( $runtime->_saved_ajax_command( path => 'a.py' ) )[0], '/usr/bin/python3', '_saved_ajax_command resolves python3 for .py files' );

        local *Developer::Dashboard::PageRuntime::command_in_path = sub { return $_[0] eq 'python' ? '/usr/bin/python' : undef };
        is( ( $runtime->_saved_ajax_command( path => 'b.py' ) )[0], '/usr/bin/python', '_saved_ajax_command falls back to python when python3 is absent' );

        local *Developer::Dashboard::PageRuntime::command_in_path = sub { return undef };
        is( ( $runtime->_saved_ajax_command( path => 'c.py' ) )[0], 'python3', '_saved_ajax_command falls back to the python3 literal when neither interpreter resolves' );
    }

    my $ghost = File::Spec->catfile( $home, 'no-such-dir', 'ghost.dat' );
    eval { $runtime->_saved_ajax_command( path => $ghost ); 1 };
    like( $@, qr/Unable to read saved ajax file/, '_saved_ajax_command dies when an extensionless file cannot be opened' );

    my $empty = write_file( File::Spec->catfile( $home, 'empty.dat' ), '' );
    is( ( $runtime->_saved_ajax_command( path => $empty ) )[0], $^X, '_saved_ajax_command defaults an empty extensionless file to the Perl bootstrap' );

    my $shebang = write_file( File::Spec->catfile( $home, 'sheb.dat' ), "#!/bin/sh\necho hi\n" );
    chmod 0700, $shebang or die $!;
    is_deeply( [ $runtime->_saved_ajax_command( path => $shebang ) ], [$shebang], '_saved_ajax_command executes a shebang file directly' );

    my $plain = write_file( File::Spec->catfile( $home, 'plain.dat' ), "just text\n" );
    is( ( $runtime->_saved_ajax_command( path => $plain ) )[0], $^X, '_saved_ajax_command bootstraps a non-shebang extensionless file through Perl' );
}

# ---- _saved_ajax_env (L658 / L668 / L688 + defaults) -------------------------
{
    my %e_nonhash = $runtime->_saved_ajax_env( path => 'p', params => 'not-a-hash' );
    like( $e_nonhash{DEVELOPER_DASHBOARD_AJAX_PARAMS}, qr/\A\{\}\s*\z/, '_saved_ajax_env coerces non-hash params to an empty hash' );

    my %e_paths = $runtime->_saved_ajax_env( path => 'p', page => 'pg', type => 'text', params => { a => 1 } );
    ok( length $e_paths{DEVELOPER_DASHBOARD_RUNTIME_ROOT}, '_saved_ajax_env exposes the runtime root when a path registry is present' );

    my %e_nopaths = $runtime_no_paths->_saved_ajax_env( path => 'p', params => {} );
    is( $e_nopaths{DEVELOPER_DASHBOARD_RUNTIME_ROOT},   '', '_saved_ajax_env leaves the runtime root empty without a path registry' );
    is( $e_nopaths{DEVELOPER_DASHBOARD_RUNTIME_LAYERS}, '', '_saved_ajax_env leaves the runtime layers empty without a path registry' );

    my %e_bare = $runtime->_saved_ajax_env( params => {} );
    is( $e_bare{DEVELOPER_DASHBOARD_AJAX_FILE}, '', '_saved_ajax_env defaults the ajax file path to empty' );
    is( $e_bare{DEVELOPER_DASHBOARD_AJAX_TYPE}, '', '_saved_ajax_env defaults the ajax type to empty' );
}

# ---- _runtime_local_perl_env (L701) ------------------------------------------
{
    is_deeply( [ $runtime_no_paths->_runtime_local_perl_env ], [], '_runtime_local_perl_env returns nothing without a path registry' );
    my %env = $runtime->_runtime_local_perl_env;
    ok( exists $env{PERL5LIB}, '_runtime_local_perl_env builds a PERL5LIB override when a path registry is present' );
}

# ---- _saved_ajax_temp_file (L725 / L727) -------------------------------------
{
    my $with = Developer::Dashboard::PageRuntime::_saved_ajax_temp_file( prefix => 'cov-prefix-', suffix => '.txt', content => 'payload' );
    ok( -e $with, '_saved_ajax_temp_file writes a file with an explicit prefix, suffix, and content' );
    unlink $with;

    my $bare = Developer::Dashboard::PageRuntime::_saved_ajax_temp_file();
    ok( -e $bare, '_saved_ajax_temp_file writes a file with defaulted prefix, suffix, and content' );
    is( -s $bare, 0, '_saved_ajax_temp_file writes empty content when none is supplied' );
    unlink $bare;
}

# ---- _cleanup_saved_ajax_temp_files (L739 / L740 / L741) ---------------------
{
    my ( $fh, $real ) = tempfile();
    close $fh;
    $runtime->_cleanup_saved_ajax_temp_files($real);
    ok( !-e $real, '_cleanup_saved_ajax_temp_files removes a real temp file' );

    my $dir = File::Spec->catdir( $home, 'cleanup-dir' );
    make_path($dir);
    eval {
        $runtime->_cleanup_saved_ajax_temp_files( undef, '', File::Spec->catfile( $home, 'never-existed' ), $dir );
        1;
    };
    like( $@, qr/Unable to remove saved ajax temp file/, '_cleanup_saved_ajax_temp_files skips undef/empty/missing paths and dies when unlink fails' );
    rmdir $dir;
}

# ---- _kill_saved_ajax_singleton (L763) ---------------------------------------
{
    is( $runtime->_kill_saved_ajax_singleton(undef), 1, '_kill_saved_ajax_singleton ignores an undefined singleton' );
    is( $runtime->_kill_saved_ajax_singleton(''),    1, '_kill_saved_ajax_singleton ignores an empty singleton' );
    my @patterns;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { push @patterns, $_[1]; return 1 };
        is( $runtime->_kill_saved_ajax_singleton('mysingle'), 1, '_kill_saved_ajax_singleton terminates matching workers for a real singleton' );
    }
    is_deeply( \@patterns, ['^dashboard ajax: mysingle$'], '_kill_saved_ajax_singleton builds an anchored process pattern' );
}

# ---- _query_string_from_params (L785 / L789) ---------------------------------
{
    is( Developer::Dashboard::PageRuntime::_query_string_from_params('nope'), '', '_query_string_from_params ignores non-hash params' );
    is( Developer::Dashboard::PageRuntime::_query_string_from_params( {} ),   '', '_query_string_from_params ignores empty params' );
    my $qs = Developer::Dashboard::PageRuntime::_query_string_from_params( { a => '1', b => undef } );
    like( $qs, qr/a=1/, '_query_string_from_params encodes defined values' );
    like( $qs, qr/b=/,  '_query_string_from_params encodes undef values as empty' );
}

# ---- _run_saved_ajax_perl_file (L881 / L885) ---------------------------------
{
    eval { Developer::Dashboard::PageRuntime->_run_saved_ajax_perl_file(undef); 1 };
    like( $@, qr/Missing saved ajax Perl file path/, '_run_saved_ajax_perl_file dies without a path' );
    eval { Developer::Dashboard::PageRuntime->_run_saved_ajax_perl_file(''); 1 };
    like( $@, qr/Missing saved ajax Perl file path/, '_run_saved_ajax_perl_file dies for an empty path' );

    my $die_file = write_file( File::Spec->catfile( $home, 'wrapper-die.pl' ), 'die "kaboom\n";' );
    my $err = eval {
        capture { Developer::Dashboard::PageRuntime->_run_saved_ajax_perl_file($die_file) };
        1;
    } ? '' : $@;
    like( $err, qr/kaboom/, '_run_saved_ajax_perl_file surfaces errors raised by the wrapped file' );

    my $ok_file = write_file( File::Spec->catfile( $home, 'wrapper-ok.pl' ), 'print "hi";' );
    my ( undef, undef, $rv ) = capture { return Developer::Dashboard::PageRuntime->_run_saved_ajax_perl_file($ok_file); };
    is( $rv, 1, '_run_saved_ajax_perl_file returns true after evaluating a clean wrapped file' );
}

# ---- _code_header (L895) ------------------------------------------------------
{
    is( $runtime->_code_header(undef), '', '_code_header returns empty for an undefined stash' );
    is( $runtime->_code_header( {} ),  '', '_code_header returns empty for a stash without usable keys' );
    like( $runtime->_code_header( { name => 1 } ), qr/\$name/, '_code_header emits lexical bindings for stash keys' );
}

# ---- _new_sandpit / _destroy_sandpit (L988 false / L1004) --------------------
{
    my $sandpit = $runtime->_new_sandpit( state => { a => 1 }, runtime_context => {} );
    ok( $sandpit->{package}, '_new_sandpit compiles a throwaway package' );

    ok( !defined $runtime->_destroy_sandpit('not-a-hash'), '_destroy_sandpit ignores non-hash inputs' );
    ok( !defined $runtime->_destroy_sandpit( {} ),         '_destroy_sandpit ignores a hash without a package' );
    is( $runtime->_destroy_sandpit($sandpit), undef, '_destroy_sandpit clears a real sandpit package' );
}

# ---- stream_saved_ajax_file: die guard, success, disconnect-like writer ------
{
    eval { $runtime->stream_saved_ajax_file(); 1 };
    like( $@, qr/Missing saved ajax file path/, 'stream_saved_ajax_file dies without a path' );

    my $ok_file = write_file( File::Spec->catfile( $ajax_dir, 'stream-ok.pl' ), qq{print "stdout-line\\n"; warn "stderr-line\\n";} );
    my $collected = '';
    my $res = $runtime->stream_saved_ajax_file(
        path          => $ok_file,
        page          => 'pg',
        type          => 'text',
        params        => { a => 1, file => 'stream-ok.pl', type => 'text' },
        stdout_writer => sub { $collected .= defined $_[0] ? $_[0] : ''; return 1 },
        stderr_writer => sub { $collected .= defined $_[0] ? $_[0] : ''; return 1 },
    );
    like( $collected, qr/stdout-line/, 'stream_saved_ajax_file forwards worker stdout' );
    like( $collected, qr/stderr-line/, 'stream_saved_ajax_file forwards worker stderr' );
    is( $res->{exit_code}, 0, 'stream_saved_ajax_file reports a clean exit code for a successful worker' );

    # path only: params, writers, page, and type all defaulted (L400/401/402/409 right).
    my $bare_res = $runtime->stream_saved_ajax_file( path => $ok_file );
    is( $bare_res->{exit_code}, 0, 'stream_saved_ajax_file runs with defaulted params, writers, page, and type' );

    # writer failure that is not disconnect-like surfaces a fatal error (L483 true).
    my $we_file = write_file(
        File::Spec->catfile( $ajax_dir, 'stream-writer-explode.pl' ),
        qq{\$SIG{TERM} = sub { exit 0 };\nlocal \$| = 1;\nprint "first\\n";\nsleep 5;\n},
    );
    my $we_error = eval {
        $runtime->stream_saved_ajax_file(
            path          => $we_file,
            page          => 'pg',
            type          => 'text',
            params        => { file => 'stream-writer-explode.pl', type => 'text' },
            stdout_writer => sub { die "writer exploded\n" },
            stderr_writer => sub { return 1 },
        );
        1;
    } ? '' : $@;
    like( $we_error, qr/writer exploded/, 'stream_saved_ajax_file surfaces a non-disconnect writer failure' );

    my $bp_file = write_file(
        File::Spec->catfile( $ajax_dir, 'stream-brokenpipe.pl' ),
        qq{\$SIG{TERM} = sub { exit 0 };\nlocal \$| = 1;\nprint "first-line\\n";\nsleep 5;\n},
    );
    my $bp_error = eval {
        $runtime->stream_saved_ajax_file(
            path          => $bp_file,
            page          => 'pg',
            type          => 'text',
            params        => { file => 'stream-brokenpipe.pl', type => 'text' },
            stdout_writer => sub { die "broken pipe\n" },
            stderr_writer => sub { return 1 },
        );
        1;
    } ? '' : $@;
    is( $bp_error, '', 'stream_saved_ajax_file treats a broken-pipe writer failure as a handled disconnect' );
}

done_testing;

__END__

=head1 NAME

t/99-pageruntime-coverage.t - branch and condition coverage closure for the older page runtime

=head1 PURPOSE

This test is the executable coverage contract for
C<Developer::Dashboard::PageRuntime>, the older bookmark renderer and CODE
executor. It drives every conditional edge of the module - argument guards,
sandpit lifecycle, Template Toolkit helper validation, saved-Ajax command
resolution, environment assembly, stream draining, worker termination, and temp
file cleanup - so that all four Devel::Cover metrics, including branch and
condition, stay at 100 percent for that module.

=head1 WHY IT EXISTS

It exists because the page runtime concentrates a large amount of
process-lifecycle and rendering logic behind small defensive conditionals that
higher-level browser and CLI flows only exercise on their happy paths. Without a
dedicated test the missing sides of those branches silently erode coverage and
hide real regressions in stdout/stderr routing, disconnect handling, and skill
runtime resolution. Keeping the edges in one file makes the coverage gate
concrete and the failure modes reviewable.

=head1 WHEN TO USE

Use this file when changing bookmark code-block execution, Template Toolkit
exposure, saved-Ajax subprocess launching or streaming, singleton handling, or
any of the private helpers those flows rely on. Extend it whenever a new
conditional edge is added to the page runtime.

=head1 HOW TO USE

Run it directly with C<prove -lv t/99-pageruntime-coverage.t> while iterating,
then keep it green under C<prove -lr t> and under the Devel::Cover gate before
release. The test is hermetic: it roots a throwaway home, changes into it so the
deepest runtime layer resolves from the working directory, and builds every
object through the public constructors.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the branch and
condition coverage gates all rely on this file to keep the page runtime's
conditional behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/99-pageruntime-coverage.t

Run the focused page-runtime coverage test by itself while iterating.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/99-pageruntime-coverage.t

Exercise the same test while collecting coverage for the page runtime.

Example 3:

  prove -lr t

Put the change back through the entire repository suite before release.

=cut
