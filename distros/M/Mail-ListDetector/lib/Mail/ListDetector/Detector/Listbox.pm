package Mail::ListDetector::Detector::Listbox;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.02';

use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;
use Carp;

sub DEBUG { 0 }

sub match {
  my $self = shift;
  my $message = shift;
  print "Got message $message\n" if DEBUG;
  carp ("Mail::ListDetector::Detector::Listbox - no message supplied") unless defined($message);
  use Email::Abstract;

  my $posting_address;
  my $list_software = Email::Abstract->get_header($message, 'List-Software');
  my $list_id = Email::Abstract->get_header($message, 'List-Id');
  if(defined($list_software) && ($list_software =~ m/listbox.com v/)) {
    unless (defined($list_id) && ($list_id =~ m/<([^\@]+\@[^\@]+)>/)) { return undef; }
    $posting_address = $1;
	chomp($list_software);
  } elsif(defined($list_id) && ($list_id =~ m/<([^\@]+\@v2.listbox.com)>/)) {
    $posting_address = $1;
    $list_software = 'listbox.com v2.0';
  } else {
	return undef;
  }
    
  my $list = new Mail::ListDetector::List;
  $list->listname($posting_address);
  $list->listsoftware($list_software);
  $list->posting_address($posting_address);

  return $list;
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::Listbox - Listbox message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::Listbox;

=head1 DESCRIPTION

An implementation of a mailing list detector, for Listbox mailing lists,
Listbox is a commercial list hosting service, see http://www.listbox.com/
for details about Listbox.

Listbox mailing list messages look like RFC2919 messages to the current RFC2919
detector (although they are not compliant) but this module provides more
information and does not test for their full compliance (like a future
RFC2919 module might). For this reason this module must be installed
before the RFC2919 module.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a Listbox
mailing list, or C<undef>.

=head1 BUGS

No known bugs.

=head1 NOTES

Thanks to Mark Overmeer <Mark@Overmeer.net> for asking and
Meng Weng Wong <mengwong@pobox.com> for adding the List-Software
header to Listbox mails to make this detector more robust.

=head1 AUTHOR

Matthew Walker - matthew@walker.wattle.id.au,
Michael Stevens - michael@etla.org,
Peter Oliver - p.d.oliver@mavit.freeserve.co.uk.
Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

