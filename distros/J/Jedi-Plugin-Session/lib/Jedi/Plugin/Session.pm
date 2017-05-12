#
# This file is part of Jedi-Plugin-Session
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Session;

# ABSTRACT: Session for Jedi

use strict;
use warnings;

our $VERSION = '0.05';    # VERSION

use Import::Into;
use Module::Runtime qw/use_module/;

use B::Hooks::EndOfScope;

sub import {
    my ( undef, $backend ) = @_;
    $backend //= 'Memory';
    my $target = caller;
    on_scope_end {
        $target->can('with')->('Jedi::Plugin::Session::Role');
        $target->can('with')->( 'Jedi::Plugin::Session::Role::' . $backend );
    };
    return;
}

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Session - Session for Jedi

=head1 VERSION

version 0.05

=head1 DESCRIPTION

This plugin add to the L<Jedi::Request> two methods : B<session_get> and B<session_set>

A secure UUID is generated on all get/post request, and if the cookie jedi_session is missing, then it will automatically
create it to keep the same UUID between each request.

If the cookie with the UUID is copied on a different browser / computer, it will work but the session will not be the same.

=head1 SYNOPSIS

The session is very specific to an app, different app in the same L<Jedi> instance, will use different session data.

 package MyJediApp;
 use Jedi::App;
 use Jedi::Plugin::Session;
 use JSON;
 sub jedi_app {
  my ($app) = @_;

  $app->get('/set_session', sub {
    my ($app, $request, $response) = @_;
    my $session = $request->session_get // {};
    $session->{val1} = { this => 'is', a => 'test' };
    $request->session_set($session);
    $response->status(200);
    $response->body('session set !')
  });
 
  $app->get('/get_session', sub {
    my ($app, $request, $response) = @_;
    my $session = $request->session_get;
    $response->status(200);
    $response->body(defined $session ? encode_json($session) : 'session not defined !');
  })
 }
 1;

=head1 LIMITATION

The session is keep in memory and serialized. You can't save CODE or unserializable object in the session.

The default expiration is '3 hours'. The cookie with a part of the UUID is keep for 2 years and sent only once.

=head1 EXPIRATION

To change the default expiration for your app, you can use the configuration like this :

 MyJediApp: # package name of your app
  session:
    expiration: 3 hours

Check L<Time::Duration::Parse> for the possible value of the expiration.

If you need to set the full expiration time again, you can just set again the session :

 $request->session_set($request->session_get // {});

=head1 BACKENDS

=head2 Memory

The default backend is memory. It use L<CHI> with the Memory driver.

=head2 Redis

You can use L<Redis> as a backend.

 package MyJediApp;
 use Jedi::App;
 use Jedi::Plugin::Session 'Redis';

Everything work the same way.

You can setup L<Redis> access in the configuration like this :

 MyJediApp: # package name of your app
  session:
    expiration: 3 hours
    redis:
      config:
        reconnect: 2
        every: 100
        server: 127.0.0.1:6900
      prefix: my_jedi_app

The redis_prefix will be used to generate the session key. The result will be :

  jedi_prefix_YOUR_PREFIX_UUID

=head2 SQLite

You can use L<DBD::SQLite> as a backend.

 package MyJediApp;
 use Jedi::App;
 use Jedi::Plugin::Session 'SQLite';

You can configuration SQLite database file in the configuration :

 MyJediApp: # package name of your app
  session:
    expiration: 3 hours
  sqlite:
    path: /var/lib/jedi_session

The path is the base path for your app. In that case the final file is :

  /var/lib/jedi_session/MyJediApp.db

If your app name is My::Jedi::App, then the final file is :

  /var/lib/jedi_session/My/Jedi/App.db

By default the file is store in the Jedi::Plugin::Session dist_dir. Each app has his own database.

If you start multiple workers, all of them will use the same database and then share the session.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi-plugin-session/issues

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
