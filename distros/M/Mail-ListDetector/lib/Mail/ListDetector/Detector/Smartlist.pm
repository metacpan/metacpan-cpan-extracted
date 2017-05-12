package Mail::ListDetector::Detector::Smartlist;

use strict;
use warnings;

use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;
use Carp;

sub DEBUG { 0 }

sub match {
  my $self = shift;
  my $message = shift;
  print "Got message $message\n" if DEBUG;
  carp ("Mail::ListDetector::Detector::Smartlist - no message supplied") unless defined($message);
  use Email::Abstract;
  my $mailing_list = Email::Abstract->get_header($message, 'X-Mailing-List');
  return undef unless defined $mailing_list;
  chomp $mailing_list;
  my ($posting_address) = ( $mailing_list =~ /^\<(\S+?)\> archive\/latest\/\d+/ );
  return undef unless defined $posting_address;
  return undef unless grep(/^$posting_address\s?$/, Email::Abstract->get_header($message, 'X-Loop'));
  my $list = new Mail::ListDetector::List;
  $list->listsoftware('smartlist');
  $list->posting_address($posting_address);
  my ($listname) = ($posting_address =~ /^([^@]+)@/);
  $list->listname($listname);
  return $list;

}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::Smartlist - Smartlist message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::Smartlist;

=head1 DESCRIPTION

An implementation of a mailing list detector, for smartlist.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a smartlist
mailing list, or C<undef>.

=head1 BUGS

No known bugs.

=head1 AUTHOR

Michael Stevens - michael@etla.org.

=cut

