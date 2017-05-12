use strict;
use warnings;

use Test::More tests => 31;

use_ok 'Email::Simple';
use_ok 'Email::Simple::Creator';

sub tested_email {
  my ($name, %args) = @_;

  my $email = Email::Simple->create(%args);
  isa_ok $email, 'Email::Simple', "$name message";

  my $string = $email->as_string;

  my @last_two = (
    substr($string, -2, 1),
    substr($string, -1, 1),
  );

  is(
    sprintf("%03u %03u", map { ord } @last_two),
    '013 010',
    "$name: stringified message ends with std CRLF"
  );

  unlike(
    $email->as_string,
    qr/(?<!\x0d)\x0a/,
    "$name: message has no LF that aren't preceded by CR",
  );

  return $email;
}

{
  my $body = "This body uses\x0d"
           . "LF only, and not\x0d"
           . "CRLF like it might ought to do.";

  tested_email(crlf =>
    body   => $body,
    header => [
      Subject => 'all tests and no code make rjbs something something',
      From    => 'jack',
      To      => 'sissy',
    ],
  );
}

{ # should get an automatic date header
  my $email = tested_email(auto_date =>
    header => [
      To => 'you',
    ],
    body => 'test test',
  );

  like(
    $email->header('date'),
    qr/^[A-Z][a-z]{2},/, # lame -- rjbs, 2007-02-23
    "we got an auto-generated date header starting with a DOW",
  );
}

{ # who needs args?  (why is this legal? who knows -- rjbs, 2007-07-13)
  my $email = tested_email('argless');

  like(
    $email->header('date'),
    qr/^[A-Z][a-z]{2},/, # lame -- rjbs, 2007-02-23
    "we got an auto-generated date header starting with a DOW",
  );
}

{ # no need to add CRLF if it's there
  my $email = tested_email(has_crlf =>
    header => [
      To => 'you',
    ],
    body => "test test\x0d\x0a",
  );
}

{ # no date header, we provided one
  my $email = tested_email(has_date =>
    header => [
      Date       => 'testing',
      'X-Header' => 'one',
      'X-Header' => 'two',
      'X-Header' => 'three',
    ],
    body => q[This is a multi-
    line message.],
  );

  my $expected = <<'END_MESSAGE';
Date: testing
X-Header: one
X-Header: two
X-Header: three

This is a multi-
    line message.
END_MESSAGE

  my $string = $email->as_string;
  $string  =~ s/\x0d\x0a/\n/gsm;

  is(
    $string,
    $expected,
    "we got just the string we expected",
  );
}

{ # a few headers with false values
  my $email = tested_email(falsies =>
    header => [
      Date  => undef,
      Zero  => 0,
      Empty => '',
    ],
    body => "The body is uninteresting.",
  );

  is_deeply(
    [ $email->header_pairs ],
    [
      Date => '',
      Zero => 0,
      Empty => '',
    ],
    "got the false headers back we want",
  );

  my $expected = <<'END_MESSAGE';
Date: 
Zero: 0
Empty: 

The body is uninteresting.
END_MESSAGE

  my $string = $email->as_string;
  $string  =~ s/\x0d\x0a/\n/gsm;

  is(
    $string,
    $expected,
    "we got just the string we expected",
  );
}

{ # no date header, we provided one
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my $email = tested_email(has_date =>
    header => [
      Date       => 'testing',
      'X-Header' => "foo\n\nbar",
    ],
    body => q[This is a single-line message.],
  );

  is(@warnings, 1, "there was one warning");
  like($warnings[0], qr/vertical whitespace/, 'and it was about \v characters');

  my $expected = <<'END_MESSAGE';
Date: testing
X-Header: foo bar

This is a single-line message.
END_MESSAGE

  my $string = $email->as_string;
  $string  =~ s/\x0d\x0a/\n/gsm;

  is(
    $string,
    $expected,
    "we got just the string we expected",
  );
}
