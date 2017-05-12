package Mail::ListDetector::Detector::Yahoogroups;

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
  carp ("Mail::ListDetector::Detector::Yahoogroups - no message supplied") unless defined($message);
  use Email::Abstract;
  my $mailing_list = Email::Abstract->get_header($message, 'Mailing-List');
  chomp $mailing_list if defined $mailing_list;
  if ((!defined $mailing_list) or $mailing_list =~ /^\s*$/) {
    print "Returning undef - couldn't find Mailing-List header\n" if DEBUG;
    return undef;
  }
  print "Yahoo! Groups: $mailing_list\n" if DEBUG
  my $list;
  $list = new Mail::ListDetector::List;
  $list->listsoftware("Yahoo! Groups");
  my $listname;
  my $posting_address;
  if ($mailing_list =~ /^\s*list\s+([^@\s]+)@((?:e|yahoo)groups\.(..|com));\s+contact\s+\1-owner@\2$/) {
    print "Mailing-List matches pattern\n" if DEBUG;
    $listname = $1;
    $posting_address = "$1\@$2";
    print "Got listname $listname\n" if DEBUG;
    $list->listname($listname);
    print "Got posting address $posting_address\n" if DEBUG;
    $list->posting_address($posting_address);
  } else {
    print "Mailing-List doesn't match\n" if DEBUG;
    return undef;
  }

  print "Returning object $list\n" if DEBUG;
  return $list;
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::Yahoogroups - Yahoo! Groups message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::Yahoogroups;

=head1 DESCRIPTION

An implementation of a mailing list detector, for Yahoo! Groups.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a Yahoo! Groups
mailing list, or C<undef>.

=head1 BUGS

No known bugs.

=head1 AUTHOR

Andrew Turner - turner@cpan.org

=cut

