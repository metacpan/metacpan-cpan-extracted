#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi;

# ABSTRACT: Web App Framework

use Moo;

our $VERSION = '1.008';    # VERSION

use Jedi::Helpers::Scalar;
use Jedi::Request;
use Jedi::Response;
use CHI;

use Module::Runtime qw/use_module/;
use Carp qw/croak/;
use Sys::HostIP;

# PUBLIC METHOD

has 'config' => ( is => 'ro', default => sub { {} } );
has 'host_ip' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return Sys::HostIP->new->ip() // '127.0.0.1';
    }
);

sub road {
    my ( $self, $base_route, $module ) = @_;
    $base_route = $base_route->full_path();

    my $jedi = use_module($module)->new(
        jedi_config     => $self->config,
        jedi_base_route => $base_route,
        jedi_host_ip    => $self->host_ip
    );
    croak "$module is not a jedi app" unless $jedi->does('Jedi::Role::App');

    $jedi->jedi_app;

    push( @{ $self->_jedi_roads }, [ $base_route => $jedi ] );
    $self->_jedi_roads_is_sorted(0);
    $self->_clear_jedi_roads_cache;
    return;
}

sub start {
    my ($self) = @_;
    return sub { $self->_response(@_)->to_psgi };
}

# PRIVATE METHODS AND ATTRIBUTES

# The roads is store when you register an app into a specific path
has '_jedi_roads'           => ( is => 'ro', default => sub { [] } );
has '_jedi_roads_is_sorted' => ( is => 'rw', default => sub {0} );
has '_jedi_roads_cache' => ( is => 'lazy', clearer => 1 );

sub _build__jedi_roads_cache {
    return CHI->new(
        driver    => 'RawMemory',
        datastore => {},
        max_size  => 10_000
    );
}

# The response loop on all path, using the cache and return a response format
# This response can be convert into a compatible psgi response
# The method 'start' use that method directly.
sub _response {
    my ( $self, $env ) = @_;

    my $sorted_roads = $self->_jedi_roads;
    if ( !$self->_jedi_roads_is_sorted ) {
        $self->_jedi_roads_is_sorted(1);
        @$sorted_roads
            = sort { length( $b->[0] ) <=> length( $a->[0] ) } @$sorted_roads;
    }

    my $path_info = $env->{PATH_INFO}->full_path();
    my $response  = Jedi::Response->new();

    if ( my $road_def = $self->_jedi_roads_cache->get($path_info) ) {
        my ( $road, $jedi ) = @$road_def;
        return $jedi->response(
            Jedi::Request->new(
                env  => $env,
                path => $path_info->without_base($road)
            ),
            $response
        );
    }

    for my $road_def (@$sorted_roads) {
        my ( $road, $jedi ) = @$road_def;
        if ( $path_info->start_with($road) ) {
            $self->_jedi_roads_cache->set( $path_info => $road_def );
            return $jedi->response(
                Jedi::Request->new(
                    env  => $env,
                    path => $path_info->without_base($road)
                ),
                $response
            );
        }
    }

    return Jedi::Response->new( status => 500, body => 'No road found !' );
}

1;

=pod

=head1 NAME

Jedi - Web App Framework

=head1 VERSION

version 1.008

=head1 DESCRIPTION

Jedi is a web framework, easy to understand, without DSL !

In a galaxy, far far away, a mysterious force is operating. Come on young Padawan, let me show you how to use that power wisely !

=head1 SYNOPSIS

An Jedi App is simple as a package in perl. You can initialize the app with the jedi launcher and a config file.

When you include L<Jedi::App>, it will automatically import L<Moo> and the L<Jedi::Role::App> in your package.

In MyApps.pm :

 package MyApps;
 use Jedi::App;
 
 sub jedi_app {
  my ($app) = @_;
  $app->get('/', $app->can('index'));
  $app->get('/config', $app->can('show_config'));
  $app->get(qr{/env/.+}, $app->can('env'));
 }
 
 sub index {
  my ($app, $request, $response) = @_;
  $response->status(200);
  $response->body('Hello World !');
  return 1;
 }

 sub env {
  my ($app, $request, $response) = @_;
  # path return always a "/" at the end
  # so /env/QUERY_STRING?a=1 => path = /env/QUERY_STRING/
  my $env = substr($request->path, length("/env/"), -1); 
  $response->status(200);
  $response->body(
      "The env : <$env>, has the value <" .
      ($request->env->{$env} // "") . 
    ">");
  return 1;
 }

 sub show_config {
  my ($app, $request, $response) = @_;
  $response->status(200);
  $response->body($app->jedi_config->{MyApps}{foo});
  return 1;
 }

 1;

In MyAdmin.pm :

 package MyAdmin;
 use Jedi::App;
 
 sub jedi_app {
   my ($app) = @_;
   $app->get('/', $app->can('index_admin'));
 }
 
 sub index_admin {
  my ($app, $request, $response) = @_;
  $response->status(200);
  $response->body('Admin !');
 }
 1

The you can create a lauching config app.yml :

 Jedi:
   Roads:
     MyApps: "/"
     MyAdmin: "/admin"
 Plack:
   env: production
   server: Starman
 Starman:
   workers: 2
   port: 9999
 MyApps:
   foo: bar

To start your app :

 perl-jedi -c app.yml

And if you want to test your app with your package inside the 'lib' directory :

 perl-jedi -Ilib -c app.yml

You can try requests :

 curl http://localhost:9999/
 # Hello World !
 
 curl http://localhost:9999/config
 # bar
 
 curl http://localhost:9999/admin
 # Admin !

 curl http://localhost:9999/env/QUERY_STRING?a=1
 # The env : <QUERY_STRING>, has the value <a=1>

=head1 HOW TO LAUNCH YOUR APPS

The L<Jedi> engine is a simple perl module that will handle the request and dispatch them to all your apps.

A L<Jedi::App> is plugged into the L<Jedi> engine by using the L<Jedi::Launcher> and a launch config file, or directly by using Jedi with Plack.

=head2 WITH THE Jedi::Launcher

This is the recommended method,
because it will load you config files,
merge them,
init the L<Jedi> engine and start L<Plack::Runner> with your config.

The launcher name is 'perl-jedi', and it take your configs as parameter :

 perl-jedi -c myGlobalConf.yml -c myConfForPlack.yml -c myEnvProd.yml

All this config will be merge together to create a simple HASH.

The config is composed of different parts, some of them for L<Jedi>, some of them for L<Plack::Runner> and others for your apps.

=head3 The part for L<Jedi>

 Jedi:
   Roads:
     Jedi::App::Blog: '/'
     Jedi::App::BlogAlt: '/'
     Jedi::App::Admin::Blog: '/admin'

It will load Jedi::App::Blog and Jedi::App::BlogAlt, and mount it into "/".
And also load Jedi::App::Admin::Blog, and mount it into "/admin"

You can push severals roads here, and many modules can be used with the same road.
If one app doesn't take the path, it could be handle by the next app.

=head3 The part for L<Plack::Runner>

  Plack:
    env: production
    server: Starman
  Starman:
    workers: 2
    port: 9999

The config is take in that order : L<Plack>, then read Plack / server and read the section for the server, here it is L<Starman>.

Then all the config is converted for L<Plack::Runner> as arguments. You can take a look to L<plackup> for all possible options.

=head3 The part for your app

You will receive all the config, like a simple HASH into all your apps.
And this will be exactly the same data.
So technically you can create the config you want.

But I advice for sharing purpose (if you release that on cpan), to use as a base key for your app, the name of your package :

 Jedi::App::Blog:
   template_dir: /var/www/blog
 Jedi::App::BlogAlt:
   template_dir: /var/www/blog/alt
 Jedi::App::Admin::Blog:
   defaultAdmin:
     user: admin
     password: admin

So app can read and change the config of other apps on the fly. Also you can create plugin that can do that...

For example, the L<Jedi::Plugin::Template>, will create a key PACKAGE/template_dir when it is used. So you can override that value to
use another template.

=head2 WITH Jedi AND plackup

The above example is equivalent to :

 plackup --env production --server Starman --workers 2 --port 9999 app.psgi

And the app.psgi contain :

 use Jedi;
 my $jedi = Jedi->new(config => {%configToLoadYourSelfHere});
 $jedi->road('/' => 'Jedi::App::Blog');
 $jedi->road('/' => 'Jedi::App::BlogAlt');
 $jedi->road('/admin' => 'Jedi::App::Admin::Blog');
 $jedi->start;

=head1 MANUALS

=over

=item * L<Jedi::Launcher>

You have a good overview of the jedi launcher here. You can run :

 perl-jedi --help
 perl-jedi --man

=item * L<Jedi::App>

An L<Jedi::App> is a L<Moo> package that will be load by L<Jedi>.

Each app declare a method 'jedi_app'. This method is called directly by L<Jedi> to initialize your app.

This is the good place to declare your routes, and initialize your databases and any stuff you need.

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

