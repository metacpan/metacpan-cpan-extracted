#!perl

use lib 'lib';
use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok( 'Getopt::Declare' ); }

# The two '?' confused extract_codeblock and led to an infinite loop in the
# usage_string() function. Bug fixed by using extract_bracketed() instead.

my $spec = <<'EOCMDS';
[pvtype: who /x?/]
<error>	 Error
{ print "Error?\n" }
EOCMDS

ok my $args = Getopt::Declare->new($spec);

ok my $got_usage = $args->usage_string, 'don\'t get stuck in a loop';

my $expected_usage = quotemeta( q{
Options:

<error>  Error
} );

ok $got_usage =~ m/$expected_usage/;

