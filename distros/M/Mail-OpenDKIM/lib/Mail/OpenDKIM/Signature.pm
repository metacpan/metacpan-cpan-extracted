package Mail::OpenDKIM::Signature;

use 5.010000;
use strict;
use warnings;

=head1 NAME

Mail::OpenDKIM::Signature - maintains a DKIM signature for a message

=head1 SYNOPSIS

  use Mail::DKIM::Signature;

  # create a signature object
  my $sig = Mail::OpenDKIM::Signature->new(
  	Algorithm => 'rsa-sha1',
	Method => 'relaxed',
	Domain => 'example.org',
	Selector => 'selector1',
	KeyFile => 'private.key',
  );

  # Generate a signature
  ...
  my $signature = ...
  # Store the signature

  $sig->data($signature)

  # Emit the email header line
  print $sig->as_string() . "\r\n";

=head1 DESCRIPTION

Mail::OpenDKIM::Signature maintains a signature header for an email.

It provides enough of a subset of the functionaility of Mail::DKIM::Signature to allow
use of the OpenDKIM library with Mail::OpenDKIM::Signer.

=head1 SUBROUTINES/METHODS

=head2 new

Create a new signature.

=cut

sub new {
  my ($class, %args) = @_;

  my $self = {
  };

  bless $self, $class;

  return $self;
}

=head2 data

Get and set the signature.

=cut

sub data
{
  my $self = shift;

  if(@_) {
    $self->{_signature} = shift;
  }

  return $self->{_signature};
}

=head2 as_string

Returns the signature in a form suitable for inclusion in an e-mail's header.

=cut

sub as_string
{
  my $self = shift;

  return 'DKIM-Signature: ' . $self->data();
}

=head2 EXPORT

This module exports nothing.

=head1 SEE ALSO

Mail::DKIM::Signature

Mail::OpenDKIM::Signer

=head1 NOTES

This module does not yet implement all of the API of Mail::DKIM::Signature

=head1 AUTHOR

Nigel Horne, C<< <nigel at mailermailer.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mail-opendkim at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-OpenDKIM>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::OpenDKIM::Signature

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mail-OpenDKIM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mail-OpenDKIM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mail-OpenDKIM>

=item * Search CPAN

L<http://search.cpan.org/dist/Mail-OpenDKIM/>

=back


=head1 SPONSOR

This code has been developed under sponsorship of MailerMailer LLC,
http://www.mailermailer.com/

=head1 COPYRIGHT AND LICENCE

This module is Copyright 2011 Khera Communications, Inc.
It is licensed under the same terms as Perl itself.

=cut

1;
