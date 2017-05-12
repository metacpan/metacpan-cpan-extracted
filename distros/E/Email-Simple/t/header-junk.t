#!perl
use strict;
use Test::More tests => 3;

use_ok('Email::Simple');

sub read_file { local $/; local *FH; open FH, shift or die $!; return <FH> }

my $mail_text = read_file("t/test-mails/junk-in-header");

my $mail = Email::Simple->new($mail_text);
isa_ok($mail, "Email::Simple");

unlike($mail->as_string, qr/linden/, "junk droped from header");
