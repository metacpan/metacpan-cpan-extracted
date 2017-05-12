#!perl -w
use strict;
use Test::More tests => 5;

# This time, with folding!

use_ok("Email::Simple");
sub read_file { local $/; local *FH; open FH, shift or die $!; return <FH> }

{
  my $mail_text = read_file("t/test-mails/badly-folded");

  my $msg1 = Email::Simple->new($mail_text);
  my $msg2 = Email::Simple->new($msg1->as_string);

  is(
    $msg2->header('X-Sieve'),
    'CMU Sieve 2.2',
    "still have X-Sieve header after round trip",
  );
}

{
  my $mail_text = read_file("t/test-mails/badly-folded-noindent");

  my $msg1 = Email::Simple->new($mail_text);

  is($msg1->header('Bar'), 'Bar', "got first header ok");
  is(
    $msg1->header('Badly-Folded'),
    'This header is badly folded because even though it goes onto the second line, it has no indent.',
    "got badly folded, middle header OK",
  );
  is($msg1->header('Foo'), 'Foo', "got final header ok");
}
