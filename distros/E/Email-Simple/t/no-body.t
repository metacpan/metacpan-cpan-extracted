#!perl -w
use strict;
use Test::More tests => 5;

# This time, with folding!

use_ok("Email::Simple");
sub read_file { local $/; local *FH; open FH, shift or die $!; return <FH> }

for ('', '-blank') {
  my $mail_text = read_file("t/test-mails/josey-nobody$_");

  my $mail = Email::Simple->new($mail_text);
  isa_ok($mail, "Email::Simple");

  is(
    $mail->header('From'),
    'Andrew Josey <ajosey@rdg.opengroup.org>',
    'correct From header on bodyless message',
  );
}

