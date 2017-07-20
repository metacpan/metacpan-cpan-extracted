#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

package My::P1;
use Log::ger;

package main;

use File::Temp qw(tempdir);
use Log::ger::Output;

sub read_file {
    my $filename = shift;
    open my $fh, "<", $filename or die;
    local $/;
    return scalar <$fh>;
}

my $dir = tempdir(CLEANUP => 0);
#diag "tempdir=$dir";

subtest "opt:path" => sub {
    Log::ger::Output->set('SimpleFile' => path=>"$dir/f1");
    My::P1::log_warn("warn1");
    My::P1::log_debug("debug");
    is(read_file("$dir/f1"), "warn1\n");
};

subtest "appends" => sub {
    open my $fh, ">", "$dir/f0"; print $fh "before\n"; close $fh;
    Log::ger::Output->set('SimpleFile' => path=>"$dir/f0");
    My::P1::log_warn("warn1");
    My::P1::log_debug("debug");
    is(read_file("$dir/f0"), "before\nwarn1\n");
};

subtest "opt:handle" => sub {
    open my $fh, ">>", "$dir/f2" or die;
    Log::ger::Output->set('SimpleFile' => handle => $fh);
    My::P1::log_warn("warn1");
    My::P1::log_debug("debug");
    is(read_file("$dir/f2"), "warn1\n");
};

subtest "no file/path given -> dies" => sub {
    dies_ok { Log::ger::Output->set('SimpleFile') };
};


done_testing;
