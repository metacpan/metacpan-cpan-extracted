package Mail::ListDetector::Detector::Listar;

use strict;
use warnings;

use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;
use Email::Valid;
use Carp;

sub DEBUG { 0 }

sub match {
  my $self = shift;
  my $message = shift;
  print "Got message $message\n" if DEBUG;
  carp ("Mail::ListDetector::Detector::Listar - no message supplied") unless defined($message);
  use Email::Abstract;
  my @senders = Email::Abstract->get_header($message, 'Sender');
  my $list;
  foreach my $sender (@senders) {
    chomp $sender;

    ($list) = ($sender =~ /^owner-(\S+)$/);
    if (!(defined $list)) {
      print "Sender didn't match owner-, trying -owner\n" if DEBUG;
      if ($sender =~  /^(\S+?)-owner/) {
        print "Sender matched -owner, removing\n" if DEBUG;
        $list = $sender;
        $list =~ s/-owner@/@/;
      } else {
        print "Sender didn't match second owner form\n" if DEBUG;
        if ($sender =~ /^(\S+?)-bounce/) {
          print "Sender matched -bounce, removing\n" if DEBUG;
          $list = $sender;
          $list =~ s/-bounce@/@/;
        } else {
          print "Sender didn't match bounce form\n" if DEBUG;
        }
      }
    }
    last if defined $list;
  }

  return unless defined $list;
  chomp $list;
  print "Got list [$list]\n" if DEBUG;
  return unless Email::Valid->address($list);
  print "List is valid email\n" if DEBUG;

  # get listar version
  my $lv = Email::Abstract->get_header($message, 'X-listar-version');
  return undef unless defined $lv;
  chomp $lv;
  my $listname = Email::Abstract->get_header($message, 'X-list');
  return undef unless defined $listname;
  chomp $listname;
  my $l = new Mail::ListDetector::List;
  $l->listsoftware($lv);
  $l->posting_address($list);
  $l->listname($listname);
  return $l;
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::Listar - Listar message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::Listar;

=head1 DESCRIPTION

An implementation of a mailing list detector, for Listar.

Listar can be configured for rfc2369 compliance, however often this is not
done.  If an Listar list is configured to be rfc2369 compliant then it will
be recognized by that detector instead.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a listar
mailing list, or C<undef>.

=head1 BUGS

None known.

=head1 AUTHOR

Michael Stevens - michael@etla.org.

=cut

