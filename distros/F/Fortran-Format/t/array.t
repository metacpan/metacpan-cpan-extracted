#!/home/ivan/bin/perl

use strict;
use warnings;
use Fortran::Format;
#use Data::Dumper;
use Test::More;

my $fname_in  = "read_arr_tests.txt";
my $fname_out = "read_arr_tests_out.txt";
open IN,  "<", $fname_in  or die "couldn't open $fname_in: $!\n";
open OUT, "<", $fname_out or die "couldn't open $fname_out: $!\n";

my (@input, @output);
{ local $/ = "\n\n"; @input = <IN>; @output = <OUT>; }

plan tests => scalar @input;

for (1 .. @input) {
    my ($in, $out) = (shift @input, shift @output);
    my ($type, $format_in, $input) = 
        $in =~ /^(.)FORMAT\((.*)\) *\n(.*)/s or die;
    my ($type_out, $format_out, $expected_output) = 
        $out =~ /^.FORMAT.*?\n 
               (.)FORMAT\((.*)\)\ *\n(.*)/xs or die;
    my $fi = Fortran::Format->new($format_in);
    my $fo = Fortran::Format->new($format_out);

    #print "in:\n$input\nexpected:\n$expected_output\n";
    #my $fh = IO::Scalar->new(\$input);
    #open my $fh, '<', \$input;
    my $arr;
    if ($type eq 'A') {
        ($arr) = $fi->read($input, 4);
    } elsif ($type eq 'M') {
        ($arr) = $fi->read($input, [2,2]);
    } else {
        die "unknown test type\n";
    }
    #print Dumper $arr;
    my $output = $fo->write($arr) . "\n";
    #print "got:\n$output\n";
    is($output, $expected_output, $format_in);
    #last;
}
