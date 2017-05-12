use Test::More tests => 13;
use strict;
$^W = 1;

BEGIN { use_ok 'Email::Date', qw(format_date format_gmdate find_date) }

{
  my $time = time;
  my $date = Time::Local::timelocal Date::Parse::strptime format_date($time);
  cmp_ok($date, '==', $time, 'format_date output was parsed back into input');
}


{ # find in the Date header first:
  my $date = find_date(<<'__MESSAGE__');
Resent-Date: Tue, 6 Jul 2004 16:11:06 -0400
Date: Tue, 6 Jul 2004 16:11:05 -0400
__MESSAGE__

  isa_ok($date, 'Time::Piece', 'found Date header');

  is($date->epoch, 1089144665, "and it's the right time");
}

{ # find in the Resent-Date
  my $date = find_date(<<'__MESSAGE__');
Resent-Date: Tue, 6 Jul 2004 16:11:06 -0400
__MESSAGE__

  isa_ok($date, 'Time::Piece', 'found Resent-Date header');

  is($date->epoch, 1089144666, "and it's the right time");
}

{ # find in the Date header first:
  my $date = find_date(<<'__MESSAGE__');
Received: from cheshirecat.manxome.org (cheshirecat.manxome.org
  [66.92.232.24]) by zodiac.codesimply.com (Postfix) with SMTP id 4BB082E6060
  for <rjbs@codesimply.com>; Thu, 20 Jul 2006 18:43:26 +0000 (UTC)        
Date: Tue, 6 Jul 2004 16:11:05 -0400
__MESSAGE__

  isa_ok($date, 'Time::Piece', 'found Date header');

  is($date->epoch, 1089144665, "and it's the right time");
}

{ # find in the Received header:
  my $date = find_date(<<'__MESSAGE__');
Received: from cheshirecat.manxome.org (cheshirecat.manxome.org
  [66.92.232.24]) by zodiac.codesimply.com (Postfix) with SMTP id 4BB082E6060
  for <rjbs@codesimply.com>; Thu, 20 Jul 2006 18:43:26 +0000 (UTC)
__MESSAGE__

  isa_ok($date, 'Time::Piece', 'found Received header');

  is($date->epoch, 1153421006, "and it's the right time");
}

{ # nothing to find!
  my $date = find_date(<<'__MESSAGE__');
X-Mail-Stupid: true
X-Mailer: TheMarsupial!
Subject: writing test mails can be boring

Dear Mariah:

I miss you.

Love,
Chuck
__MESSAGE__

  is($date, undef, "no date to find in this mail");
}

is(
  length format_date, # no argument == now
  (localtime)[3] > 9 ? 31 : 30, # Day > 9 means extra char in the string
  "constant length",
);

my $birthday = 1153432704; # no, really!

is(
  format_gmdate(1153432704),
  'Thu, 20 Jul 2006 21:58:24 +0000',
  "rjbs's birthday date format properly in GMT",
);
