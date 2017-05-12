package Mail::ListDetector::Detector::ListSTAR;

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
	carp ("Mail::ListDetector::Detector::ListSTAR - no message supplied") unless defined($message);
	use Email::Abstract;

	my $x_listserver = Email::Abstract->get_header($message, 'X-Listserver');
	my $x_list_software = Email::Abstract->get_header($message, 'X-List-Software');
	my $list_software = Email::Abstract->get_header($message, 'List-Software');
	my $listsoftware;
	if (defined($x_listserver) && ($x_listserver =~ m/(ListSTAR v[\w\.]+)/)) {
		$listsoftware = $1;
	} elsif (defined($list_software) && ($list_software =~ m/(ListSTAR v[\w\.]+)/)) {
		$listsoftware = $1;
	} elsif (defined($x_list_software) && ($x_list_software =~ m/(ListSTAR v[\w\.]+)/)) {
		$listsoftware = $1;
	} else {
		return undef;
	}

	my $listname;
	my $sender = Email::Abstract->get_header($message, 'Sender');
	if (defined($sender) && ($sender =~ m/<(.*)@.*>/)) {
		$listname = $1;
	}

	my $rfc2369 = new Mail::ListDetector::Detector::RFC2369
	my $list;
	unless ($list = $rfc2369->match($message)) {
		my $x_list_subscribe = Email::Abstract->get_header($message, 'X-List-Subscribe');

		return undef unless defined($x_list_subscribe);
		chomp $x_list_subscribe;
		return undef unless $x_list_subscribe =~ m/(<.*>)/;
		my $list_uri = new URI($1);
		return undef unless defined $list_uri;
		if ($list_uri->scheme ne 'mailto') {
			return undef;
		}
		my $posting_address = $list_uri->to;
		my $listname;
		if($posting_address =~ m/^(.*)@.*$/) {
			$listname = $1;
		}

		$list = new Mail::ListDetector::List;
		$list->listname($listname);
		$list->posting_address($posting_address);
	}

	if (defined($listname)) {
		$list->listname($listname);
	}

	$list->listsoftware($listsoftware);
	return $list;
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::ListSTAR - ListSTAR message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::ListSTAR;

=head1 DESCRIPTION

An implementation of a mailing list detector, for ListSTAR mailing lists,
ListSTAR (not to be confused with Listar) is a MacOS mailing list publishing tool
by MCF Software, see http://www.liststar.com/ for details about ListSTAR.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a ListSTAR
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

