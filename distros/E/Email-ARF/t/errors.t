#!perl
use strict;
use warnings;

use Test::More 'no_plan';

my $class;
BEGIN {
  $class = 'Email::ARF::Report';
  use_ok($class);
}

eval { my $report = $class->new; };
like($@, qr/no report source/, "you must pass input to ->new");

eval { my $report = $class->new(bless{}); };
like(
  $@,
  qr/could not be interpreted/,
  "arg to new must be string or mail::MIME"
);

{
  my $message = <<'END_MESSAGE';
MIME-Version: 1.0
Content-Type: text/plain

This is plain.
END_MESSAGE

  eval { my $report = $class->new($message); };
  like($@, qr/non-ARF content type/, "croak on wrong top-level content-type");

}

{
  my $message = <<'END_MESSAGE';
MIME-Version: 1.0
Content-Type: multipart/report; report-type="feedback-report"

This is plain.
END_MESSAGE

  eval { my $report = $class->new($message); };
  like($@, qr/too few subparts/, "an ARF report needs 3+ parts");

}
