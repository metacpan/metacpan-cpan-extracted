#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use JCAMP::DX;
use Text::Diff;

use Test::More tests => 1;

my $input_dir = 'inputs';
my $output_dir = 'outputs';

opendir my $dir, $input_dir || die "Cannot open directory: $!";
my @inputs = sort grep { /\.jcamp$/ } readdir $dir;
closedir $dir;

my $ntests = @inputs;
my $n_ok = 0;
for my $case (@inputs) {
    my $input_file = "$input_dir/$case";

    open( my $inp, $input_file );
    my $input = join '', <$inp>;
    close $inp;

    my $file_contents;
    JCAMP::DX->new_from_file( $input_file,
                              { store_file => \$file_contents } );
    if( $input eq $file_contents ) {
        $n_ok++;
    } else {
        print STDERR "\n$input_file: FAILED:\n";
        print STDERR diff( \$file_contents, \$input );
    }
}

ok( $n_ok == $ntests );
