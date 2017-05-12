package Email::Postman::Report;
use Moose;

use DateTime;
use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

has 'about_email' => ( is => 'ro' , isa => 'Str', required => 1 );
has 'about_header' => ( is => 'rw' , isa => 'Str' , required => 1 , default => 'To' );
has 'timestamp' => ( is => 'ro', isa => 'DateTime' , required => 1 , default => sub{ DateTime->now(); } );
has 'success' => ( is => 'rw' , isa => 'Bool', default => 0);
has 'message' => ( is => 'rw' , isa => 'Str', required => 1 , default => '');
has 'failed_at' => ( is => 'rw' , isa => 'Maybe[DateTime]' , clearer => 'clear_failed_at' );

=head1 NAME

Email::Postman::Report - A report about sending a message to ONE email address.

=cut

=head2 about_email

The pure email address (like in Email::Address::address) this report is about.

=head2 timestamp

The creation <DateTime> of this report.

=head2 success

This was a success.

=head2 message

The message explaining the success (or the failure).

=head2 failed_at

In case of failure, the L<DateTime> at which the failure happened.

=head2 set_failure_message

Shortcut to set the failure state AND the message at the same time.

Usage:

 $this->set_failure_message("Something went very wrong");

=cut

sub set_failure_message{
  my ($self, $message) = @_;
  $self->success(0);
  $LOGGER->warn("Recording failure:$message");
  $self->message($message);
  $self->failed_at(DateTime->now());
}

=head2 reset

Resets this report success and message.

=cut

sub reset{
  my ($self) = @_;
  $self->success(0);
  $self->message('');
  $self->clear_failed_at();
}

=head2 failure

Opposite of success.

=cut

sub failure{
  my ($self) = @_;
  return !$self->success();
}

__PACKAGE__->meta->make_immutable();
