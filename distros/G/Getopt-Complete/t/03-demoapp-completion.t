#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin;

local $ENV{PATH} = $FindBin::Bin . ':' . $ENV{PATH};
my $path = 'demoapp';
plan tests => 12;

ok(-e $FindBin::Bin . '/' . $path, "found the demo program ($path)");
ok(test_completion("$path model build ") > 0, 'results for valid sub-command');
ok(test_completion("$path model buil") > 0, 'results for valid partial sub-command');
ok(test_completion("$path projectx ") == 0, 'no results for bad sub-command');
ok(test_completion("$path project list --filter name=foo ") > 0, 'results for valid option-space-argument');
ok(test_completion("$path project list --filter=name=foo ") > 0, 'results for valid option-equals-argument');
ok(test_completion("$path model --help foo ") == 0, 'no results for invalid argument');
ok(test_completion("$path model --help foo") == 0, 'no results for non-argument option');
ok(test_completion("$path project list --filter name=foo") == 0, 'no results for option argument');
ok(test_completion("$path project list --fooba") == 0, 'no results for unknown option');
ok(test_completion("$path project list --fooba $FindBin::Bin") > 0, 'file completion for unknown option');
ok(test_completion("$path project list $FindBin::Bin") > 0, 'file completion for bare args');

sub test_completion {
    my $line = shift;
    my @args = split(' ', $line);
    my $COMP_CWORD = $#args;
    if($line =~ m/\s$/) { $COMP_CWORD++; } #actually want to complete a new word
    my $command = $args[0];
    my @results = split("\n", `COMP_CWORD=$COMP_CWORD $command $line`);
    print "Found " . scalar(@results) . " fresults for '$line': " . join(', ', @results) . "\n";
    return scalar(@results);
}
