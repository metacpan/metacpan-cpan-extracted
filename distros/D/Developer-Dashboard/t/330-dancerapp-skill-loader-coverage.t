#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Web::DancerApp;

# ---------------------------------------------------------------------------
# Test-only doubles for the Dancer2 application, routes, request context and
# path registry, so every defensive branch of the skill loader can be driven
# without mutating the real DeveloperDashboard Dancer2 application.
# ---------------------------------------------------------------------------
{
    package T330::Route;
    sub new { my ( $class, %a ) = @_; return bless {%a}, $class; }
    sub method { return $_[0]{method}; }
    sub match  { return $_[0]{match}; }
}

{
    package T330::App;
    sub new { my ( $class, %a ) = @_; return bless { hooks => [], %a }, $class; }
    sub name     { return 'DeveloperDashboard'; }
    sub routes   { return $_[0]{routes}; }
    sub add_hook { my ( $self, $hook ) = @_; push @{ $self->{hooks} }, $hook; return 1; }
}

{
    package T330::Paths;
    sub new { my ( $class, @entries ) = @_; return bless { entries => \@entries }, $class; }
    sub nested_skill_entries { return @{ $_[0]{entries} }; }
}

{
    package T330::Response;
    sub new { return bless { headers => [] }, $_[0]; }
    sub status       { $_[0]{status} = $_[1]; }
    sub content_type { $_[0]{content_type} = $_[1]; }
    sub content      { $_[0]{content} = $_[1]; }
    sub push_header  { push @{ $_[0]{headers} }, [ $_[1], $_[2] ]; }
}

{
    package T330::Request;
    sub new { return bless { method => $_[1] }, $_[0]; }
    sub method { return $_[0]{method}; }
    sub header { return; }
    sub env    { return {}; }
    sub body   { return ''; }
}

{
    package T330::Context;
    sub new { my ( $class, %a ) = @_; return bless { response => T330::Response->new, halted => 0, %a }, $class; }
    sub request  { return $_[0]{request}; }
    sub response { return $_[0]{response}; }
    sub halt     { $_[0]{halted}++; return; }
}

{
    package T330::Backend;
    sub new { my ( $class, %a ) = @_; return bless {%a}, $class; }
    sub authorize_request { return $_[0]{refusal}; }
}

{ package T330::NoAuthBackend; sub new { return bless {}, $_[0]; } }

sub with_fake_dancer_app {
    my ( $app, $code ) = @_;
    no warnings 'redefine';
    local *Dancer2::Core::Runner::apps = sub { return [ defined $app ? $app : () ]; };
    return $code->();
}

my $root = tempdir( CLEANUP => 1 );

# skill_dir($name, $source) writes one skill lib/Dashboard.pm (or a bare lib
# dir when no source is given) and returns the skill directory.
sub skill_dir {
    my ( $name, $source ) = @_;
    my $dir = File::Spec->catdir( $root, $name );
    make_path( File::Spec->catdir( $dir, 'lib' ) );
    if ( defined $source ) {
        my $file = File::Spec->catfile( $dir, 'lib', 'Dashboard.pm' );
        open my $fh, '>', $file or die "Unable to write $file: $!";
        print {$fh} $source;
        close $fh or die "Unable to close $file: $!";
    }
    return $dir;
}

# ---------------------------------------------------------------------------
# Early exits: no usable paths registry, and no DeveloperDashboard app.
# ---------------------------------------------------------------------------
is_deeply( Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules(undef), [], 'a missing paths registry loads nothing' );
is_deeply( Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules( bless {}, 'T330::Plain' ), [], 'a paths object without nested_skill_entries loads nothing' );

{
    my $error = with_fake_dancer_app( undef, sub {
        return eval { Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules( T330::Paths->new ); 1 } ? '' : $@;
    } );
    like( $error, qr/Unable to find the DeveloperDashboard Dancer2 application/, 'a missing Dancer2 application is fatal' );
}

# ---------------------------------------------------------------------------
# Entry filtering: non-hash, missing dir, empty dir, and dir without a module.
# ---------------------------------------------------------------------------
{
    my $no_module = skill_dir('no-module');
    my $app = T330::App->new( routes => { get => undef, post => [] } );
    my $loaded = with_fake_dancer_app( $app, sub {
        Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules(
            T330::Paths->new( 'scalar', {}, { dir => '' }, { dir => $no_module } )
        );
    } );
    is_deeply( $loaded, [], 'malformed entries and skills without Dashboard.pm are skipped' );
    is( scalar @{ $app->{hooks} }, 0, 'no authorization hook is added when no skill routes were added' );
}

# ---------------------------------------------------------------------------
# Containment and load failures.
# ---------------------------------------------------------------------------
{
    my $dir = skill_dir( 'contain', "package T330::Contain; 1;\n" );
    my $app = T330::App->new( routes => {} );

    my $run = sub {
        my ($paths) = @_;
        return with_fake_dancer_app( $app, sub {
            return eval { Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules($paths); 1 } ? '' : $@;
        } );
    };

    {
        no warnings 'redefine';
        local *Developer::Dashboard::Web::DancerApp::abs_path = sub { return; };
        like( $run->( T330::Paths->new( { dir => $dir } ) ), qr/Unable to resolve skill Dashboard module/, 'unresolvable real paths are fatal' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Web::DancerApp::abs_path = sub {
            my ($p) = @_;
            return $p =~ /Dashboard\.pm\z/ ? undef : $p;
        };
        like( $run->( T330::Paths->new( { dir => $dir } ) ), qr/Unable to resolve skill Dashboard module/, 'an unresolvable module path with a resolvable lib is fatal' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Web::DancerApp::abs_path = sub {
            my ($p) = @_;
            return $p =~ /Dashboard\.pm\z/ ? File::Spec->catfile( $root, 'contain', 'other', 'Dashboard.pm' ) : File::Spec->catdir( $root, 'contain', 'lib' );
        };
        like( $run->( T330::Paths->new( { dir => $dir } ) ), qr/resolves outside its skill lib directory/, 'a module outside its lib dir via .. is fatal' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Web::DancerApp::abs_path = sub {
            my ($p) = @_;
            return $p =~ /Dashboard\.pm\z/ ? File::Spec->catdir( $root, 'contain' ) : File::Spec->catdir( $root, 'contain', 'lib' );
        };
        like( $run->( T330::Paths->new( { dir => $dir } ) ), qr/resolves outside its skill lib directory/, 'a module that is the lib parent (..) is fatal' );
    }
    {
        no warnings 'redefine';
        local *File::Spec::abs2rel = sub { return '/absolute/result'; };
        like( $run->( T330::Paths->new( { dir => $dir } ) ), qr/resolves outside its skill lib directory/, 'an absolute relative-path result is fatal' );
    }

    my $broken = skill_dir( 'broken', "package T330::Broken; die 'boom from skill';\n1;\n" );
    like( $run->( T330::Paths->new( { dir => $broken } ) ), qr/Unable to load skill Dashboard module .*boom from skill/s, 'a skill module that dies is reported' );
}

# ---------------------------------------------------------------------------
# Route splicing: a skill adds get and put routes; the builtin fallback stays
# last for get, and a method without prior routes is handled.
# ---------------------------------------------------------------------------
{
    our ( $T330_APP );
    my $builtin_get = T330::Route->new( method => 'get' );
    my $builtin_put = T330::Route->new( method => 'put' );
    my $builtin_post = T330::Route->new( method => 'post' );
    my $app = T330::App->new( routes => { get => [$builtin_get], put => [$builtin_put], post => [$builtin_post], delete => [] } );
    $main::T330_APP = $app;
    my $dir = skill_dir( 'adds-routes', <<'PERL' );
package T330::AddsRoutes;
push @{ $main::T330_APP->routes->{get} },    bless( { method => 'get',  match => 1 }, 'T330::Route' );
push @{ $main::T330_APP->routes->{put} },    bless( { method => 'put',  match => 1 }, 'T330::Route' );
push @{ $main::T330_APP->routes->{post} },   bless( { method => 'post', match => 1 }, 'T330::Route' );
push @{ $main::T330_APP->routes->{patch} },  bless( { method => 'patch', match => 1 }, 'T330::Route' );
1;
PERL
    my $loaded = with_fake_dancer_app( $app, sub {
        Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules( T330::Paths->new( { dir => $dir } ) );
    } );
    is( scalar @{$loaded}, 1, 'the skill Dashboard.pm is loaded' );
    is( scalar @{ $app->{routes}{get} }, 2, 'get routes keep builtin plus skill route' );
    is( $app->{routes}{get}[-1], $builtin_get, 'the builtin get fallback stays last' );
    is( $app->{routes}{put}[0], $builtin_put, 'non get/post builtin routes stay first' );
    is( scalar @{ $app->{routes}{put} }, 2, 'put gains the skill route' );
    is( scalar @{ $app->{routes}{patch} }, 1, 'a method with no builtin routes keeps only the skill route' );
    is( scalar @{ $app->{hooks} }, 1, 'an authorization hook is registered once skill routes exist' );
}

# ---------------------------------------------------------------------------
# _authorize_skill_dashboard_routes guard paths and refusal rendering.
# ---------------------------------------------------------------------------
{
    my $call = sub { my @a = @_; return eval { Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes(@a); 1 } ? '' : $@; };
    like( $call->( 'nope', T330::Context->new ), qr/Missing skill route list/, 'a non-array route list is fatal' );
    like( $call->( [], 'plain-scalar' ), qr/Missing Dancer2 request context/, 'a non-reference context is fatal' );
    like( $call->( [], bless( {}, 'T330::NoRequest' ) ), qr/Missing Dancer2 request context/, 'a context without request() is fatal' );
}

{
    my $ctx = T330::Context->new( request => T330::Request->new(undef) );
    my $route = T330::Route->new( method => 'get', match => 1 );
    is( Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes( [$route], $ctx ), undef, 'an undefined request method matches no skill route' );
    is( $ctx->{halted}, 0, 'nothing is halted for an unrelated request' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::DancerApp::request = sub { return T330::Request->new('GET'); };
    my $route = T330::Route->new( method => 'get', match => 1 );
    my $request = T330::Request->new('GET');

    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP = { app => T330::NoAuthBackend->new, default_headers => {} };
    my $ctx = T330::Context->new( request => $request );
    my $error = eval { Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes( [$route], $ctx ); 1 } ? '' : $@;
    like( $error, qr/does not implement authorize_request/, 'a backend without authorize_request is fatal for skill routes' );

    $Developer::Dashboard::Web::DancerApp::BACKEND_APP = { app => T330::Backend->new( refusal => undef ), default_headers => {} };
    $ctx = T330::Context->new( request => $request );
    is( Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes( [$route], $ctx ), undef, 'an authorized skill request passes through' );
    is( $ctx->{halted}, 0, 'an authorized request is not halted' );

    $Developer::Dashboard::Web::DancerApp::BACKEND_APP = {
        app => T330::Backend->new( refusal => [ 403, 'text/plain', undef, 'not-a-hash' ] ),
        default_headers => {},
    };
    $ctx = T330::Context->new( request => $request );
    Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes( [$route], $ctx );
    is( $ctx->{halted}, 1, 'a refused request is halted' );
    is( $ctx->{response}{content}, '', 'an undefined refusal body becomes empty content' );
    is_deeply( $ctx->{response}{headers}, [], 'a non-hash header value pushes no headers' );

    $Developer::Dashboard::Web::DancerApp::BACKEND_APP = {
        app => T330::Backend->new( refusal => [ 401, 'text/plain', 'denied', { 'X-B' => 'b', 'X-A' => 'a' } ] ),
        default_headers => {},
    };
    $ctx = T330::Context->new( request => $request );
    Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes( [$route], $ctx );
    is( $ctx->{response}{content}, 'denied', 'the refusal body is rendered' );
    is_deeply( $ctx->{response}{headers}, [ [ 'X-A', 'a' ], [ 'X-B', 'b' ] ], 'refusal headers are pushed in sorted order' );
}

done_testing;

__END__

=pod

=head1 NAME

t/330-dancerapp-skill-loader-coverage.t - defensive-path coverage for the Dancer2 skill Dashboard.pm loader

=head1 PURPOSE

Drives C<_load_skill_dashboard_modules> and C<_authorize_skill_dashboard_routes>
in C<Developer::Dashboard::Web::DancerApp> through fake Dancer2 application,
route, request and response doubles so every guard, containment check, route
splice and refusal-rendering branch is exercised.

=head1 WHY IT EXISTS

The live PSGI round trip in C<t/76-web-dancerapp-coverage.t> only reaches the
happy path. The missing-application die, malformed skill entries, path
containment failures, load failures, routes without a prior builtin list, and
the authorization guards cannot occur with the real application, so they are
reached here with doubles and local overrides.

=head1 WHEN TO USE

Run it when changing how skill C<lib/Dashboard.pm> modules are discovered,
contained, loaded, spliced ahead of the builtin fallback route, or authorized.

=head1 HOW TO USE

  prove -lv t/330-dancerapp-skill-loader-coverage.t

=head1 WHAT USES IT

Developers during TDD and the Devel::Cover gate for the route adapter.

=head1 EXAMPLES

  prove -lv t/330-dancerapp-skill-loader-coverage.t

=cut
