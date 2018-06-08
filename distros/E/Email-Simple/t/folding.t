#!perl -w
use strict;
use Test::More tests => 14;

# This time, with folding!

use_ok("Email::Simple");
sub read_file { local $/; local *FH; open FH, shift or die $!; return <FH> }

my $mail_text = read_file("t/test-mails/josey-fold");

my $mail = Email::Simple->new($mail_text);
isa_ok($mail, "Email::Simple");
is($mail->header("References"),
   q{<200211120937.JAA28130@xoneweb.opengroup.org>  <1021112125524.ZM7503@skye.rdg.opengroup.org>  <3DD221BB.13116D47@sun.com>},
    "References header checks out");
is($mail->header("reFerEnceS"),
   q{<200211120937.JAA28130@xoneweb.opengroup.org>  <1021112125524.ZM7503@skye.rdg.opengroup.org>  <3DD221BB.13116D47@sun.com>},
    "References header checks out with case folding");
is_deeply([$mail->header("Received")],
[
'from mailman.opengroup.org ([192.153.166.9]) by deep-dark-truthful-mirror.pad with smtp (Exim 3.36 #1 (Debian)) id 18Buh5-0006Zr-00 for <posix@simon-cozens.org>; Wed, 13 Nov 2002 10:24:23 +0000',
'(qmail 1679 invoked by uid 503); 13 Nov 2002 10:10:49 -0000'],
"And the received headers are folded gracefully, and multiple headers work");

{
  my $text = <<'END';
Fold-1: 1
 2 3
Fold-2: 0
 1 2

Body
END

  my $email = Email::Simple->new($text);
  is($email->header('Fold-2'), '0 1 2', "we unfold with a false start string");
}

{
  my $to   = 'to@example.com';
  my $from = 'from@example.com';

  my $subject = 'A ' x 50; # Long enough to need to be folded

  my $email_1 = Email::Simple->create(
    header => [
      To      => $to,
      From    => $from,
      Subject => $subject, # string specified in constructor does *not* get folded
    ]
  );

  unlike($email_1->as_string, qr/\Q$subject/, "we fold the 50-A line");
}

{
  my $to   = 'to@example.com';
  my $from = 'from@example.com';

  my $subject = 'A ' x 50; # Long enough to need to be folded

  my $email_1 = Email::Simple->create(
    header => [
      To      => $to,
      From    => $from,
      Subject => $subject, # string specified in constructor does *not* get folded
    ]
  );

  $email_1->header_raw_prepend( 'Test' ,"This is a test of folding an existing header which is just the right xx\r\n size to fold twice" );
  $email_1->header_raw_prepend( 'Test2' ,"This is a test of folding an existing header which is long enough to fold but should never fold because it is already folded\n manually." );
  $email_1->header_raw_prepend( 'Test3', "this\n line\n is\n very\n folded" );
  $email_1->header_raw_prepend( 'Test4', "Folded line with a crlf at the end\n" );
  $email_1->header_raw_prepend( 'Test5', 'foobar' );

  unlike($email_1->as_string(), qr/xx\r?\n\s+\r?\n/, 'we do not have a blank fold line' );
  like( $email_1->as_string(), qr/This is a test of folding an existing header which is long enough to fold but should never fold because it is already folded\n manually./, 'do not refold if already folded long lines' );
  like( $email_1->as_string(), qr/this\n line\n is\n very\n folded/, 'do not refold if already folded short lines' );
  unlike($email_1->as_string(), qr/at the end\n\s+\n/, 'no double fold on line ending in newline' );


  {
    my @warnings;
    my $string = do {
      local $SIG{__WARN__} = sub { push @warnings, $_[0] };
      $email_1->header_raw_prepend( 'Test6', "Invalid\nFolding" );
      $email_1->as_string;
    };

    is(@warnings, 1, "setting an invalidly-folded header emits a warning");
    like($warnings[0], qr/bad space/, "...and it's the right one");
    like($string, qr/Test6: Invalid\r?\n Folding\r?\n/, "header fixed");
  }
}

