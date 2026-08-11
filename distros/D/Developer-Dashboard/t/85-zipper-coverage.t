#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Capture::Tiny qw(capture);

use lib 'lib';

use Developer::Dashboard::Zipper;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillDispatcher;

# Warnings are fatal in this repository; fail loudly on any unexpected warning.
$SIG{__WARN__} = sub { die "unexpected warning: $_[0]" };

# Hermetic runtime: a throwaway HOME with the process cwd inside it so the
# DD-OOP layer stack resolves entirely under the temp directory.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

# Convenience: run one Ajax() invocation, capturing its printed script output
# and any die so the caller can assert on both without leaking to the harness.
sub ajax_run {
    my (@args) = @_;
    my $err;
    my ($out) = capture { eval { Developer::Dashboard::Zipper::Ajax(@args); 1 } or $err = $@; };
    return ( $out, $err );
}

# ---------------------------------------------------------------------------
# zip(): early return on undef/empty, real encode on a defined non-empty value.
# ---------------------------------------------------------------------------
is( zip(undef), undef, 'zip returns undef for an undefined payload' );
is( zip(''),    undef, 'zip returns undef for an empty payload' );
my $zipped = zip('hello world');
ok( ref($zipped) eq 'HASH' && $zipped->{raw} ne '' && $zipped->{url} ne '', 'zip encodes a non-empty payload into raw and url tokens' );

# ---------------------------------------------------------------------------
# unzip(): early return on undef/empty, round-trip decode of a real token.
# ---------------------------------------------------------------------------
is( unzip(undef), undef, 'unzip returns undef for an undefined token' );
is( unzip(''),    undef, 'unzip returns undef for an empty token' );
is( unzip( $zipped->{raw} ), 'hello world', 'unzip round-trips an encoded payload back to text' );

# ---------------------------------------------------------------------------
# acmdx(): defaults vs supplied values, base prefix, singleton, app override.
# ---------------------------------------------------------------------------
my $ac_full = acmdx(
    type     => 'perl',
    code     => 'print 1;',
    base_url => 'https://host',
    target   => '_self',
    label    => 'Go',
    app      => 'https://app/here',
    singleton => 'one',
);
like( $ac_full->{url}{tokenised}, qr{^https://host/ajax\?token=}, 'acmdx prefixes the tokenised url with a supplied base_url' );
like( $ac_full->{url}{tokenised}, qr{&singleton=one}, 'acmdx appends a non-empty singleton to the query' );
is( $ac_full->{url}{app}, 'https://app/here', 'acmdx honours an explicit app url override' );
like( $ac_full->{html}, qr{target="_self"}, 'acmdx uses the supplied link target' );
like( $ac_full->{html}, qr{>Go<},           'acmdx uses the supplied link label' );

my $ac_bare = acmdx();
like( $ac_bare->{url}{tokenised}, qr{^/ajax\?token=&type=text$}, 'acmdx falls back to /ajax, empty token, and text type with no arguments' );
is( $ac_bare->{url}{app}, $ac_bare->{url}{tokenised}, 'acmdx defaults the app url to the tokenised url' );
like( $ac_bare->{html}, qr{target="_blank"},    'acmdx defaults the link target to _blank' );
like( $ac_bare->{html}, qr{>Click Here<},       'acmdx defaults the link label to Click Here' );

my $ac_empty_singleton = acmdx( code => 'x', singleton => '' );
unlike( $ac_empty_singleton->{url}{tokenised}, qr{singleton=}, 'acmdx omits an empty singleton from the query' );

# ---------------------------------------------------------------------------
# saved_ajax_file_path(): runtime_root required vs supplied.
# ---------------------------------------------------------------------------
my $rt = File::Spec->catdir( $home, 'runtime-a' );
my $store_path = Developer::Dashboard::Zipper::saved_ajax_file_path( runtime_root => $rt, file => 'good' );
is( $store_path, File::Spec->catfile( $rt, 'dashboards', 'ajax', 'good' ), 'saved_ajax_file_path builds the dashboards ajax-tree path' );
my $rt_err = eval { Developer::Dashboard::Zipper::saved_ajax_file_path( file => 'good' ); 1 } ? '' : $@;
like( $rt_err, qr/runtime_root is required/, 'saved_ajax_file_path dies without a runtime_root' );

# ---------------------------------------------------------------------------
# _saved_ajax_url_and_store(): success, undef code, open failure, chmod failure.
# ---------------------------------------------------------------------------
my $stored = Developer::Dashboard::Zipper::_saved_ajax_url_and_store(
    runtime_root => $rt,
    file         => 'good',
    code         => 'print "saved";',
    type         => 'text',
);
ok( -f $stored->{path}, '_saved_ajax_url_and_store writes the handler file' );

my $stored_undef = Developer::Dashboard::Zipper::_saved_ajax_url_and_store(
    runtime_root => $rt,
    file         => 'undefcode',
    code         => undef,
    type         => 'text',
);
ok( -f $stored_undef->{path}, '_saved_ajax_url_and_store writes an empty file when code is undef' );

# open('>') failure: the target already exists as a directory.
my $rt_dir = File::Spec->catdir( $home, 'runtime-dir' );
make_path( File::Spec->catdir( $rt_dir, 'dashboards', 'ajax', 'blocked' ) );
my $open_err = eval {
    Developer::Dashboard::Zipper::_saved_ajax_url_and_store(
        runtime_root => $rt_dir,
        file         => 'blocked',
        code         => 'x',
        type         => 'text',
    );
    1;
} ? '' : $@;
like( $open_err, qr/Unable to write/, '_saved_ajax_url_and_store dies when the handler file cannot be opened for writing' );

# chmod failure: a symlink to a root-owned world-writable device we cannot chmod.
my $rt_chmod = File::Spec->catdir( $home, 'runtime-chmod' );
make_path( File::Spec->catdir( $rt_chmod, 'dashboards', 'ajax' ) );
my $chmod_link = File::Spec->catfile( $rt_chmod, 'dashboards', 'ajax', 'chmodfail' );
symlink( File::Spec->devnull, $chmod_link ) or die "Unable to symlink devnull: $!";
my $chmod_err = eval {
    Developer::Dashboard::Zipper::_saved_ajax_url_and_store(
        runtime_root => $rt_chmod,
        file         => 'chmodfail',
        code         => 'x',
        type         => 'text',
    );
    1;
} ? '' : $@;
like( $chmod_err, qr/Unable to chmod/, '_saved_ajax_url_and_store dies when the handler file cannot be chmod-ed' );

# ---------------------------------------------------------------------------
# load_saved_ajax_code(): missing file, readable file, unreadable file.
# ---------------------------------------------------------------------------
is(
    Developer::Dashboard::Zipper::load_saved_ajax_code( runtime_root => $rt, file => 'missing' ),
    undef,
    'load_saved_ajax_code returns undef for a missing handler file',
);
is(
    Developer::Dashboard::Zipper::load_saved_ajax_code( runtime_root => $rt, file => 'good' ),
    'print "saved";',
    'load_saved_ajax_code reads back stored handler code',
);
my $unreadable = File::Spec->catfile( $rt, 'dashboards', 'ajax', 'unreadable' );
open my $ufh, '>', $unreadable or die "Unable to seed $unreadable: $!";
print {$ufh} "secret";
close $ufh;
chmod 0000, $unreadable or die "Unable to chmod $unreadable: $!";
my $read_err = eval {
    Developer::Dashboard::Zipper::load_saved_ajax_code( runtime_root => $rt, file => 'unreadable' );
    1;
} ? '' : $@;
like( $read_err, qr/Unable to read/, 'load_saved_ajax_code dies when the handler file exists but cannot be read' );
chmod 0600, $unreadable;

# ---------------------------------------------------------------------------
# _saved_skill_ajax_route_spec(): non-hash context, unblessed paths, real route.
# ---------------------------------------------------------------------------
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = undef;
    is(
        Developer::Dashboard::Zipper::_saved_skill_ajax_route_spec( skill_name => 'x', file => 'y' ),
        undef,
        '_saved_skill_ajax_route_spec returns undef when the ajax context is not a hash',
    );
}
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {};
    is(
        Developer::Dashboard::Zipper::_saved_skill_ajax_route_spec( skill_name => 'x', file => 'y' ),
        undef,
        '_saved_skill_ajax_route_spec returns undef when the context has no blessed paths',
    );
}

# Install a skill with a custom ajax route so a real route spec resolves.
my $skill_config = File::Spec->catdir( $home, '.developer-dashboard', 'skills', 'myskill', 'config' );
make_path($skill_config);
open my $rfh, '>', File::Spec->catfile( $skill_config, 'routes.json' ) or die $!;
print {$rfh} '{ "version": 1, "ajax": { "myhandler": { "path": "/v1/my/handler" } } }';
close $rfh;

my $dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $paths );
my $fixture_spec = $dispatcher->skill_ajax_route_spec( 'myskill', 'myhandler' );
ok( $fixture_spec && $fixture_spec->{path} eq '/v1/my/handler', 'skill ajax route fixture resolves a defined custom route' );

{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = { paths => $paths };
    my $route = Developer::Dashboard::Zipper::_saved_skill_ajax_route_spec( skill_name => 'myskill', file => 'myhandler' );
    ok( $route && $route->{path} eq '/v1/my/handler', '_saved_skill_ajax_route_spec resolves a real skill ajax route with blessed paths' );

    # file falls back to '' when absent while paths are still blessed.
    is(
        Developer::Dashboard::Zipper::_saved_skill_ajax_route_spec( skill_name => 'myskill' ),
        undef,
        '_saved_skill_ajax_route_spec resolves undef for a blank ajax file target',
    );
}

# ---------------------------------------------------------------------------
# _saved_ajax_url(): defined route, skill-namespaced route, plain route,
# singleton variants, and base_url prefixing.
# ---------------------------------------------------------------------------
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = { paths => $paths };
    my $ru = Developer::Dashboard::Zipper::_saved_ajax_url(
        file       => 'myhandler',
        skill_name => 'myskill',
        type       => 'text',
        base_url   => 'https://h',
        singleton  => 'sg',
    );
    is( $ru->{url}, 'https://h/v1/my/handler?singleton=sg', '_saved_ajax_url uses a defined route path and appends a singleton without an existing query' );
}
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {};
    my $ru = Developer::Dashboard::Zipper::_saved_ajax_url(
        file       => 'plain',
        skill_name => 'noskill',
        type       => 'text',
    );
    is( $ru->{url}, '/ajax/noskill/plain?type=text', '_saved_ajax_url builds a skill-namespaced route when no custom route exists' );
}
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {};
    my $ru = Developer::Dashboard::Zipper::_saved_ajax_url(
        file      => 'plain2',
        singleton => 'sg2',
    );
    is( $ru->{url}, '/ajax/plain2?type=text&singleton=sg2', '_saved_ajax_url builds a bare route and appends a singleton onto an existing query' );

    my $ru_empty = Developer::Dashboard::Zipper::_saved_ajax_url( file => 'plain3', singleton => '' );
    is( $ru_empty->{url}, '/ajax/plain3?type=text', '_saved_ajax_url omits an empty singleton' );
}

# ---------------------------------------------------------------------------
# _url_path_escape(): undef, empty, and a multi-segment path.
# ---------------------------------------------------------------------------
is( Developer::Dashboard::Zipper::_url_path_escape(undef), '', '_url_path_escape returns empty for undef' );
is( Developer::Dashboard::Zipper::_url_path_escape(''),    '', '_url_path_escape returns empty for an empty string' );
is( Developer::Dashboard::Zipper::_url_path_escape('seg/me nt'), 'seg/me%20nt', '_url_path_escape escapes each segment independently' );

# ---------------------------------------------------------------------------
# _validate_saved_ajax_file(): every rejection branch plus the accepted value.
# ---------------------------------------------------------------------------
for my $case (
    [ undef,        qr/file is required/,                'undef file' ],
    [ '',           qr/file is required/,                'empty file' ],
    [ '/abs/path',  qr/file must be relative/,           'absolute file' ],
    [ '../escape',  qr/invalid parent traversal/,        'parent traversal' ],
    [ 'bad!char',   qr/invalid characters/,              'invalid characters' ],
) {
    my ( $value, $pattern, $label ) = @{$case};
    my $err = eval { Developer::Dashboard::Zipper::_validate_saved_ajax_file($value); 1 } ? '' : $@;
    like( $err, $pattern, "_validate_saved_ajax_file rejects a $label" );
}
is( Developer::Dashboard::Zipper::_validate_saved_ajax_file('ok_file.tt'), 'ok_file.tt', '_validate_saved_ajax_file accepts a valid relative file' );

# ---------------------------------------------------------------------------
# _js_single_quote(): undef fallback and escaping of backslashes and quotes.
# ---------------------------------------------------------------------------
is( Developer::Dashboard::Zipper::_js_single_quote(undef), '', '_js_single_quote treats undef as an empty string' );
is( Developer::Dashboard::Zipper::_js_single_quote(q{a'b\\c}), q{a\\'b\\\\c}, '_js_single_quote escapes single quotes and backslashes' );

# ---------------------------------------------------------------------------
# __cmdx / _cmdx / _cmdp: encode pipeline, perl vs non-perl switch selection.
# ---------------------------------------------------------------------------
like( Developer::Dashboard::Zipper::__cmdx( 'perl', 'code' ), qr/base64 -d \| gunzip/, '__cmdx builds a decode pipeline for a real payload' );
like( Developer::Dashboard::Zipper::__cmdx( 'perl', '' ), qr/base64 -d \| gunzip/, '__cmdx tolerates an empty payload via the fallback token' );
is( ( _cmdx( 'perl', 'code' ) )[1], '-e', '_cmdx selects the -e switch for perl payloads' );
is( ( _cmdx( 'bash', 'code' ) )[1], '-c', '_cmdx selects the -c switch for non-perl payloads' );
my @cmdp = _cmdp( 'text', 'code' );
is( $cmdp[1], 'text', '_cmdp returns the payload type as its trailing tuple value' );

# ---------------------------------------------------------------------------
# Ajax(): jvar guard, non-hash context, saved-bookmark storage paths, the
# transient-token guard, and the plain tokenised fall-through.
# ---------------------------------------------------------------------------

# jvar is mandatory.
{
    my ( undef, $err ) = ajax_run();
    like( $err, qr/jvar is required/, 'Ajax dies without a jvar' );
}

# Non-hash AJAX_CONTEXT collapses to an empty context and takes the plain path.
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = undef;
    my ( $out, $err ) = ajax_run( jvar => 'root', code => 'x' );
    is( $err, undef, 'Ajax tolerates a non-hash ajax context' );
    like( $out, qr/set_chain_value/, 'Ajax emits a chain-value script for the plain tokenised path' );
}

# Saved-bookmark path, code present -> _saved_ajax_url_and_store, singleton set.
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {
        source       => 'saved',
        page_id      => 'p1',
        runtime_root => $rt,
        skill_name   => 'mysk',
    };
    my ( $out, $err ) = ajax_run(
        jvar      => 'root.path',
        file      => 'h1',
        code      => 'print 1;',
        type      => 'text',
        base_url  => 'https://b',
        singleton => 'sg',
    );
    is( $err, undef, 'Ajax stores a saved-bookmark handler with code and a singleton' );
    like( $out, qr/dashboard_ajax_singleton_cleanup\('sg'\)/, 'Ajax emits singleton cleanup for a saved bookmark with a singleton' );
}

# Saved-bookmark path, skill source, code present, no singleton, dotless jvar.
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {
        source       => 'skill',
        page_id      => 'p1',
        runtime_root => $rt,
        skill_name   => '',
    };
    my ( $out, $err ) = ajax_run(
        jvar => 'root',
        file => 'h5',
        code => 'print 2;',
        type => 'text',
    );
    is( $err, undef, 'Ajax stores a saved-bookmark handler for a skill-sourced page' );
    unlike( $out, qr/singleton_cleanup/, 'Ajax skips singleton cleanup when no singleton is supplied' );
}

# Saved-bookmark path, code present, empty singleton (defined but blank).
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {
        source       => 'saved',
        page_id      => 'p1',
        runtime_root => $rt,
        skill_name   => '',
    };
    my ( undef, $err ) = ajax_run(
        jvar      => 'root',
        file      => 'h7',
        code      => 'print 3;',
        type      => 'text',
        singleton => '',
    );
    is( $err, undef, 'Ajax stores a saved-bookmark handler with an empty singleton' );
}

# Saved-bookmark path, no code -> _saved_ajax_url, skill_name + base_url present.
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {
        source     => 'saved',
        page_id    => 'p1',
        skill_name => 'mysk2',
    };
    my ( $out, $err ) = ajax_run(
        jvar      => 'root.path',
        file      => 'h3',
        type      => 'text',
        base_url  => 'https://c',
        singleton => 'sg3',
    );
    is( $err, undef, 'Ajax builds a stable saved-bookmark url without code' );
    like( $out, qr{https://c/ajax/mysk2/h3}, 'Ajax uses the skill-namespaced saved url with a base prefix' );
}

# Saved-bookmark path, no code, no skill_name, no base_url.
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {
        source     => 'saved',
        page_id    => 'p1',
        skill_name => '',
    };
    my ( undef, $err ) = ajax_run( jvar => 'root', file => 'h4', type => 'text' );
    is( $err, undef, 'Ajax builds a bare saved-bookmark url without a skill name or base url' );
}

# Saved-bookmark path, code present, empty runtime_root and base_url -> the
# store attempt dies inside saved_ajax_file_path while the arg defaults evaluate.
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {
        source       => 'saved',
        page_id      => 'p1',
        runtime_root => '',
        skill_name   => '',
    };
    my ( undef, $err ) = ajax_run(
        jvar     => 'root',
        file     => 'h2',
        code     => 'print 4;',
        type     => 'text',
        base_url => '',
    );
    like( $err, qr/runtime_root is required/, 'Ajax surfaces the store failure when the context runtime_root is blank' );
}

# Saved-bookmark path, blank file, transient tokens disabled -> hard failure.
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {
        source              => 'saved',
        page_id             => 'p1',
        allow_transient_urls => 0,
    };
    my ( undef, $err ) = ajax_run( jvar => 'root', type => 'text' );
    like( $err, qr/file is required for saved bookmark Ajax/, 'Ajax rejects a fileless saved bookmark when transient tokens are disabled' );
}

# Saved-bookmark path, blank file, transient tokens allowed -> falls through to
# the plain tokenised path with a dotted jvar.
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {
        source              => 'saved',
        page_id             => 'p1',
        allow_transient_urls => 1,
    };
    my ( $out, $err ) = ajax_run( jvar => 'root.path', code => 'x', type => 'text' );
    is( $err, undef, 'Ajax falls through to the tokenised path for a fileless bookmark when transient tokens are allowed' );
    like( $out, qr/set_chain_value/, 'Ajax emits the tokenised chain-value script on transient fall-through' );
}

# Saved source but a blank page_id skips the saved block entirely.
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {
        source  => 'saved',
        page_id => '',
    };
    my ( $out, $err ) = ajax_run( jvar => 'root', code => 'x' );
    is( $err, undef, 'Ajax skips the saved block when the page id is blank' );
    like( $out, qr/set_chain_value/, 'Ajax uses the plain tokenised path when the saved block is skipped for a blank page id' );
}

# A non-saved, non-skill source skips the saved block via the outer condition.
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {
        source  => 'other',
        page_id => 'p1',
    };
    my ( $out, $err ) = ajax_run( jvar => 'root.path', code => 'x' );
    is( $err, undef, 'Ajax skips the saved block for an unrelated source' );
    like( $out, qr/set_chain_value/, 'Ajax uses the plain tokenised path for an unrelated source' );
}

done_testing;

__END__

=pod

=head1 NAME

t/85-zipper-coverage.t - branch and condition coverage for the older Zipper helper surface

=head1 PURPOSE

This test is the executable coverage contract for
C<Developer::Dashboard::Zipper>. It drives every reachable branch and condition
in the older token, saved Ajax URL, saved-handler storage, and compatibility
helper functions so the release coverage gate can hold the module at 100 percent
on branch and condition metrics without weakening the standard.

=head1 WHY IT EXISTS

The Zipper module keeps the historical bookmark and Ajax helper API alive, and
several of its paths - the transient-token guard, the saved-handler storage
failure modes, the skill-namespaced route resolution, and the defensive default
fallbacks - are hard to reach from the higher level web and CLI flows. Collecting
their fixtures in one focused file keeps those paths measured and stops the
coverage gate from silently regressing when the helper surface changes.

=head1 WHEN TO USE

Use this file when changing token encoding, saved Ajax file validation or
storage, the skill-aware saved Ajax URL builder, the transient-token policy, or
any of the older shell/link compatibility wrappers in the Zipper module.

=head1 HOW TO USE

Run C<prove -lv t/85-zipper-coverage.t> while iterating on the helper surface,
then confirm branch and condition coverage with
C<HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t> and keep it green under the
full C<prove -lr t> suite before release.

=head1 WHAT USES IT

Developers during TDD, the full repository test suite, and the release coverage
gate rely on this file to keep the older Zipper helper behavior and its
error-handling branches exercised end to end.

=head1 EXAMPLES

Example 1:

  prove -lv t/85-zipper-coverage.t

Run the focused Zipper coverage test by itself while changing the helper surface.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/85-zipper-coverage.t

Exercise the same test while collecting branch and condition coverage for the
module.

Example 3:

  prove -lr t

Put the change back through the whole repository suite before calling it done.

=cut
