#!/usr/bin/perl -w

use strict;

use Test::More tests => 3;

BEGIN {
  use_ok('Mail::Qmail::Queue::Send');
};

use constant BODY_FN => 't/30Send.body';
use constant ENV_FN => 't/30Send.env';

unlink(BODY_FN,ENV_FN);

my $qq_send = Mail::Qmail::Queue::Send->new(QmailQueue => "perl -Iblib/lib t/30Send.qq @{[BODY_FN]} @{[ENV_FN]}")
    or die "Couldn't create qmail-queue sender: $!\n";
$qq_send->body("Test message\n")
    or die "Couldn't write body: $!\n";
$qq_send->from('sgifford@suspectclass.com')
    or die "Couldn't write envelope from: $!\n";
$qq_send->to('GIFF@cpan.org')
    or die "Couldn't write envelope to #1: $!\n";
$qq_send->to('gifford@umich.edu')
    or die "Couldn't write envelope to #2: $!\n";
$qq_send->envelope_done()
    or die "Couldn't finish writing envelope: $!\n";
$qq_send->wait_exitstatus() == 0
    or die "Bad exit status from qmail-queue: $?\n";

is(catfile(BODY_FN),"Test message\n","Body");
is(catfile(ENV_FN),
   "Fsgifford\@suspectclass.com\0TGIFF\@cpan.org\0Tgifford\@umich.edu\0\0",
   "Envelope");

sub catfile
{
    my $fn = shift;
    open(F,"< $fn")
	or die "Couldn't open '$fn': $!\n";
    undef $/;
    my $r = <F>;
    close(F)
	or die "Couldn't close '$fn': $!\n";
    return $r;
}
