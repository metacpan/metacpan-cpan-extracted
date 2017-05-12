package Mail::OpenDKIM::PrivateKey;

use 5.010000;
use strict;
use warnings;
use Carp;

=head1 NAME

Mail::OpenDKIM::PrivateKey - Load in a private key for use with the Mail::OpenDKIM package

=head1 SYNOPSIS

  use Mail::OpenDKIM::PrivateKey;

  my $pk;

  eval {
     $pk = Mail::OpenDKIM::PrivateKey->load(File => 'mykeyfile'));
  }
  if(defined($pk)) {
    # Do something with $pk->data();
    ...
  }

=head1 DESCRIPTION

Mail::OpenDKIM::PrivateKey provides a system to allow private keys to be loaded from a file
for use when signing an email with Mail::OpenDKIM::Signer.

It provides enough of a subset of the functionaility of Mail::DKIM::PrivateKey to allow
use of the OpenDKIM library with Mail::OpenDKIM::Signer.

=head1 SUBROUTINES/METHODS

=head2 load

=cut

sub load
{
  my ($class, %args) = @_;

  my $self = {
    _data => undef,
  };

  bless $self, $class;

  if($args{File}) {
    open(my $fin, '<', $args{File}) or croak("Can't open $args{File}: $!");
    while(!eof($fin)) {
      my $line = <$fin>;
      chomp $line;
      unless($line =~ /^---/) {
        $self->{_data} .= $line;
      }
    }
    close $fin;
  }
  elsif($args{Data}) {
    $self->{_data} = $args{Data};
  }

  return $self;
}

=head2 data

This routine provides access to the key data.

=cut

sub data {
  my $self = shift;

  return $self->{_data};
}

=head2 EXPORT

This module exports nothing.

=head1 SEE ALSO

Mail::DKIM::PrivateKey

=head1 NOTES

This module does not yet implement all of the API of Mail::DKIM::PrivateKey

=head1 AUTHOR

Nigel Horne, C<< <nigel at mailermailer.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mail-opendkim at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-OpenDKIM>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::OpenDKIM::PrivateKey


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

This module is Copyright 2011 Khera Communications, Inc.  It is
licensed under the same terms as Perl itself.

=cut

1;
