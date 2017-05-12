#!/usr/bin/env perl

use strict;
use warnings;

use Linux::PipeMagic qw/ systee syssplice /;
use File::Temp qw/ tempdir /;
use File::Slurp qw/ read_file /;
use Test::More;
my $dir = tempdir(CLEANUP => 1);

my $TEST_SAMPLE = "hallo world\n";

{
    open(my $fh, ">", "$dir/master") or die $!;
    print $fh $TEST_SAMPLE;
    close $fh;
}


open(my $fh_in, "<", "$dir/master") or die $!;
open(my $fh_out, ">", "$dir/copy") or die $!;
pipe(my $pipe1_read, my $pipe1_write) or die $!;
pipe(my $pipe2_read, my $pipe2_write) or die $!;

my $read_from_pipe;

while ((my $read = syssplice($fh_in, $pipe1_write, length($TEST_SAMPLE), 0)) > 0) {
    is($read, length($TEST_SAMPLE));
    is(systee($pipe1_read, $pipe2_write, $read, 0), $read) or die $!;
    is(syssplice($pipe1_read, $fh_out, $read, 0), $read) or die $!;
    sysread($pipe2_read, $read_from_pipe, $read);
}
close $fh_in;
close $fh_out;
close $pipe1_read;
close $pipe1_write;
close $pipe2_read;
close $pipe2_write;

my $from_copy  = read_file("$dir/copy");
ok length $from_copy;
ok length $read_from_pipe;

is($from_copy, $read_from_pipe);

done_testing();

