#!/usr/bin/perl -I../blib/lib

require 5.00397;
use strict;
use Mail::Folder::Mbox;
use Mail::Folder::Maildir;
use Mail::Folder::Emaul;
use Mail::Address;

unless (@ARGV) {
  my $maildir  = '/var/spool/mail';
  my $user = `whoami`;
  chomp($user);
  my $mailfile = "$maildir/$user";
  die("No mail\n") if (!-f $mailfile);
  push(@ARGV, $mailfile);
}

for my $file (@ARGV) {
  my $folder = new Mail::Folder('AUTODETECT', $file);
  unless ($folder) {
    warn("can't open $folder: $!");
    next;
  }
  
  for my $msg (sort { $a <=> $b } $folder->message_list) {
    my $mref = $folder->get_header($msg);
    my $from = $mref->get('From'); chomp($from);
    my $subj = $mref->get('Subject'); chomp($subj);
    my @addrs = Mail::Address->parse($from);

    if (@addrs) {
      if ($from = $addrs[0]->phrase) {
	$from =~ s/^"//; $from =~ s/"$//;
      } elsif ($from = $addrs[0]->comment) {
	$from =~ s/^\(//; $from =~ s/\)$//;
      } else {
	$from = $addrs[0]->address;
      }
    }
    
    printf("%-20s  %s\n", $from, $subj);
  }
  
  $folder->close;
}
