#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use JCAMP::DX;
use Text::Diff;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 1;

use Test::More tests => 1;

my $input_dir = 'inputs';
my $output_dir = 'outputs';

opendir my $dir, $input_dir || die "Cannot open directory: $!";
my @inputs = sort grep { /\.jcamp$/ } readdir $dir;
closedir $dir;

my $ntests = @inputs;
my $n_ok = 0;
for my $case (@inputs) {
    $case =~ /^(.+)\.jcamp$/;
    my $input_file = "$input_dir/$case";
    my $output_file = "$output_dir/$1.out";

    open( my $out, $output_file );
    my $output = join '', <$out>;
    close $out;

    my $input = Dumper( JCAMP::DX->new_from_file( $input_file ) );
    if( $input eq $output ) {
        $n_ok++;
    } else {
        print STDERR "\n$input_file: FAILED:\n";
        print STDERR diff( \$output, \$input );
    }
}

ok( $n_ok == $ntests );
