
# $Id: rep-new.t,v 1.3 2003/06/22 04:51:34 lem Exp $

use IO::File;
use Test::More;

package MyReader;
use base 'Mail::Abuse::Reader';
sub read { 1; }
package main;

plan tests => 10;
my $loaded = 0;
my $r;
my $fh;

my $config = './config.' . $$;
eval { $fh = new IO::File ">./config.$$"; close $fh; };

END { unlink  $config; }

eval { use Mail::Abuse::Report; $loaded = 1; };

SKIP:
{

    skip 'Mail::Abuse::Report failed to load (FATAL)', 10
	unless $loaded;

    skip 'Cannot create empty config file. Check your permissions', 10
	unless $fh;

				# Verify the creation of an object
    my $rep = new Mail::Abuse::Report (text => \ "Contents of text",
				       config => $config);
    isa_ok($rep, 'Mail::Abuse::Report');

				# Verify the accessor
    is(($r = $rep->text, ref($r)), 'SCALAR', "Return of ->text");
    is($$r, "Contents of text");

				# Verify flush
    isa_ok($rep->flush, "Mail::Abuse::Report");
    ok(defined $rep->text, "Flushed text");

				# Verify custom accessors
    $rep->sample_key("weird accessor for a new argument");
    is($rep->sample_key, "weird accessor for a new argument");

				# Verify flushing custom attributes
    isa_ok($rep->flush, "Mail::Abuse::Report");
    ok(! defined $rep->sample_key, "Flushed sample key text");

				# Verify creation with an unexistant
				# file
    eval { $rep = new Mail::Abuse::Report (config => $config . 'no') };
    ok($@ =~ /config file must be readable/, 
       "Called with config => unexistant config");
    eval { $rep = new Mail::Abuse::Report (config => $config) };
    ok(!$@, "Called with config => existing config");
}

