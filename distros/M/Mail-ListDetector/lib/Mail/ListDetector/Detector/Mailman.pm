package Mail::ListDetector::Detector::Mailman;

use strict;
use warnings;

use base qw(Mail::ListDetector::Detector::Base);
use Mail::ListDetector::List;
use Carp;

sub DEBUG { 0 }

sub match {
  my $self = shift;
  my $message = shift;
  print "Got message $message\n" if DEBUG;
  carp ("Mail::ListDetector::Detector::Mailman - no message supplied") unless defined($message);
  use Email::Abstract;
  my $version = Email::Abstract->get_header($message, 'X-Mailman-Version');
  chomp $version if defined $version;
  if ((!defined $version) or $version =~ /^\s*$/) {
    print "Returning undef - couldn't find mailman version - $version\n" if DEBUG;
    return undef;
  }
  print "Mailman version $version\n" if DEBUG
  my $list;
  $list = new Mail::ListDetector::List;
  $list->listsoftware("GNU Mailman version $version");

  my $sender = Email::Abstract->get_header($message, 'Sender');
  print "Sender is $sender\n" if DEBUG && defined $sender;
  # return undef unless defined $sender;
  my $poss_posting_address;

  if (defined $sender) {
	chomp $sender;
	if ($sender =~ /^(([^@]+)-(admin|owner|bounces)(?:\+[^@]+)?\@(\S+))$/) {
		print "sender matches pattern\n" if DEBUG;
		$list->listname($2); 
		print "Listname is $2\n" if DEBUG;
		$poss_posting_address = $2 . '@' . $4;
		print "Possible posting address is $poss_posting_address\n" if DEBUG;
	} elsif ($sender =~ /^((admin|owner)-([^@]+)\@(\S+))$/) {
		$list->listname($3);
		$poss_posting_address = $3 . '@' . $4;
		print "Listname is $3\n" if DEBUG;
		print "Possible posting address is $poss_posting_address\n" if DEBUG;
	}
  } else {
		# fallback way to guess posting address and list name.
		my $beenthere = Email::Abstract->get_header($message, 'X-BeenThere');
		return undef unless defined $beenthere;
		print "X-BeenThere is $beenthere\n" if DEBUG;
		$poss_posting_address = $beenthere;
		chomp $poss_posting_address;
		if ($beenthere =~ /^([^@]+)\@/) {
			$list->listname($1);
		}
  }

  my $posting_address;
  my $list_post = Email::Abstract->get_header($message, 'List-Post');
  if (defined $list_post) {
    print "Got list post $list_post\n" if DEBUG;
    if ($list_post =~ /^\<mailto\:([^\>]*)\>$/) {
      $posting_address = $1;
      print "Got posting address $posting_address\n" if DEBUG;
      $list->posting_address($posting_address);
    }
  } else {
    print "Got posting address $poss_posting_address\n" if DEBUG;
    $list->posting_address($poss_posting_address);
  }

  print "Returning object $list\n" if DEBUG;
  return $list;
}

1;

__END__

=pod

=head1 NAME

Mail::ListDetector::Detector::Mailman - Mailman message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::Mailman;

=head1 DESCRIPTION

An implementation of a mailing list detector, for GNU Mailman.

=head1 METHODS

=head2 new()

Inherited from Mail::ListDetector::Detector::Base.

=head2 match()

Accepts a Mail::Internet object and returns either a
Mail::ListDetector::List object if it is a post to a Mailman
mailing list, or C<undef>.

=head1 BUGS

No known bugs.

=head1 AUTHOR

Michael Stevens - michael@etla.org.

=cut

