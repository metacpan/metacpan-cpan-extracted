#!/usr/bin/env perl
#===============================================================================
#
#         FILE: pronom_statistics.pl
#
#        USAGE: ./pronom_statistics.pl
#
#  DESCRIPTION: perl ./pronom_statistics.pl <DROIDSIGNATURE-FILE>
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Andreas Romeyke,
#      CREATED: 28.08.2018 14:26:43
#     REVISION: ---
#===============================================================================
# PODNAME: pronom_statistics.pl
use strict;
use warnings 'FATAL';
use utf8;
use feature qw(say);
use Carp;
use Getopt::Long;
use Term::ProgressBar;
use File::FormatIdentification::Pronom;

################################################################################
# main
################################################################################
my $csv_file;
my $verbose;
my $progress_flag = 1;
GetOptions (
    "csvfile=s" => \$csv_file,
    "verbose" => \$verbose,
    "progress!" => \$progress_flag,
    "help" => sub {
        say "$0 [--csvfile=FILE] [--verbose] [--noprogress] droid_signature_filename1 [.. droid_signature_filenameN]";
        say "$0 --help ";
        say "";
        say "--csvfile=FILE .............. creates a CSV file to store statistics";
        say "--verbose ................... enables more verbose output in standard report";
        say "--noprogress ................ disables progress bar";
        say "droid_signature_filename..... DROID signature files (container files not supported yet)";
    }
) or croak "wrong option, try '$0 --help'";
if ((defined $csv_file) && (-e $csv_file)) {
    croak "CSV file '$csv_file' already exist";
}
say "using ",scalar @ARGV," signature files";
my $progress = Term::ProgressBar->new( $#ARGV );
for (my $idx=0; $idx <= $#ARGV; $idx++) {
    my $pronomfile = $ARGV[$idx];
    if ( !defined $pronomfile ) {
        say "you need at least a pronom signature file";
    }
    my $pronom = File::FormatIdentification::Pronom->new(
        "droid_signature_filename" => $pronomfile
    );
    if (defined $csv_file) {
        $pronom->print_csv_statistics( $csv_file );
    } else {
        $pronom->print_statistics( $verbose );
    }
    if ($progress_flag) {
        $progress->update($idx);
    }
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

pronom_statistics.pl

=head1 VERSION

version 0.06

=head1 AUTHOR

Andreas Romeyke <pause@andreas-romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
