#!/usr/bin/perl
use strict;
use warnings;
use Mail::SPF::Iterator;

require 't/spf-test-suite.pl';

# local tests with +all
run(spf_all_test(SPF_SoftFail), pass_all => SPF_SoftFail);
run(spf_all_test());

# check with the test suite and skip tests which have +all
run('t/rfc7208-tests-2014.05.pl',
    pass_all => SPF_SoftFail,
    skip => [qw(all-double multispf2)]
);


sub spf_all_test {
    my $expect = shift || SPF_Pass;
    return [{
	'tests' => {
	    '+all' => {
		'spec' => '',
		'mailfrom' => 'user@example0.net',
		'description' => 'SPF policies passes all',
		'result' => "$expect",  # depends on pass_all
		'host' => '1.2.3.5',
		'helo' => 'mail.example.net'
	    },
	    'all' => {
		'spec' => '',
		'mailfrom' => 'user@example1.net',
		'description' => 'SPF policies passes all',
		'result' => "$expect",  # depends on pass_all
		'host' => '1.2.3.5',
		'helo' => 'mail.example.net'
	    },
	    'include +all' => {
		'spec' => '',
		'mailfrom' => 'user@example2.net',
		'description' => 'SPF policies passes all but has include',
		'result' => 'pass',     # don't use pass_all since include
		'host' => '1.2.3.5',
		'helo' => 'mail.example.net'
	    },
	    '-a:... +all' => {
		'spec' => '',
		'mailfrom' => 'user@example3.net',
		'description' => 'SPF policies passes all but has negative expression',
		'result' => 'pass',     # don't use pass_all since negative expression
		'host' => '1.2.3.5',
		'helo' => 'mail.example.net'
	    },
	},
	'description' => 'test option pass_all to detect pass all policies',
	'zonedata' => {
	    'example0.net' => [
		{
		    'TXT' => 'v=spf1 ip4:8.8.8.8 +all'
		}
	    ],
	    'example1.net' => [
		{
		    'TXT' => 'v=spf1 ip4:8.8.8.8 all'
		}
	    ],
	    'example2.net' => [
		{
		    'TXT' => 'v=spf1 include:example0.net +all'
		}
	    ],
	    'example3.net' => [
		{
		    'TXT' => 'v=spf1 -ip4:8.8.8.8 +all'
		}
	    ],
	}
    }];
}
