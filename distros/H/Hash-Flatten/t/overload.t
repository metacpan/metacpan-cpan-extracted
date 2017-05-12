#!/usr/local/bin/perl -w

###############################################################################
# Purpose : Unit test for Hash::Flatten with overload
# Author  : John Alden based on a bug report from Marcel Grünauer
# Created : Oct 2005
# CVS     : $Header: /home/cvs/software/cvsroot/hash_flatten/t/overload.t,v 1.3 2006/04/11 13:43:30 mattheww Exp $
###############################################################################
# -t : trace
# -T : deep trace into modules
###############################################################################

use strict;
use Test::Assertions qw(test);
use Getopt::Std;
use Log::Trace;

use vars qw($opt_t $opt_T);
getopts("tT");

plan tests;

#Compile the code
chdir($1) if($0 =~ /(.*)(\/|\\)(.*)/);
unshift @INC, "./lib", "../lib";
require Hash::Flatten;

#Optional tracing
import Log::Trace qw(print) if ($opt_t);
deep_import Log::Trace qw(print) if ($opt_T);

my $expected = {
	'x.bar.value' => 1,
	'x.baz.value' => 2
};

#Package without overload
package PkgSansOverload;
$PkgSansOverload::Counter=0;
sub new { bless { value => ++$PkgSansOverload::Counter }, shift }

#Package with overloaded string (if overload is available)
package PkgWithOverload;
$PkgWithOverload::Counter=0;
eval {
	require overload;
	import overload '""' => sub { 'blah' };
};
sub new { bless { value => ++$PkgWithOverload::Counter }, shift }

#########################################
# The tests
#########################################

package main;

my $data = {'x' => {}};
$data->{'x'}{'bar'} = PkgSansOverload->new;
$data->{'x'}{'baz'} = PkgSansOverload->new;
my $flat = Hash::Flatten::flatten($data);
DUMP($flat);
ASSERT(EQUAL($flat, $expected), "expected value without overload");

$data = {'x' => {}};
$data->{'x'}{'bar'} = PkgWithOverload->new;
$data->{'x'}{'baz'} = PkgWithOverload->new;
$flat = Hash::Flatten::flatten($data);
DUMP($flat);
ASSERT(EQUAL($flat, $expected), "same value with overloaded stringify");
