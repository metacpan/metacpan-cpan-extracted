package Mail::ListDetector::Detector::Ezmlm;

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
  carp ("Mail::ListDetector::Detector::Ezmlm - no message supplied") unless defined($message);
  use Email::Abstract;

  print "Getting mailing list header\n" if DEBUG;
  my $mailing_list = Email::Abstract->get_header($message, 'Mailing-List');
  return undef unless defined $mailing_list;
  print "Got header, and isn't null\n" if DEBUG;
  chomp $mailing_list;
  print "Mailing-List is [$mailing_list]\n" if DEBUG;
  my ($help, $listsoftware);
  print "Matching for information\n" if DEBUG;
  ($help, $listsoftware) = ($mailing_list =~ /^contact (\S+?)\; run by (\w+)$/);
  print "Help was [$help], listsoftware was [$listsoftware]\n" if DEBUG;
  if ((defined $listsoftware) and ($listsoftware eq 'ezmlm')) {
    print "List software matched\n" if DEBUG;
    my $list = new Mail::ListDetector::List;
    print "Set listsoftware = [$listsoftware]\n" if DEBUG;
    $list->listsoftware($listsoftware);
    my $posting = $help;
    $posting =~ s/-help\@/\@/;
    DEBUG && print "posting is [$posting]\n";
    $list->posting_address($posting);
    # FIXME: dodgy for unusual addresses.
    my ($listname) = ($posting =~ /^([^@]+)@/);
    $list->listname($listname);
    print "Returning list object\n" if DEBUG;
    return $list;
  } else {
    print "Didn't match, returning\n" if DEBUG;
    return undef;
  }
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::Ezmlm - Ezmlm message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::Ezmlm;

=head1 DESCRIPTION

An implementation of a mailing list detector, for ezmlm.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to an ezmlm
mailing list, or C<undef>.

=head1 BUGS

No known bugs.

=head1 AUTHOR

Michael Stevens - michael@etla.org.

=cut

