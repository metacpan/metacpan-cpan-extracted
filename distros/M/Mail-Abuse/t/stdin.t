
# $Id: stdin.t,v 1.1 2003/10/31 17:40:23 lem Exp $

use IO::File;
use Test::More;
use Mail::Abuse::Reader::Stdin;

my @msgs = (
	    "This is the first message\n",
	    "This is the second message\n",
	    "This is the third message\n",
	    "This is the fourth message\n",
	    "This is the fifth message\n",
	    "This is the sixth message\n",
	    );

my $loaded = 0;
my $config = "test$$.cfg";
my $tests = 3 + 4 * @msgs;

eval { use Mail::Abuse::Reader::POP3; $loaded = 1; };

package MyReport;
use base 'Mail::Abuse::Report';
sub new { bless {}, ref $_[0] || $_[0] };
package main;

plan tests => $tests;

END { unlink $config; };

SKIP:
{
    *ARGV = \*DATA;		# Fake an ARGV fh based in our test data

    my $fh = new IO::File;
    $fh->open($config, "w") 
	or skip "Failed to create temp config $config: $! (FATAL)\n", $tests;

    print $fh "stdin delimiter: ___REPORT___\n";

    $fh->close;

    skip 'Mail::Abuse::Reader::Stdin failed to load (FATAL)', $tests,
    unless $loaded;

    my $r = new Mail::Abuse::Reader::Stdin;
    isa_ok($r, 'Mail::Abuse::Reader::Stdin');
    isa_ok($r, 'Mail::Abuse::Reader');

    my $rep = new Mail::Abuse::Report (config => $config, 
				       reader => $r);

    isa_ok($rep, 'Mail::Abuse::Report');

    for my $m (@msgs)
    {
	eval { $rep->next; };
	ok(!$@, "->next worked");
	ok($rep->text, "Actually fetched a message");
	ok($ {$rep->text}, "The message contains data");
	is($ {$rep->text}, $m);
    }
};

__DATA__
This is the first message
___REPORT___
This is the second message
___REPORT___
This is the third message
___REPORT___
This is the fourth message
___REPORT___
This is the fifth message
___REPORT___
This is the sixth message
___REPORT___
