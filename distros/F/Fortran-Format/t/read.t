#!/home/ivan/bin/perl

use strict;
use warnings;
use blib;
use Fortran::Format;
use Data::Dumper;
use Test::More;

#simple_test(@ARGV);

my $fname  = "read_tests_out.txt";
open IN,  "<", $fname  or die "couldn't open $fname: $!\n";

#$Fortran::Format::Writer::DEBUG = 1;

my (@input);
{ local $/ = "\n\n"; @input = <IN>; }

plan tests => scalar @input;

for my $rec (@input) {
    my ($format_in, $input, $format_out, $expected_output) = 
        $rec =~ /^.FORMAT\((.*)\)\ *\n 
                 (.*)\n
                  .FORMAT\((.*)\)\ *\n(.*)/xs or die "wrong format?";
    my $fi = Fortran::Format->new($format_in);
    my $fo = Fortran::Format->new($format_out);

    #print "in:\n$input\nexpected:\n$expected_output\n";
    my $val;
    if ($format_in =~ /A/) {
        ($val) = $fi->read($input, "1A40");
    } else {
        ($val) = $fi->read($input, 1);
    }
    #print Dumper $val;
    my $output = $fo->write($val) . "\n";
    #print "got:\n$output\n";
    is($output, $expected_output, $format_in);
}

sub simple_test {
    my ($fmt, $str) = @_;
    my ($val) = Fortran::Format->new($fmt)->read($str, 1);
    print "val = '$val'\n";
    exit;
}
