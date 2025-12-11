use v5.14.0;
use warnings;

package JMAP::Tester::UA::Test 0.107;

use Moo;
with 'JMAP::Tester::Role::UA';

use Carp ();
use Future;
use HTTP::Response;

has request_handler => (
  is  => 'ro',
  required => 1,
  default  => sub {
    return sub {
      return HTTP::Response->new(200, "Reply meaningless");
    };
  },
);

has _transactions => (
  is => 'rw',
  init_arg => undef,
  lazy     => 1,
  default  => sub {  []  },
  clearer  => 'clear_transactions',
);

sub transactions {
  my ($self) = @_;
  return $self->_transactions->@*;
}

sub request {
  my ($self, $tester, $req, $log_type, $log_extra) = @_;

  my $res = $self->request_handler->(@_);

  my $logger = $tester->_logger;
  my $log_method = "log_" . ($log_type // 'jmap') . '_request';

  $logger->$log_method(
    $tester,
    {
      ($log_extra ? %$log_extra : ()),
      http_request => $req,
    }
  );

  push $self->_transactions->@*, {
    request  => $req,
    response => $res,
  };

  return Future->done($res);
}

sub set_cookie         { Carp::confess("set_cookie not implemented") }
sub scan_cookies       { Carp::confess("scan_cookies not implemented") }
sub get_default_header { Carp::confess("get_default_header not implemented") }
sub set_default_header { Carp::confess("set_default_header not implemented") }

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::UA::Test

=head1 VERSION

version 0.107

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
