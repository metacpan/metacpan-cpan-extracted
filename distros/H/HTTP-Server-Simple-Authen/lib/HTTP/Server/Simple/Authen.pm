package HTTP::Server::Simple::Authen;

use strict;
our $VERSION = '0.04';

use Carp;
use MIME::Base64;

sub do_authenticate {
    my $self = shift;
    if (($ENV{HTTP_AUTHORIZATION} || '') =~ /^Basic (.*?)$/) {
        my($user, $pass) = split /:/, (MIME::Base64::decode($1) || ':');
        if ($self->authen_handler->authenticate($user, $pass)) {
            return $user;
        }
    }

    return;
}

sub authen_realm { "Authorized area" }

sub authen_handler {
    my $class = ref(shift);
    Carp::croak("You have to override $class\::authen_handler to return Authen::Simple object");
}

sub authenticate {
    my $self = shift;
    my $user = $self->do_authenticate();
    unless (defined $user) {
        my $realm = $self->authen_realm();
        print "HTTP/1.0 401\r\n";
        print qq(WWW-Authenticate: Basic realm="$realm"\r\n\r\n);
        print "Authentication required.";
        return;
    }
    return $user;
}

1;
__END__

=head1 NAME

HTTP::Server::Simple::Authen - Authentication plugin for HTTP::Server::Simple

=head1 SYNOPSIS

  package MyServer;
  use base qw( HTTP::Server::Simple::Authen HTTP::Server::Simple::CGI);

  use Authen::Simple::Passwd;
  sub authen_handler {
      Authen::Simple::Passwd->new(passwd => '/etc/passwd');
  }

  sub handle_request {
      my($self, $cgi) = @_;
      my $user = $self->authenticate or return;
      ...
  }

  MyServer->new->run();

=head1 DESCRIPTION

HTTP::Server::Simple::Authen is an HTTP::Server::Simple plugin to
allow HTTP authentication. Authentication scheme is pluggable and you
can use whatever Authentication protocol that Authen::Simple supports.

You can use C<authenticate> method whatever you want to authenticate
the request. The method returns C<$username> taken from the request if
the authentication is successful, and C<undef> otherwise. The code in
L</SYNOPSIS> requires authentication for all the requests and behaves
just the same as Apache's C<Require valid-user>.

The following code will explain more about conditioning.

  sub handle_request {
      my($self, $cgi) = @_;
      if ($cgi->path_info =~ m!/foo/!) {
          my $user = $self->authenticate;
          return unless defined($user) && length($user) == 8;
      }
      ...
  }

This means all the requests to URL C</foo/> require to be
authenticated, and usernames with 8 chars long are authorized.

=head1 METHODS

Your subclass has to override following methods to implement HTTP
authentication.

=over 4

=item authen_handler

Should return a valid Authen::Simple instance to authenticate HTTP
request (Required).

=item authen_realm

Returns a string for Authentication realm to be shown in the browser's
dialog box. Defaults to 'Authorized area'.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Server::Simple>, L<Authen::Simple>

=cut
