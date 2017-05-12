package Email::Send::Test::DataDumper;

use strict;
use warnings;
our $VERSION = '0.01';

use Return::Value;
use Tie::DataDumper;
our $FILENAME;
$FILENAME = '=' unless $FILENAME;

sub is_available {
    return eval { require Tie::DataDumper }
    ? success
    : failure "is_available: Loading Tie::DataDumper failed: $@";
}

sub send {
    my ($class, $message, @args) = @_;
    my $deliveries = $class->_deliveries(@args);
    push @$deliveries, [ $class, $message, \@args ];
}

sub deliveries {
    my ($class, @args) = @_;
    my $deliveries = $class->_deliveries(@args);
    return @$deliveries;
}

sub emails {
    my ($class, @args) = @_;
    my $deliveries = $class->_deliveries(@args);
    return scalar @$deliveries unless wantarray;
    return map { $_->[1] } @$deliveries;
}

sub clear {
    my ($class, @args) = @_;
    my $deliveries = $class->_deliveries(@args);
    @$deliveries = ();
    return 1;
}

sub _deliveries {
    my ($class, @args) = @_;
    @args = ($FILENAME) unless @args;
    tie my @deliveries => 'Tie::DataDumper', $args[0];
    return \@deliveries;
}

1;
__END__

=head1 NAME

Email::Send::Test::DataDumper - Captures emails sent via Email::Send for testing, with Tie::DataDumper

=head1 SYNOPSIS

  # Load as normal
  use Email::Send;
  use Email::Send::Test::DataDumper;

  # First, set the filename for Tie::DataDumper
  $Email::Send::Test::DataDumper::FILENAME = 'sentmail.txt';

  # Always clear the email trap before each test to prevent unexpected
  # results, and thus spurious test results.
  Email::Send::Test::DataDumper->clear;
  
  ### BEGIN YOUR CODE TO BE TESTED (example follows)
  my $sender = Email::Send->new({ mailer => 'Test::DataDumper', mailer_args => [ 'sentmail.txt' ] });
  $sender->send( $message );
  ### END YOUR CODE TO BE TESTED
  
  # Check that the number and type (and content) of mails
  # matched what you expect.
  my @emails = Email::Send::Test::DataDumper->emails;
  is( scalar(@emails), 1, 'Sent 1 email' );
  isa_ok( $emails[0], 'Email::MIME' ); # Email::Simple subclasses pass through

=head1 DESCRIPTION

Email::Send::Test::DataDumper is

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

L<Email::Send::Test>,
L<Tie::DataDumper>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
