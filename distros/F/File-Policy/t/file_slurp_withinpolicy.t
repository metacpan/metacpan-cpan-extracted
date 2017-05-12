#!/usr/local/bin/perl

#
# Test harness for File::Slurp::WithinPolicy
# $Id: file_slurp_withinpolicy.t,v 1.3 2005/06/15 10:40:04 simonf Exp $
#

use strict;
use lib qw(./lib ../lib);
use File::Policy qw(:all);
use File::Slurp::WithinPolicy qw(:all);
use Test::Assertions 'test';
use Log::Trace;
use Getopt::Std;
use Cwd;

use vars qw($opt_t $opt_T $opt_s);
getopts("tTs");

plan tests;

#So if can find config files even when run from make
if (-d 't') {
	chdir 't';
}

#Tracing
import Log::Trace qw(print) if($opt_t);
import Log::Trace ('print' => {Deep => 1}) if($opt_T);

my $i;
my $o;
my $root = cwd();

# clear the decks for the temp files
unlink("$root/FSWP_TEST", "$root/FSWP_TEST_LIST", "$root/FSWP_TEST_REF", "$root/FSWP_TEST_BLOCK", "$root/FSWP_TEST_APPEND");

# let's set $/ to be something unusual to check we can handle it
$/ = 'r';

####################################################################
# simple read and write
$o = 'this is a test';
ASSERT( overwrite_file("$root/FSWP_TEST", $o) , 'write file - string');
ASSERT( ($i = read_file("$root/FSWP_TEST")) , 'read back');
ASSERT( ($i eq $o), 'ensure data matches' );

####################################################################
# Write by reference
$o = 'this is a reference test';
ASSERT( write_file("$root/FSWP_TEST_REF", \$o) , 'write file - string reference');
ASSERT( $i = read_file("$root/FSWP_TEST_REF") , 'read back');
ASSERT( ($i eq $o) , 'ensure data matches');

####################################################################
# Read back into a buffer ref
$o = 't' x 100000;
ASSERT( write_file("$root/FSWP_TEST_REF", {buf_ref => \$o}) , 'write file - string reference 1e5 bytes');
my $refString;
read_file("$root/FSWP_TEST_REF", buf_ref => \$refString);
TRACE("length = ".length($refString));
ASSERT( (ref \$refString eq 'SCALAR'), 'right reference type');
ASSERT( (length($refString) == 100000), 'correct length');
ASSERT( ($refString eq $o), 'correct string');

####################################################################
# testing the list-context read.
my @list;
$o = "line1$/line2$/line3$/line4$/line5$/";
ASSERT( write_file("$root/FSWP_TEST_LIST", $o) , 'write file - multiline');
eval q{ @list = read_file("$root/FSWP_TEST_LIST");};
DUMP(\@list);
ASSERT( (! $@) , 'read back list - eval outcome');
ASSERT( ($#list > 0) , 'read back list - has array filled');
ASSERT( ($list[0] eq "line1$/") , 'ensure data matches');

####################################################################
# now let's check we don't have any nasty block IO problems
# big file
$o = (int(rand(1000)) . int(rand(1000)) . int(rand(1000)) . int(rand(1000))) x 5000;
ASSERT( write_file("$root/FSWP_TEST_BLOCK", \$o) , 'write file - block');
ASSERT( $i = read_file("$root/FSWP_TEST_BLOCK") , 'read back');
ASSERT( ($i eq $o) , 'ensure data matches');

####################################################################
# appending to file, with gratuitious pause
$o = (int(rand(1000)) . int(rand(1000)) . int(rand(1000)) . int(rand(1000))) x 250;
ASSERT( append_file("$root/FSWP_TEST_APPEND", \$o) , 'append file - many times');
for (2..10) {
	append_file("$root/FSWP_TEST_APPEND", \$o);
}
sleep(1);
for (11..20) {
	append_file("$root/FSWP_TEST_APPEND", \$o);
}
ASSERT( ($i = read_file("$root/FSWP_TEST_APPEND")) , 'read back');
ASSERT( ($i eq ($o x 20)) , 'ensure data matches');

####################################################################
# Reading directories
@list = grep /^FSWP/, sort &read_dir($root);
DUMP(\@list);
ASSERT(EQUAL( \@list, [
  'FSWP_TEST',
  'FSWP_TEST_APPEND',
  'FSWP_TEST_BLOCK',
  'FSWP_TEST_LIST',
  'FSWP_TEST_REF',
]), "read_dir");

####################################################################
# test error conditions
ASSERT( DIED(sub  { read_file("$root/FSWP_Icon\r"); } ), 'bad chars' );
ASSERT( DIED(sub  { read_file("$root/FSWP_NONEXISTENT"); } ), 'doesnt exist' );

####################################################################
# cleanup
unlink("$root/FSWP_TEST", "$root/FSWP_TEST_LIST", "$root/FSWP_TEST_REF", "$root/FSWP_TEST_BLOCK", "$root/FSWP_TEST_APPEND") unless ($opt_s);

