use v5.14.0;
use warnings;

package JMAP::Tester::UA::LWP 0.104;

use Moo;
with 'JMAP::Tester::Role::UA';

use Carp ();
use Future;

has lwp => (
  is   => 'ro',
  lazy => 1,
  default => sub {
    my ($self) = @_;

    require LWP::UserAgent;
    my $lwp = LWP::UserAgent->new;
    $lwp->cookie_jar({});

    $lwp->default_header('Content-Type' => 'application/json');

    if ($ENV{IGNORE_INVALID_CERT}) {
      $lwp->ssl_opts(SSL_verify_mode => 0, verify_hostname => 0);
    }

    return $lwp;
  },
);

sub set_cookie {
  my ($self, $arg) = @_;

  for (qw(api_uri name value)) {
    Carp::confess("can't set_cookie without $_") unless $arg->{$_};
  }

  my $uri = URI->new($arg->{api_uri});

  $self->lwp->cookie_jar->set_cookie(
    1,
    $arg->{name},
    $arg->{value},
    '/',
    $arg->{domain} // $uri->host,
    $uri->port,
    0,
    ($uri->port == 443 ? 1 : 0),
    86400,
    0,
    $arg->{rest} || {},
  );
}

sub scan_cookies {
  my ($self, $callback) = @_;
  return $self->lwp->cookie_jar->scan($callback);
}

sub get_default_header {
  my ($self, $name) = @_;

  return scalar $self->lwp->default_header($name);
}

sub set_default_header {
  my ($self, $name, $value) = @_;

  $self->lwp->default_header($name, $value);
  return;
}

sub request {
  my ($self, $tester, $req, $log_type, $log_extra) = @_;

  Carp::cluck("something very strange happened") unless $tester->can('_logger');
  my $logger = $tester->_logger;

  my $log_method = "log_" . ($log_type // 'jmap') . '_request';
  if ($logger->can($log_method)) {
    $self->lwp->set_my_handler(request_send => sub {
      my ($req) = @_;
      $logger->$log_method({
        ($log_extra ? %$log_extra : ()),
        http_request => $req,
      });
      return;
    });
  }

  my $http_res = $self->lwp->request($req);

  # Clear our handler, or it will get called for
  # any http request our ua makes!
  $self->lwp->set_my_handler(request_send => undef);

  return Future->done($http_res);
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::UA::LWP

=head1 VERSION

version 0.104

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
