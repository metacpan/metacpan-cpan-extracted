use v5.14.0;
use warnings;

package JMAP::Tester::UA::Async 0.104;

use Moo;
with 'JMAP::Tester::Role::UA';

use Future;

has http_client => (
  is   => 'ro',
  required => 1,
);

sub set_cookie {
  my ($self, $arg) = @_;

  for (qw(api_uri name value)) {
    Carp::confess("can't set_cookie without $_") unless $arg->{$_};
  }

  my $uri = URI->new($arg->{api_uri});

  $self->http_client->{cookie_jar}->set_cookie(
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
  return $self->http_client->{cookie_jar}->scan($callback);
}

has _default_headers => (
  is => 'ro',
  default => sub {
    {
      'Content-Type' => 'application/json',
    }
  },
);

sub get_default_header {
  my ($self, $name) = @_;

  return scalar $self->_default_headers->{$name};
}

sub set_default_header {
  my ($self, $name, $value) = @_;

  if (defined $value) {
    $self->_default_headers->{$name} = $value;
  } else {
    delete $self->_default_headers->{$name};
  }

  return;
}

sub request {
  my ($self, $tester, $req, $log_type, $log_extra) = @_;

  my $dh = $self->_default_headers;
  for my $h (keys %$dh) {
    $req->header($h => $dh->{$h}) unless defined $req->header($h);
  }

  my $logger = $tester->_logger;

  my $log_method = "log_" . ($log_type // 'jmap') . '_request';

  return $self->http_client->do_request(
    request => $req,
    on_ready => sub {
      # This fires just before the request is written to the socket, just
      # like how LWP::UserAgent logs the request before actually sending
      # it
      my $log_method = "log_" . ($log_type // 'jmap') . '_request';

      if ($logger->can($log_method)) {
        $tester->_logger->$log_method({
          ($log_extra ? %$log_extra : ()),
          http_request => $req,
        });
      }

      return Future->done;
    },
  );
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::UA::Async

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
