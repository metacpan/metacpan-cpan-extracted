package Mail::ListDetector::Detector::AutoShare;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;
use Mail::ListDetector::Detector::RFC2919;
use Mail::ListDetector::Detector::RFC2369;
use Carp;

sub DEBUG { 0 }

sub match {
	my $self = shift;
	my $message = shift;
	print "Got message $message\n" if DEBUG;
	carp ("Mail::ListDetector::Detector::AutoShare - no message supplied") unless defined($message);
	use Email::Abstract;

	my $list_software = Email::Abstract->get_header($message, 'List-Software');
	if (defined($list_software) && ($list_software =~ m/(AutoShare [\w\.]+)/)) {
		$list_software = $1;

		my $list_post = Email::Abstract->get_header($message, 'List-Post');
		return undef unless defined($list_post);
		$list_post =~ m/<(.+)>/ or return undef;
		my $posting_address = $1;

		my $rfc2919 = new Mail::ListDetector::Detector::RFC2919;
		my $rfc2369 = new Mail::ListDetector::Detector::RFC2369;
		my $list = ( $rfc2919->match($message) or $rfc2369->match($message) );

		$list->listsoftware($list_software);

		return $list;
	} else {
		return undef;
	}
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::AutoShare - AutoShare message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::AutoShare;

=head1 DESCRIPTION

An implementation of a mailing list detector, for AutoShare mailing lists,
AutoShare is a freeware Macintosh list server by Mikael Hansen, see
http://home.comcast.net/~autoshare/autoshare/ for details about AutoShare.

Some AutoShare mailing list messages are RFC2919 compliant and all are RFC2369
compliant but this module provides more information.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a AutoShare
mailing list, or C<undef>.

Since later version of AutoShare specifies a (mostly) unique ID for a mailing
list in the format of RFC2919, Mail::ListDetector::Detector::RFC2919 is used
to attempt to extract this information about the list.

=head1 BUGS

No known bugs.

=head1 AUTHOR

Matthew Walker - matthew@walker.wattle.id.au,
Michael Stevens - michael@etla.org,
Peter Oliver - p.d.oliver@mavit.freeserve.co.uk.
Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

