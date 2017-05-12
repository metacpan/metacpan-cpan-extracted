package Mail::ListDetector::Detector::RFC2369;

use strict;
use warnings;
use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;
use URI;
use Carp;

sub DEBUG { 0 }

sub match {
  my $self = shift;
  my $message = shift;
  print "Got message $message\n" if DEBUG;
  carp ("Mail::ListDetector::Detector::RFC2369 - no message supplied") unless defined($message);
  use Email::Abstract;

  my $posting_uri = Email::Abstract->get_header($message, 'List-Post');
  return undef unless defined($posting_uri);
  chomp $posting_uri;
  return undef unless $posting_uri =~ m/(<.*>)/;
  my $posting_u = new URI($1);
  return undef unless defined $posting_u;
  if ($posting_u->scheme ne 'mailto') {
    return undef;
  }
  my $posting_email = $posting_u->to;
  my $software = 'RFC2369';
  my ($listname) = ($posting_email =~ /^([^@]+)@/);
  my $list = new Mail::ListDetector::List;
  $list->listsoftware($software);
  $list->posting_address($posting_email);
  $list->listname($listname);
  return $list;

}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::RFC2369 - RFC2369 message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::RFC2369;

=head1 DESCRIPTION

An implementation of a mailing list detector, for RFC2369 compliant
mailing lists.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a RFC2369 compliant
mailing list, or C<undef>.

The RFC2369 standard does not REQUIRE all the information we wish to
extract to be present - therefore this module may not be able to
return full information for all RFC2369 compliant lists.

=head1 BUGS

No known bugs.

=head1 AUTHOR

Michael Stevens - michael@etla.org.

=cut

