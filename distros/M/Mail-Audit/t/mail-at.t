
use strict;
use warnings;

use Test::More 'no_plan';

require Mail::Audit;

{
  my $result = Mail::Audit::__from_mailer(<<'END_HEADER');
From: "Jane Doe" <mail@janedoe.example.com>
To: <snarepops@v2.listbox.biz>
END_HEADER

  ok(! $result, 'mail from <mail@example> is not from_mailer');
}

{
  my $result = Mail::Audit::__from_mailer(<<'END_HEADER');
From: sendmail@example.com
To: <snarepops@v2.listbox.biz>
END_HEADER

  ok($result, 'mail from sendmail@example is from_mailer');
}

{
  my $result = Mail::Audit::__from_mailer(<<'END_HEADER');
From: Mailer@example.com
To: <snarepops@v2.listbox.biz>
END_HEADER

  ok($result, 'mail from Mailer@example is from_mailer');
}
