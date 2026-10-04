#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Cwd qw(abs_path getcwd);

use lib 'lib';

use Developer::Dashboard::SkillDispatcher;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillManager;
use Developer::Dashboard::PageDocument;

sub write_file {
    my ( $path, $content ) = @_;
    my $dir = ( File::Spec->splitpath($path) )[1];
    make_path($dir) if !-d $dir;
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} $content;
    close $fh;
    return $path;
}

my $orig_cwd = getcwd();
my $tmp      = abs_path( tempdir( CLEANUP => 1 ) );
chdir $tmp or die $!;
local $ENV{HOME} = $tmp;

my $skill = File::Spec->catdir( $tmp, '.developer-dashboard', 'skills', 'mk' );
write_file( File::Spec->catfile( $skill, 'cli', 'go' ), "#!/bin/sh\necho go\n" );
chmod 0755, File::Spec->catfile( $skill, 'cli', 'go' );
write_file( File::Spec->catfile( $skill, 'cli', 'go.d', '01-h' ), "#!/bin/sh\necho hook\n" );
chmod 0755, File::Spec->catfile( $skill, 'cli', 'go.d', '01-h' );

my $paths      = Developer::Dashboard::PathRegistry->new( home => $tmp );
my $manager    = Developer::Dashboard::SkillManager->new( paths => $paths );
my $dispatcher = Developer::Dashboard::SkillDispatcher->new( manager => $manager );

# A command spec that lacks env_skill_layers must fall back to the skill layers.
{
    no warnings 'redefine';
    my $orig = \&Developer::Dashboard::SkillDispatcher::_command_spec;
    local *Developer::Dashboard::SkillDispatcher::_command_spec = sub {
        my $spec = $orig->(@_);
        delete $spec->{env_skill_layers} if $spec;
        return $spec;
    };

    my $run = $dispatcher->dispatch( 'mk', 'go' );
    like( $run->{stdout}, qr/go/, 'dispatch falls back to skill_layers when the spec has no env_skill_layers' );

    my $hooks = $dispatcher->execute_hooks( 'mk', 'go' );
    ok( exists $hooks->{hooks}, 'execute_hooks falls back to skill_layers when the spec has no env_skill_layers' );

    local *Developer::Dashboard::SkillDispatcher::_exec_resolved_command = sub { return { handed_off => 1 } };
    open my $save_out, '>&', \*STDOUT or die $!;
    open STDOUT, '>', File::Spec->devnull or die $!;
    my $exec = $dispatcher->exec_command( 'mk', 'go' );
    open STDOUT, '>&', $save_out or die $!;
    is( $exec->{handed_off}, 1, 'exec_command falls back to skill_layers when the spec has no env_skill_layers' );
}

# _execute_hooks_streaming with a first argument that is not an options hash.
{
    my $result = $dispatcher->_execute_hooks_streaming( 'mk', 'go', [$skill], 'plain-arg' );
    ok( ref $result->{hooks} eq 'HASH', '_execute_hooks_streaming treats a non-hash first argument as a plain argument' );
    $result = $dispatcher->_execute_hooks_streaming( 'mk', 'go', [$skill], {}, 'arg' );
    ok( ref $result->{hooks} eq 'HASH', '_execute_hooks_streaming keeps an options hash that lacks env_skill_layers as a plain argument' );
}

# _skill_env with the skill path equal to the home: the shared perl5 lib is
# already seen through the layer walk, so it is not added twice.
{
    make_path( File::Spec->catdir( $tmp, 'perl5', 'lib', 'perl5' ) );
    my %env = $dispatcher->_skill_env(
        skill_name   => 'mk',
        skill_path   => $tmp,
        skill_layers => [ undef, '', $skill ],
        command      => 'go',
    );
    ok( exists $env{DEVELOPER_DASHBOARD_SKILL_ROOT}, '_skill_env skips undefined and empty layers and dedupes the shared lib' );
    my $count = () = ( $env{PERL5LIB} // '' ) =~ m{\Q$tmp\E/perl5/lib/perl5(?::|\z)}g;
    is( $count, 1, 'the shared perl5 lib appears once' );
}

# _prepend_skill_lib_to_perl_argv guard clauses.
{
    my $scalar = 'not-an-array';
    is( Developer::Dashboard::SkillDispatcher::_prepend_skill_lib_to_perl_argv( $scalar, $skill ), $scalar, 'a non-array argv is returned untouched' );
    my @foreign = ( 'sh', 'a', 'b' );
    Developer::Dashboard::SkillDispatcher::_prepend_skill_lib_to_perl_argv( \@foreign, $skill );
    is( scalar @foreign, 3, 'a non-perl argv is left untouched' );
    my @argv = ( $^X, 'a', 'b' );
    Developer::Dashboard::SkillDispatcher::_prepend_skill_lib_to_perl_argv( \@argv, undef );
    is( scalar @argv, 3, 'an undefined skill path leaves argv untouched' );
    Developer::Dashboard::SkillDispatcher::_prepend_skill_lib_to_perl_argv( \@argv, '' );
    is( scalar @argv, 3, 'an empty skill path leaves argv untouched' );
}

# _merge_saved_url_query edge cases.
{
    my $m = \&Developer::Dashboard::SkillDispatcher::_merge_saved_url_query;
    is( $m->( 'http://h/p', { a => 1 } ), 'http://h/p?a=1', 'a saved URL without a query gains the request params' );
    is( $m->( 'http://h/p?a=1&&flag&k=v', undef ), 'http://h/p?a=1&flag=&k=v', 'empty pairs are skipped and valueless keys get an empty value' );
    is( $m->( 'http://h/p?a=1', { splat => 'x', b => ['p', 'q'], c => undef } ), 'http://h/p?a=1&b=q&c=', 'splat is ignored, array values use the last item, undef becomes empty' );
    is( $m->( 'http://h/p', {} ), 'http://h/p', 'no merged keys leaves the URL alone' );
}

# _skill_page_response with pages whose meta has no source_format.
{
    no warnings 'redefine';
    my $plain = Developer::Dashboard::PageDocument->new( id => 'mk', title => 't', layout => { body => 'b' }, meta => {} );
    local *Developer::Dashboard::SkillDispatcher::_load_skill_page = sub { return $plain };
    package Local::App420 {
        sub new { return bless { runtime => Local::Runtime420->new }, shift }
        sub _decorate_skill_page_routes { return $_[1] }
        sub _page_with_runtime_state    { return $_[1] }
        sub _page_response              { return [ 200, 'text/html', 'rendered' ] }
    }
    package Local::Runtime420 {
        sub new { return bless {}, shift }
        sub prepare_page { my ( $s, %a ) = @_; return $a{page} }
    }
    my $with_app = $dispatcher->_skill_page_response( skill_name => 'mk', route_id => 'index', app => Local::App420->new );
    is( $with_app->[2], 'rendered', 'an app-rendered page without a source_format goes through the renderer' );
    my $no_app = $dispatcher->_skill_page_response( skill_name => 'mk', route_id => 'index' );
    is( $no_app->[0], 200, 'a page without a source_format renders its instruction when no app is supplied' );

    my $raw = Developer::Dashboard::PageDocument->new(
        id => 'mk', title => 't', layout => { body => 'b' },
        meta => { source_format => 'raw-url', raw_url => 'http://h/p?a=1' },
    );
    local *Developer::Dashboard::SkillDispatcher::_load_skill_page = sub { return $raw };
    my $redirect = $dispatcher->_skill_page_response( skill_name => 'mk', route_id => 'index', app => Local::App420->new );
    is( $redirect->[0], 302, 'a raw-url page redirects when no query params were supplied' );
    my $with_body = $dispatcher->_skill_page_response( skill_name => 'mk', route_id => 'index', app => Local::App420->new, body_params => { b => 2 } );
    like( $with_body->[3]{Location}, qr/b=2/, 'a raw-url redirect merges body params' );
}

# _load_skill_page: the root index route names the skill alone for raw URLs.
{
    write_file( File::Spec->catfile( $skill, 'dashboards', 'index' ), "http://h/p\n" );
    my $page = $dispatcher->_load_skill_page( skill_name => 'mk', route_id => 'index' );
    is( $page->{id}, 'mk', 'a raw-url index page is named after the skill alone' );
}

chdir $orig_cwd;
done_testing;

__END__

=pod

=head1 NAME

t/420-skilldispatcher-coverage.t - closes remaining branch and condition gaps in Developer::Dashboard::SkillDispatcher

=head1 PURPOSE

Covers the env_skill_layers fallback in dispatch, execute_hooks and exec_command,
the non-hash argument path of the streaming hook runner, shared perl5 lib
dedupe, argv guard clauses, saved-URL query merging edge cases, and
skill page responses whose page metadata carries no source_format.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs every reachable branch exercised, and these paths were only reachable through failure injection or unusual inputs that the broader tests do not produce.

=head1 WHEN TO USE

Use this file when you change the modules it covers, when a coverage run reports one of their branches or conditions as uncovered, or when you want a focused check before running the full suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/420-skilldispatcher-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release. It is hermetic: it uses temporary directories and a local HOME.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/420-skilldispatcher-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/420-skilldispatcher-coverage.t

Confirm the targeted branches and conditions are reported as covered.

=cut
