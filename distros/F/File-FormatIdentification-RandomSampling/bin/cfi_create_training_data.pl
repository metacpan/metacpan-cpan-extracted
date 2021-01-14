#!/usr/bin/perl
# reads all the files given on command line,
# calcs histogram and detect mimetype
# stores a line in CSV-file
# used to execute a learner to train decision-trees
# example call:
# find ~/git/format-corpus -print0| xargs -0 perl -I lib cfi_create_training_data.pl --csv_file=test.csv
#
# (c) 2020 by Andreas Romeyke
# licensed via GPL v3.0 or later
# PODNAME: cfi_create_training_data.pl
use strict;
use warnings FATAL => 'all';
use feature qw(say);
use lib '../lib';
use Pod::Usage;
use IO::Handle;
use Path::Tiny;
use Time::Progress;
use Time::HiRes qw(time);
use Getopt::Long;
use MIME::Types;
use File::FormatIdentification::RandomSampling;

STDOUT->autoflush(1);
# guarantee, that output will be utf-8
binmode(STDOUT, ":encoding(UTF-8)");

sub print_histogram {
    my $fh = shift;
    my $category = shift;
    my $histogram = shift;
    foreach my $sk (qw(onegram bigram)) {
        foreach my $ngram (@{$histogram->{$sk}}) {
            print $fh "$ngram,";
        }
    }
    say $fh $category;
    return;
}

#### MAIN

my $csv_file;
my $help;
my $sectorsize = 512; # 1 Sector = 512 Bytes
GetOptions(
    "help|?"     => \$help,
    "csv_file=s" => \$csv_file,
) or pod2usage(2);
pod2usage(1) if $help;
if (!defined $csv_file) {
    die "you must define csv_file!";
}

open(my $fhout, ">>", $csv_file) or die "could not open csv_file '$csv_file' for appending, $!";
say $fhout "onegram1, onegram2, onegram3, onegram4, onegram5, onegram6, onegram7, onegram8, bigram1, bigram2, bigram3, bigram4, bigram5, bigram6, bigram7, bigram8, mimetype";
close($fhout);
foreach my $image (@ARGV) {
    my $types = MIME::Types->new;
    my $mime = $types->mimeTypeOf($image);

    my $category = "unknown";
    if (defined $mime) {
        $category = $mime->simplified();
    }
    my $rs = File::FormatIdentification::RandomSampling->new();
    open(my $fh, "<", $image) or die "could not open image $image for reading, $!";
    binmode($fh);
    my $buffer;
    while (read $fh, $buffer, $sectorsize) {
        $rs->update_bytegram($buffer);
    }
    close $fh;
    my $hist = $rs->calc_histogram();
    open(my $fhout, ">>", $csv_file) or die "could not open csv_file '$csv_file' for appending, $!";
    print_histogram($fhout, $category, $hist);
    close($fhout);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

cfi_create_training_data.pl

=head1 VERSION

version 0.005

=head1 AUTHOR

Andreas Romeyke <pause@andreas-romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Andreas Romeyke.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
