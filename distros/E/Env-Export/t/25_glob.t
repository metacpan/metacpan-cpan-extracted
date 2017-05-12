#!/usr/bin/perl

use strict;
use warnings;
use subs qw(sub_count);

use File::Spec;
use Test::More;

(my $vol, my $dir, undef) = File::Spec->splitpath(File::Spec->rel2abs($0));
require File::Spec->catpath($vol, $dir, 'sub_count.pl');

# TEST SCOPE: These tests exercise shell-style globbing pseudo-regexen

# The number of tests is not dependent on what is currently in %ENV, as we
# will be creating all our own key/value pairs for these tests
plan tests => 292;

# Record the list of all %ENV keys that are valid as identifiers
my @valid = sort grep(/^[A-Za-z_]\w*$/, keys %ENV);
my $prefix = 'AAAAA';
while (grep(/^$prefix/, @valid))
{
    # Keep bumping this up until there are no matching keys in %ENV
    $prefix++;
}

# Create a bunch of dummy %ENV entries
for (0 .. 255)
{
    $ENV{sprintf("$prefix%02X", $_)} = $_;
}

my $namespace = 'namespace0000';

# Set 1: AAAAA* should yield the same results as qr/AAAAA.*/
my @should_see = sort grep(/^$prefix.*/, keys %ENV);
my $code = <<"END_CODE";
package $namespace;
use Env::Export '$prefix*';
package main;
END_CODE

$code .= "is(${namespace}::$_(), \$ENV{$_}, '$prefix* glob, key=$_');\n"
    for (@should_see);

eval $code;
warn "eval fail: $@" if $@;
# Check the count of exported symbols
is(sub_count($namespace), scalar(@should_see),
   "Number of subs exported to first namespace");

# Set 2: AAAAA?0 should yield the same results as qr/AAAAA.0/
$namespace++;
@should_see = sort grep(/^$prefix.0/, keys %ENV);
$code = <<"END_CODE";
package $namespace;
use Env::Export '$prefix?0';
package main;
END_CODE

$code .= "is(${namespace}::$_(), \$ENV{$_}, '$prefix.0 glob, key=$_');\n"
    for (@should_see);

eval $code;
warn "eval fail: $@" if $@;
# Check the count of exported symbols
is(sub_count($namespace), scalar(@should_see),
   "Number of subs exported to second namespace");

# Set 3: AAAAA0?* should yield the same results as qr/AAAAA0.+/
$namespace++;
@should_see = sort grep(/^${prefix}0.+/, keys %ENV);
$code = <<"END_CODE";
package $namespace;
use Env::Export '${prefix}0?*';
package main;
END_CODE

$code .= "is(${namespace}::$_(), \$ENV{$_}, '$prefix.0 glob, key=$_');\n"
    for (@should_see);

eval $code;
warn "eval fail: $@" if $@;
# Check the count of exported symbols
is(sub_count($namespace), scalar(@should_see),
   "Number of subs exported to third namespace");

# Last test: make sure a glob pattern doesn't sneak an invalid sub in
# Re-compute $prefix so that nothing we added shows up, either
@valid = sort grep(/^[A-Za-z_]\w*$/, keys %ENV);
while (grep(/^$prefix/, @valid))
{
    $prefix++;
}
$ENV{"$prefix***"} = '+++';
$namespace++;
eval "package $namespace; use Env::Export '$prefix*';";
warn "eval fail: $@" if $@;
is(sub_count($namespace), 0, 'Glob will not export invalid subs');

exit;
