package Mail::ListDetector::Detector::Lyris;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;
use Mail::ListDetector::Detector::RFC2369;
use Carp;

sub DEBUG { 0 }

sub match {
	my $self = shift;
	my $message = shift;
	print "Got message $message\n" if DEBUG;
	carp ("Mail::ListDetector::Detector::Lyris - no message supplied") unless defined($message);
	use Email::Abstract;

	my $x_listserver = Email::Abstract->get_header($message, 'X-Listserver');
	my $x_list_software = Email::Abstract->get_header($message, 'X-List-Software');
	my $list_software = Email::Abstract->get_header($message, 'List-Software');
	my $x_lyris_message_id = Email::Abstract->get_header($message, 'X-Lyris-Message-Id');
	my $message_id = Email::Abstract->get_header($message, 'Message-Id');
	my $listsoftware;
	if (defined($x_listserver) && ($x_listserver =~ m/(Lyris v[\w\.]+)/)) {
		$listsoftware = $1;
	} elsif (defined($list_software) && ($list_software =~ m/Lyris Server version ([\w\.]+)/)) {
		$listsoftware = "Lyris $1";
	} elsif (defined($x_list_software) && ($x_list_software =~ m/Lyris v([\w\.]+)/)) {
		$listsoftware = "Lyris $1";
	} elsif (defined($x_lyris_message_id) && ($x_lyris_message_id =~ m/^<LYR/)) {
		$listsoftware = "Lyris";
	} elsif (defined($message_id) && ($message_id =~ m/^<(LYR|LISTMANAGER)/)) {
		$listsoftware = "Lyris";
	} else {
		return undef;
	}

	my ($listname, $posting_address);
	my $list_unsubscribe = Email::Abstract->get_header($message, 'List-Unsubscribe');
	print $list_unsubscribe if DEBUG;
	if (defined($list_unsubscribe)) {
		if ($list_unsubscribe =~ m/<mailto:(leave|unsubscribe)-(.*)-\d+[A-Z]{1}@(.*)>/) {
			$listname = $2;
			$posting_address = "$listname\@$3";
		} elsif ($list_unsubscribe =~ m/<mailto:(leave|unsubscribe)-(.*?)@([\w\.-]*)\??.*>/) {
			$listname = $2;
			$posting_address = "$listname\@$3";
		} else {
			return undef;
		}
	} else  {
		return undef;
	}

	my $list = new Mail::ListDetector::List;
	$list->listname($listname);
	$list->posting_address($posting_address);

	$list->listsoftware($listsoftware);
	return $list;
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::Lyris - Lyris message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::Lyris;

=head1 DESCRIPTION

An implementation of a mailing list detector, for Lyris mailing lists,
Lyris is a ???? by MCF Software, see http://www.liststar.com/ for details about Lyris.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a Lyris
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

