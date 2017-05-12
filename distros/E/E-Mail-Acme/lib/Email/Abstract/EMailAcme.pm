use strict;
## no critic warnings # let's be 5.00x compatible

package Email::Abstract::EMailAcme;

$Email::Abstract::EMailAcme::VERSION = 1555;

sub target { "E::Mail::Acme" }

sub get_header {
  my ($self, $e_mail, $header) = @_;

  return unless exists $e_mail->{$header};

  if (wantarray) {
    return @{ $e_mail->{$header} };
  } else {
    return $e_mail->{$header}->[0];
  }
}

sub set_header {
  my ($self, $e_mail, $header, @values) = @_;

  my $hvalue = $e_mail->{$header};
  splice @$hvalue, 0, scalar(@$hvalue), @values;
  #$e_mail->{$header} = \@values if @values;
}

sub get_body {
  my ($self, $e_mail) = @_;

  my $whole = "$e_mail";
  my $head  = $e_mail->{''};

  $whole =~ s/\A\Q$head\E\x0d\x0a//;
  
  return $whole;
}

sub set_body {
  my ($self, $e_mail, $string) = @_;

  @$e_mail = [ $string ];
}

sub as_string {
  my ($self, $e_mail) = @_;
  "$e_mail";
}

'200-sorry';

__END__

=head1 NAME

Email::Abstract::EMailAcme - pose as a more convoluted representation of e-mail

=head1 VERSION

version 1555

=head1 SYNOPSIS

  my $abstract = Email::Abstract->new($e_mail);

=head1 DESCRIPTION

Some people are going to require you to use some obnoxious form of e-mail
object full of methods and subobjects.  Email::Abstract lets you use an
abstract wrapper that converts between all seamlessly.  This is an adapter
class to let Email::Abstract work with E'Mail::Acme.

=head1 METHODS

=head2 as_string

=head2 get_body

=head2 get_header

=head2 set_body

=head2 set_header

See L<Email::Abstract>

=head1 AUTHOR

Ricardo SIGNES wrote this module on Monday, July 16, 2007.

=head1 COPYRIGHT AND LICENSE

This code is copyright (c) 2007, Ricardo SIGNES.  It is free software,
available under the same terms as Perl itself.

=cut
