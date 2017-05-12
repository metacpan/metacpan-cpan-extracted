# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 11;

BEGIN { $| = 1; }
use_ok(Log::Accounting::Sendmail);

######################### End of black magic.

my $sm = Log::Accounting::Sendmail->new();
ok($sm->add(<<END), "add");
Apr 26 00:36:11 pizza sm-mta[76734]: i3PMa7Xo076734: from=<olimaul\@cpan.org>, size=3314, class=-60, nrcpts=1, msgid=<200404252235.i3PMZslE031153\@pause.perl.org>, proto=SMTP, daemon=MTA, relay=x1.develooper.com [63.251.223.170]
Apr 26 00:36:15 pizza sm-mta[76735]: i3PMa7Xo076734: to=<oli\@42.nu>, delay=00:00:05, xdelay=00:00:04, mailer=local, pri=141552, dsn=2.0.0, stat=Sent
END
my %out;
ok(%out = $sm->calc(), "calc");
ok(($out{"olimaul\@cpan.org"}->[0]->[0] eq "oli\@42.nu" &&
    $out{"olimaul\@cpan.org"}->[0]->[1] == 3314), "check");

ok($sm->reset(), "reset");

ok($sm->add(<<END), "add2");
Apr 26 13:04:10 pizza sm-mta[30871]: i3QB49mW030871: from=<oli\@42.nu>, size=119649, class=0, nrcpts=2, msgid=<20040426130231.X30361-100001\@pizza.42.nu>, proto=ESMTP, daemon=MTA, relay=localhost [127.0.0.1]
Apr 26 13:04:10 pizza sendmail[30870]: i3QB49LZ030868: to=<foo\@bar.com>, delay=00:00:01, xdelay=00:00:01, mailer=relay, pri=149401, relay=[127.0.0.1] [127.0.0.1], dsn=2.0.0, stat=Sent (i3QB49mW030871 Message accepted for delivery)
Apr 26 13:04:10 pizza sendmail[30870]: i3QB49LZ030868: to=<foo2\@bar.com>, delay=00:00:01, xdelay=00:00:01, mailer=relay, pri=149401, relay=[127.0.0.1] [127.0.0.1], dsn=2.0.0, stat=Sent (i3QB49mW030871 Message accepted for delivery)
Apr 26 13:04:16 pizza sm-mta[30874]: i3QB49mW030871: to=<foo\@bar.com>, ctladdr=<oli\@42.nu> (1000/1000), delay=00:00:06, xdelay=00:00:06, mailer=esmtp, pri=149649, relay=mail.bar.com. [192.168.159.249], dsn=2.0.0, stat=Sent (OK)
Apr 26 13:04:16 pizza sm-mta[30874]: i3QB49mW030871: to=<foo2\@bar.com>, ctladdr=<oli\@42.nu> (1000/1000), delay=00:00:06, xdelay=00:00:06, mailer=esmtp, pri=149649, relay=mail.bar.com. [192.168.159.249], dsn=2.0.0, stat=Sent (OK)
END
ok($sm->filter("oli\@42.nu"), "filter2");
ok($sm->group("oli"), "group2");
ok($sm->map(oli => ["oli\@42.nu"]), "map2");
ok(%out = $sm->calc(), "calc2");
ok(($out{"oli"}->[0] == 2 && $out{"oli"}->[1] == 239298), "check2");
