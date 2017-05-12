#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::App;

# ABSTRACT: to define your application

use strict;
use warnings;

our $VERSION = '1.008';    # VERSION

use Import::Into;
use Module::Runtime qw/use_module/;

use B::Hooks::EndOfScope;

sub import {
    my $target = caller;
    use_module('Moo')->import::into($target);
    on_scope_end {
        $target->can('with')->('Jedi::Role::App');
    };
    return;
}

1;

=pod

=head1 NAME

Jedi::App - to define your application

=head1 VERSION

version 1.008

=head1 DESCRIPTION

A L<Jedi::App> is a L<Moo> class with a 'jedi_app' method. This method is call directly by L<Jedi> to mount your app in
the required path.

=head1 REQUIRED METHOD

=head2 jedi_app

This method is automatically called by L<Jedi> to initialize your app.

You have to define the relative route the app takes

 sub jedi_app {
   my ($app) = @_;
   $app->get('/' => sub {
     my ($app, $request, $response) = @_;
     # ...
   });
   $app->post('/signin', $app->can('route_signin')),
 }

 sub route_signin {
   my ($app, $request, $response) = @_;
   # ...
 }

The return will decide if L<Jedi> need to continue to any other matching routes, or stop here.

If the return is B<true>, the route continue.

If the return is B<false>, the route stop here.

You can for instance :

 sub jedi_app {
   my ($app) = @_;
   $app->get(qr{.*}, $app->can("check_auth"));
   $app->get('/', $app->can("handle_index"));
 }
 
 sub check_app{
  my ($app, $request, $response) = @_;
  # check auth
  if (!$auth_ok) {
    $response->status('302');
    $response->set_header('Location', '/auth');
    return 0;
  }
  return 1;
 }

=head1 DEFINE YOUR ROUTES

All routes will take ($app, $request, $response).

=head2 get

Define a GET method.

  $app->get("/", sub{...});

=head2 post

Define a POST method.

  $jedi->post("/", sub{...});

=head2 put

Define a PUT method.

  $jedi->put("/", sub{...});

=head2 del

Define a DEL method.

  $jedi->del("/", sub{...});

=head2 missing

If no route matches, all the missing method is executed.

  $jedi->missing(sub{...});

=head1 CONFIG

The 'config' attribute of L<Jedi> is passed to all your apps.

You can access to it with the 'jedi_config' attribute :

 sub jedi_app {
  my ($app) = @_;
  my $admin_token = $app->jedi_config->{MyConf}{admin}{token};
  # ... 
 }

=head1 SERVER HOST IP

To get the server host ip, use the method 'jedi_host_ip' :

 sub jedi_app {
  my ($app) = @_;
  say "Server Host IP : ", $app->jedi_host_ip;
 }

=head1 THE REPONSE

Each route will call your method with : ($app, $request, $response).

'$app' is the 'self' of your package, a L<Jedi::App>

'$request' is the request, a L<Jedi::Request>

'$response' is the object you need to manipulate to prepare your response, a L<Jedi::Response>

Checkout the documentation of each of them to get all the possibilities.

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


