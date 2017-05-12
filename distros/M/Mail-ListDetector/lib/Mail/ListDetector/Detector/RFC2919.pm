package Mail::ListDetector::Detector::RFC2919;

use strict;
use warnings;

use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;
use Mail::ListDetector::Detector::RFC2369;
use URI;
use Carp;

sub DEBUG { 0 }

sub match {
  my $self = shift;
  my $message = shift;
  print "Got message $message\n" if DEBUG;
  carp ("Mail::ListDetector::Detector::RFC2919 - no message supplied") unless defined($message);
  use Email::Abstract;

  my $list_id = Email::Abstract->get_header($message, 'List-ID');
  return undef unless defined($list_id);
  $list_id =~ m/<(.+)>/ or return undef;
  my $listname = $1;
  
  my $rfc2369 = new Mail::ListDetector::Detector::RFC2369;
  my $list = ( $rfc2369->match($message) or new Mail::ListDetector::List );

  $list->listsoftware('RFC2919');
  $list->listname($listname);

  return $list;
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::RFC2919 - RFC2919 message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::RFC2919;

=head1 DESCRIPTION

An implementation of a mailing list detector, for RFC2919 compliant
mailing lists, i.e., those with List-ID lines in the header.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a RFC2919 compliant
mailing list, or C<undef>.

Since RFC2919 only specifies a (mostly) unique ID for a mailing list,
Mail::ListDetector::Detector::RFC2369 is used to attempt to extract
further information about the list.

=head1 BUGS

No known bugs.

=head1 AUTHOR

Michael Stevens - michael@etla.org,
Peter Oliver - p.d.oliver@mavit.freeserve.co.uk.

=cut

