#!/usr/bin/perl

require 5.00397;
use strict;
use Net::POP3;
use Mail::Folder::Mbox;

my $server = 'mailhost';
my $mailbox = 'mailbox';
my $user = 'YOUR_POP_ACCOUNT_NAME';
my $pass = 'YOUR_POP_ACCOUNT_PASSWORD';

my @deletes;

autoflush STDOUT 1;

print "opening $mailbox\n";
my $folder = Mail::Folder->new('mbox', $mailbox, Create => 1, NotMUA => 1)
  or die "can't create local mailfolder object: $!";

print("connecting to $server\n");
my $pop = Net::POP3->new($server, Debug => 0)
  or die "can't connect to $server\n";

print "logging in\n";
my $qtymsgs = $pop->login($user, $pass);

if (defined($qtymsgs)) {
  if ($qtymsgs) {
    print "retrieving $qtymsgs message", ($qtymsgs > 1)?'s':'', ": ";
    for my $msgnum (1 .. $qtymsgs) {
      if (my $msg = $pop->get($msgnum)) {
	print '.';
	pop(@{$msg}) if ($msg->[$#{$msg}] eq "\n");
	my $mref = new Mail::Internet($msg, Modify => 0);
	$folder->append_message($mref);
	push(@deletes, $msgnum);
      } else {
	print 'x';
      }
    }
    print("\n");
    $folder->sync if (defined(@deletes));
  } else { print("no messages\n"); }
} else { warn("can't log into $server\n"); }

$folder->close;

print "deleting messages on $server\n" if (@deletes);
map { $pop->delete($_) } @deletes;

print "disconnecting\n";
$pop->quit;
