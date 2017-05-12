package Mail::ListDetector::Detector::LetterRip;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;
use Carp;

sub DEBUG { 0 }

sub match {
  my $self = shift;
  my $message = shift;
  print "Got message $message\n" if DEBUG;
  carp ("Mail::ListDetector::Detector::LetterRip - no message supplied") unless defined($message);
  use Email::Abstract;

  my $posting_address;
  my $list_software = Email::Abstract->get_header($message, 'List-Software');
  if(defined($list_software) && ($list_software =~ m/(LetterRip (Pro ){0,1}[\w\.]+)/)) {
    $list_software = $1;
  } else {
	return undef;
  }
  
  return undef unless my $sender = Email::Abstract->get_header($message, 'Sender');
  chomp $sender;
  $sender =~ s/<(.*)>/$1/;
    
  my $list = new Mail::ListDetector::List;
  $list->listname($sender);
  $list->listsoftware($list_software);
  $list->posting_address($sender);

  return $list;
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::LetterRip - LetterRip message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::LetterRip;

=head1 DESCRIPTION

An implementation of a mailing list detector, for LetterRip and
LetterRip Pro mailing lists, LetterRip is a commercial mailing
list manager from LetterRip Software, see http://www.letterrip.com/
for details about LetterRip.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a LetterRip
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

