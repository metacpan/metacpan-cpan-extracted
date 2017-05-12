#!perl -w
use strict;
use Test::More tests => 3;

# This time, with folding!

use_ok("Email::Simple");
sub read_file { local $/; local *FH; open FH, shift or die $!; return <FH> }

my $mail_text = read_file("t/test-mails/long-msgid");

my $mail = Email::Simple->new($mail_text);
isa_ok($mail, "Email::Simple");

SKIP: {
    skip "no alarm() on win32", 1 if $^O =~ /mswin32/i;
    alarm 5;
    ok($mail->as_string(), "Doesn't hang");
};
