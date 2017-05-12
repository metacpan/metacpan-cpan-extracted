package Mail::ListDetector::Detector::Listserv;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;

sub DEBUG { 0 }

sub match {
  my $self = shift;
  my $message = shift;
  print "Got message $message\n" if DEBUG;
  carp ("Mail::ListDetector::Detector::Listserv - no message supplied") unless defined($message);
  use Email::Abstract;

  my ($posting_address, $list_name, $list_software);
  my @received = Email::Abstract->get_header($message, 'Received');
  foreach my $received (@received) {
#	$received =~ s/\n/ /;
	if($received =~ m/\(LISTSERV-TCP\/IP\s+release\s+([^\s]+)\)/s) {
      $list_software = "LISTSERV-TCP/IP release $1";
      my $sender = Email::Abstract->get_header($message, 'Sender');
      if($sender =~ m/^(.*) <(.+)>$/) {
		$list_name = $1;
        $posting_address = $2;
      }
      last;
    }
  }

  unless (defined $list_software) { return undef; }

  my $list = new Mail::ListDetector::List;
  if(defined $list_name) {
    $list->listname($list_name);
  } else {
    $list->listname($posting_address);
  }
  $list->listsoftware($list_software);
  $list->posting_address($posting_address);

  return $list;
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::Listserv - Listserv message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::Listserv;

=head1 DESCRIPTION

An implementation of a mailing list detector, for LISTSERV(R) mailing lists,
LISTSERV(R) is commercial email list management software, see
<http://www.lsoft.com/> for details.

There is very little to go on to detect a LISTSERV(R) message, this detector
needs to be called close to last.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a Listserv
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

