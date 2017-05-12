package Mail::ListDetector::Detector::CommuniGate;

use strict;
use warnings;

use vars qw($VERSION);
use Email::Abstract;
$VERSION = '0.01';

use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;
use Carp;

sub DEBUG { 0 }

sub match {
	my $self = shift;
	my $message = shift;
	print "Got message $message\n" if DEBUG;
	carp ("Mail::ListDetector::Detector::CommuniGate - no message supplied") unless defined($message);

	my $x_listserver = Email::Abstract->get_header($message, 'X-Listserver');
	if (defined($x_listserver) && ($x_listserver =~ m/CommuniGate List/)) {
		chomp $x_listserver;

		my $sender = Email::Abstract->get_header($message, 'Sender');
		return undef unless defined($sender);
		$sender =~ m/([^\s]+@[^\s]+)\s+\((.*)\)/ or return undef;
		my $posting_address = $1;
		my $listname = $2;

		my $list = new Mail::ListDetector::List;

		$list->listsoftware($x_listserver);
		$list->posting_address($posting_address);
		$list->listname($listname);

		return $list;
	} else {
		return undef;
	}
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::CommuniGate - CommuniGate message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::CommuniGate;

=head1 DESCRIPTION

An implementation of a mailing list detector, for CommuniGate mailing lists,
CommuniGate is a legacy MacOS messaging application, see
http://www.stalker.com/mac/default.html for details about CommuniGate.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a CommuniGate
mailing list, or C<undef>.

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

