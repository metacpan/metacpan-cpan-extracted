package t::lib::Test;
use strict;
use warnings;
use parent 'Test::Builder::Module';

use Data::Dumper;
use Test::More;
use JSON::MaybeXS qw( decode_json );
use Path::Tiny    qw( path );

our @EXPORT= (
     @Test::More::EXPORT,
     qw(
        read_report
        get_coverage_from_report
        parse_fixture
     ),
);

sub import {
    unshift @INC, 't/lib';

    strict->import;
    warnings->import;

    goto &Test::Builder::Module::import;
}

sub read_report {
    my $path  = shift // '/tmp';
    my @files = glob("$path/QC_*");

    ok(@files == 1, "Report exists at $path")
        or return;

    my ($fname) =  @files;

    my $json = path($fname)->slurp
        or return;

    my $decoded = decode_json($json)
        or return;

    return $fname, $decoded;
}

sub get_coverage_from_report {
    my ($file, $report) = @_;

    my $lines = $report->{files}{$file};

    return $lines;
}

sub parse_fixture {
    my $file = shift;

    my @lines = path($file)->lines;

    my @expected =
        map  +($_->[0]),                         # linenos
        grep +($_->[1] =~ /YES/),                # look for lines marked with YES
        map  [ $_ + 1, $lines[$_] ], 0..$#lines; # enumerate

    my @present =
        map  +($_->[0]),                         # linenos
        grep +($_->[1] =~ /YES|NO/),             # look for lines marked with YES or NO
        map  [ $_ + 1, $lines[$_] ], 0..$#lines; # enumerate
    my %subs =
        map  {
            my ($name, $phase) = $_->[1] =~ m{\bSUB,([^,]+),([^,]*)\n$};

            ("$name,$_->[0]" => $phase);
        } grep +($_->[1] =~ /SUB,/),               # look for lines marked with SUB,
        map  [ $_ + 1, $lines[$_] ], 0..$#lines; # enumerate

    return {"covered" => \@expected, "present" => \@present, subs => \%subs};
}


1;
