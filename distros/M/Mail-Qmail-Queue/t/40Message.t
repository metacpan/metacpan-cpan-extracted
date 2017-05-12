#!/usr/bin/perl -w

use strict;

use Test::More tests => 10;

BEGIN {
  use_ok('Mail::Qmail::Queue::Message');
};

use constant BODY_IN => 't/40Message.body.in';
use constant ENV_IN => 't/40Message.env.in';
use constant BODY_OUT => 't/40Message.body.out';
use constant ENV_OUT => 't/40Message.env.out';

unlink(BODY_OUT,ENV_OUT);

my $msg = Mail::Qmail::Queue::Message->receive(
	EnvelopeFileHandle => FileHandle->new(ENV_IN,"r"),
	BodyFileHandle => FileHandle->new(BODY_IN,"r"))
  or die "Couldn't receive message";

is($msg->body,"This is a test message.\n");
is($msg->from,'sgifford@suspectclass.com');
ok(eq_array($msg->to_ref,[qw(sgifford@suspectclass.com gifford@umich.edu)]));

${$msg->body_ref()} =~ s/This/That/;
${$msg->from_ref()} =~ s/$/-\@[]/;
push(@{$msg->to_ref()},'GIFF@cpan.org');

is($msg->body,"That is a test message.\n");
is($msg->from,'sgifford@suspectclass.com-@[]');
ok(eq_array($msg->to_ref,[qw(sgifford@suspectclass.com gifford@umich.edu GIFF@cpan.org)]));

my $qq_res = $msg->send(QmailQueue => "perl -Iblib/lib t/30Send.qq @{[BODY_OUT]} @{[ENV_OUT]}");
is($qq_res,0);
$qq_res == 0
    or die "qmail-queue send failed: status $qq_res";

is(catfile(BODY_OUT),"That is a test message.\n","Body");
is(catfile(ENV_OUT),
   "Fsgifford\@suspectclass.com-\@[]\0Tsgifford\@suspectclass.com\0Tgifford\@umich.edu\0TGIFF\@cpan.org\0\0",
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

