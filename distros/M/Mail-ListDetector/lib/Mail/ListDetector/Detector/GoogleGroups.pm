package Mail::ListDetector::Detector::GoogleGroups;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;
use Mail::ListDetector::Detector::RFC2919;
use Carp;

sub DEBUG { 0 }

sub match {
	my $self = shift;
	my $message = shift;
	print "Got message $message\n" if DEBUG;
	carp ("Mail::ListDetector::Detector::GoogleGroups - no message supplied") unless defined($message);
	use Email::Abstract;

	my $x_google_loop = Email::Abstract->get_header($message, 'X-Google-Loop');
	if (defined($x_google_loop)) {
		my $rfc2919 = new Mail::ListDetector::Detector::RFC2919;
		my $list = $rfc2919->match($message);
		unless (defined ($list)) {
			return undef;
		}

		$list->listsoftware ('Google Groups');
		my $listname = $list->listname;
		$listname =~ s/\.googlegroups\.com$//;
		$list->listname ($listname);

		return $list;
	} else {
		return undef;
	}
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::GoogleGroups - Google Groups message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::GoogleGroups;

=head1 DESCRIPTION

An implementation of a mailing list detector, for Google Groups mailing lists,
See http://groups-beta.google.com for information about Google Groups

Google Groups mailing list messages are RFC2919 compliant but this module
provides more information.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a Google Groups
mailing list, or C<undef>.

Mail::ListDetector::Detector::RFC2919 is used to extract the information
about the list, we just munge it so we know it is a Google Groups list.

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

