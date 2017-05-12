
use strict;
use warnings;

use Test::More 'no_plan';

require Mail::Audit;

{
  my $result = Mail::Audit::__from_mailer(<<'END_HEADER');
From: "Root, Dan" <Dan.Root@snare.info>
To: <snarepops@v2.listbox.biz>
END_HEADER

  is($result, undef, "we don't block mail from poor Dan Root");
}

{
  my $result = Mail::Audit::__from_mailer(<<'END_HEADER');
From: root@popen.va
To: <snarepops@v2.listbox.biz>
END_HEADER

  like($result, qr/root/, "we block mail from root");
}
