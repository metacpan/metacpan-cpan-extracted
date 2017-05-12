
# $Id: google.t,v 1.4 2005/06/09 15:04:31 lem Exp $

use IO::File;
use Test::More;

my $loaded = 0;
my $config = "test$$.cfg";
my $tests = 15;

package MyReport;
use base 'Mail::Abuse::Report';
sub new { bless {}, ref $_[0] || $_[0] };
package main;

END { unlink $config; };

plan tests => $tests;

SKIP: 
{
    skip "These tests have been disabled as Google changed its interface\n", 
    $tests--;

    unless (exists $ENV{GOOGLE_PROXY})
    {
	diag "";
	diag "See file TESTING if your network requires the use of proxies.";
	diag "If this is the case, some tests may fail until " 
	    . "you follow directions.";
	diag "Tests will be attempted anyway.";
    }

    use_ok('Mail::Abuse::Reader::GoogleGroups');

    my $fh = new IO::File;
    skip "Failed to create temp config $config: $! (FATAL)\n", $tests--
	unless ($fh->open($config, "w"));

    if ($ENV{GOOGLE_PROXY})
    {
	print $fh &Mail::Abuse::Reader::GoogleGroups::PROXY, 
	": ", $ENV{GOOGLE_PROXY}, "\n";
    }

    print $fh &Mail::Abuse::Reader::GoogleGroups::QUERY, ": net\n";
    print $fh &Mail::Abuse::Reader::GoogleGroups::MAX, ": 2\n";

# Uncomment the following line to get debug output. This is useful
# when reporting bugs...
#   print $fh &Mail::Abuse::Reader::GoogleGroups::DEBUG, ": on\n";

    $fh->close;

    skip "Failed to load Mail::Abuse::Reader::GoogleGroups", $tests--
 	unless use_ok('Mail::Abuse::Reader::GoogleGroups');

    skip "You don't seem to be connected to the Internet, so the " .
  	"remaining tests cannot complete.", $tests--
  	    unless gethostbyname('www.google.com');
    
    my $r = new Mail::Abuse::Reader::GoogleGroups;
    isa_ok($r, 'Mail::Abuse::Reader::GoogleGroups');
    isa_ok($r, 'Mail::Abuse::Reader');
    my $rep = new Mail::Abuse::Report (config	=> $config, 
#				       debug	=> 1,
  				       reader 	=> $r);
    
    isa_ok($rep, 'Mail::Abuse::Report');

    for my $i (0 .. 1)
    {
	my $res = undef;
	eval { $res = $rep->next; };
	unless (ok(!$@, "[$i] ->next worked"))
	{
	    diag "[$i] eval returned:\n$@";
	}
	ok($res, "[$i] Positive result for ->next");
	ok($rep->text, "[$i] Actually fetched a message");
	ok($ {$rep->text}, "[$i] The message contains data");
#	diag "Message text:\n" . $ {$rep->text};
    }
    eval { $res = $rep->next; };
    unless (ok(!$@, "->last next worked"))
    {
	diag "eval returned:\n$@";
    }
    ok(!$res, "Negative result for last ->next");
};
