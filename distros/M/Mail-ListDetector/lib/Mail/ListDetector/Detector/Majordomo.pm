package Mail::ListDetector::Detector::Majordomo;

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
  carp ("Mail::ListDetector::Detector::Majordomo - no message supplied") unless defined($message);
  use Email::Abstract;

  my $sender = Email::Abstract->get_header($message, 'Sender');
  print "Got sender\n" if DEBUG;
  return unless defined $sender;
  print "Sender was defined\n" if DEBUG;
  chomp $sender;
  print "Sender is [$sender]\n" if DEBUG;

  my ($list) = ($sender =~ /^owner-(\S+)$/);
  if (!(defined $list)) {
    print "Sender didn't match owner-, trying -owner\n" if DEBUG;
    if ($sender =~  /^(\S+?)-owner/) {
      print "Sender matched -owner, removing\n" if DEBUG;
      $list = $sender;
      $list =~ s/-owner@/@/;
    } else {
      print "Sender didn't match second owner form\n" if DEBUG;
      return undef;
    }
  }
  return unless defined $list;
  chomp $list;
  print "Got list [$list]\n" if DEBUG;
  if ($list =~ m/(majordomo?|domo)\@/) {
	return undef;
  }
  return unless Email::Valid->address($list);
  print "List is valid email\n" if DEBUG;

  my $mv;
  # Some versions of Majordomo provide a version number
  unless ($mv = Email::Abstract->get_header($message, 'X-Majordomo-Version')) {
    # If we don't have a version number check the received headers.
    my (@received) = Email::Abstract->get_header($message, 'Received');
    my $majordom = 0;
    foreach my $received_line (@received) {
      if ($received_line =~ /(majordomo?|domo)\@/) {
        $majordom++;
        last;
      }
    }
    print "Received check returned [$majordom]\n" if DEBUG;
    return unless $majordom;
  }

  print "On list\n" if DEBUG;
  my $l = new Mail::ListDetector::List;
  if ($mv) {
    $l->listsoftware("majordomo $mv");
  } else {
    $l->listsoftware('majordomo');
  }
  $l->posting_address($list);
  print "Set listsoftware 'majordomo', posting address [$list]\n" if DEBUG;
  my ($listname) = ($list =~ /^([^@]+)@/);
  print "Listname is [$listname]\n" if DEBUG;
  $l->listname($listname);
  return $l;
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::Majordomo - Majordomo message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::Majordomo;

=head1 DESCRIPTION

An implementation of a mailing list detector, for majordomo.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a majordomo
mailing list, or C<undef>.

=head1 BUGS

=over 4

=item *

This module needs to guess a little about whether a message is a post
to a majordomo mailing list, as majordomo puts so little information in
the message headers.

=back

=head1 AUTHOR

Michael Stevens - michael@etla.org.

=cut

