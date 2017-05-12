
# $Id: pop3.t,v 1.2 2003/06/22 13:10:27 lem Exp $

use Test::More;
my $tests = 10;

unless (-f './poptest.cfg')
{
    plan tests => 1;
  SKIP: { skip 'See file TESTING for testing the POP3 reader', 1; }
    exit 0;
}

				# A suitable file exists...

my $loaded = 0;

eval { use Mail::Abuse::Reader::POP3; $loaded = 1; };
use Mail::Abuse::Report;

plan tests => $tests;

SKIP:
{
    skip 'Mail::Abuse::Reader::POP3 failed to load (FATAL)', $tests,
    unless $loaded;

    diag "Expect some failures if there are no messages in the inbox...";
    my $r = new Mail::Abuse::Reader::POP3;
    isa_ok($r, 'Mail::Abuse::Reader::POP3');
    isa_ok($r, 'Mail::Abuse::Reader');

    my $rep = new Mail::Abuse::Report (config => 'poptest.cfg', 
				       reader => $r);
    isa_ok($rep, 'Mail::Abuse::Report');

    eval { $rep->next };

    ok(!$@, "->next worked ok");

    ok($rep->text, "Actually fetched a message");
    ok($ {$rep->text}, "The message contains data");

    my $old = $ {$rep->text};

    my $res;

    eval { $res = $rep->next };

    ok(!$@, "->next worked again");

    skip 3, "No more messages in inbox. Probably ok"
	unless $res;

    ok($rep->text, "Actually fetched a message");
    ok($ {$rep->text}, "The message contains data");
    ok($ {$rep->text} ne $old, "The messages are different");
}
