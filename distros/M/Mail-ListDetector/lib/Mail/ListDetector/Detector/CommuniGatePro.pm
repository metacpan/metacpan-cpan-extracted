package Mail::ListDetector::Detector::CommuniGatePro;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.02';

use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;
use Mail::ListDetector::Detector::RFC2919;
use Carp;

sub DEBUG { 0 }

sub match {
	my $self = shift;
	my $message = shift;
	print "Got message $message\n" if DEBUG;
	carp ("Mail::ListDetector::Detector::CommuniGatePro - no message supplied") unless defined($message);
	use Email::Abstract;

	my $x_listserver = Email::Abstract->get_header($message, 'X-Listserver');
	if (defined($x_listserver) && ($x_listserver =~ m/CommuniGate Pro LIST/)) {
		chomp $x_listserver;

		my $sender = Email::Abstract->get_header($message, 'Sender');
		return undef unless defined($sender);
		$sender =~ m/<(.+)>/ or return undef;
		my $posting_address = $1;

		my $rfc2919 = new Mail::ListDetector::Detector::RFC2919;
		my $list = ( $rfc2919->match($message) or new Mail::ListDetector::List );

		$list->listsoftware($x_listserver);
		$list->posting_address($posting_address);

		return $list;
	} else {
		return undef;
	}
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::CommuniGatePro - CommuniGate Pro message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::CommuniGatePro;

=head1 DESCRIPTION

An implementation of a mailing list detector, for CommuniGate Pro mailing lists,
See http://www.stalker.com/ for details about CommuniGate Pro.

CommuniGate Pro mailing list messages are RFC2919 compliant but this module
provides more information.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a CommuniGate Pro
mailing list, or C<undef>.

Since CommuniGate Pro specifies a (mostly) unique ID for a mailing list
in the format of RFC2919, Mail::ListDetector::Detector::RFC2919 is used
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

