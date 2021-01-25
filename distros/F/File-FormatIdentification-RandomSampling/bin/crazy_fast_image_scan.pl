#!/usr/bin/perl
# (c) 2020 by Andreas Romeyke
# licensed via GPL v3.0 or later
use strict;
use warnings FATAL => 'all';
use Getopt::Long;
use feature qw(say);
use Pod::Usage;
use IO::Handle;
use Fcntl qw(:seek);
use Path::Tiny;
use Math::Random qw(random_uniform_integer);
use Time::Progress;
use Time::HiRes qw(time);
use File::FormatIdentification::RandomSampling;
use File::FormatIdentification::RandomSampling::Model;
#use File::FormatIdentification::Pronom;
use List::Util qw(all);

# PODNAME: crazy-fast-image-scan
# ABSTRACT tool to detect content of media using random sampling 




STDOUT->autoflush(1);
# guarantee, that output will be utf-8
binmode(STDOUT, ":encoding(UTF-8)");


sub calc_null_probability {
    my $filesize = shift;
    my $sectorsize=shift;
    my $sectorcount = shift;
    # totalsector-sectors
    # -------------------  = p_1
    # totalsectors
    my $totalsectors = $filesize/$sectorsize;
    my $probability= ($totalsectors - $sectorcount) / $totalsectors;
    return $probability;
}

sub calc_probability_of_not_finding_data {
    my $imagesize = shift; # size of image
    my $sectorsize=shift;
    my $sectorcount = shift;
    my $probsize = shift; # chance to find file of size $probsize
    if ($probsize > $imagesize) { return; }
    # totalsector-sectors
    # -------------------  = p_1
    # totalsectors

    my $totalsectors = $imagesize/$sectorsize;
    my $probsectors = int(0.5 + $probsize/$sectorsize);
    my $probability= ($totalsectors - $sectorcount) / $totalsectors;
    #say "p_1 = $prob";
    for (my $i = 1; $i<=$probsectors; $i++) {
        my $den = $totalsectors - ($i -1);
        my $nom = $den - $sectorcount;
        $probability *= $nom / $den ;
        #say "p_$i = $prob ($nom / $den)";
    }
    return $probability;
}

my $help;
my $image;
my $filesize;
my $percentage = 0.01; # 1%
my $sectorsize = 512; # 1 Sector = 512 Bytes
my $pronom_droid_file;
my $pronom;
GetOptions(
    "help|?"       => \$help,
    "image=s"      => \$image,
    "percentage=f" => \$percentage,
    "sectorsize=i" => \$sectorsize,
    "pronomfile=s" => \$pronom_droid_file,
) or pod2usage(2);
pod2usage(1) if $help;

if (! defined $image or length($image) < 1) {
    die "image missed!";
}

if (!defined $filesize) {
    $filesize = -s $image;
    if ((!defined $filesize) or ($filesize == 0) ) {
        my $fh = path($image)->openr();
        my $seeksize = sysseek $fh, 0, SEEK_END;
        sysseek $fh, 0, SEEK_SET;
        $filesize = $seeksize;
    }
}

#if (defined $pronom_droid_file) {
#    $pronom = File::FormatIdentification::Pronom->new(
#        "droid_signature_filename" => $pronom_droid_file
#    );
#}
my $sectors = int($filesize / $sectorsize)+1;
if ($sectors > 2147483561) {
    die "too many sectors ($sectors, restart it with smaller percentage value (current: $percentage)";
}
if (int($sectors * $percentage) == 0) {
    die "too few sectors ($sectors, restart it with higher percentage value (current: $percentage)";
}
# prepare random sample positions
my @seek_positions = sort map {$_*$sectorsize} random_uniform_integer(int($sectors * $percentage), 0, $sectors);
my $count_seeks = scalar @seek_positions;
say "Scanning Image $image with size $filesize, checking $count_seeks sectors";

my $buffer;
my %stats;
$stats{start} = time();
my $progressbar=Time::Progress->new(min => 0, max => $count_seeks, smoothing => 1);
open( my $fh, "<", $image) or die "could not open image $image for reading, $!";
binmode($fh);
my $pos = 0;
my $ff = File::FormatIdentification::RandomSampling->new();
foreach my $seek (@seek_positions) {
    seek $fh, $seek, SEEK_SET;
    read $fh, $buffer, $sectorsize;
    my $type = $ff->calc_type($buffer);
    my $histogram = $ff->calc_histogram();
    my $model = File::FormatIdentification::RandomSampling::Model->new();
    my $mimetype = $model->calc_mimetype( $histogram );
    $stats{mimetype}->{$mimetype}++;
#    if (defined $pronom) {
#        foreach my $internalid ( $pronom->get_all_internal_ids() ) {
#            my $sig = $pronom->get_signature_id_by_internal_id($internalid);
#            if (!defined $sig) {next;}
#            my $puid = $pronom->get_puid_by_signature_id($sig);
#            my $name = $pronom->get_name_by_signature_id($sig);
#            my $quality = $pronom->get_qualities_by_internal_id($internalid);
#            my @regexes = $pronom->get_regular_expressions_by_internal_id($internalid);
#            if ( all {$buffer =~ m/$_/saa} @regexes ) {
#                $stats{puid}->{$puid}->{name} = $name;
#                $stats{puid}->{$puid}->{count}++;
#            }
#        }
#    }
    $stats{type}->{$type}++;
    print $progressbar->report("scanning %40b ETA: %E     \r", $pos++);
}
$stats{end} = time();
$stats{duration} = $stats{end} - $stats{start};
$stats{throughput} = ($count_seeks * $sectorsize) / ($stats{duration});
$stats{fullscan_duration} = $filesize  / $stats{throughput};
$stats{speedup} = 0.5 + $stats{fullscan_duration} / $stats{duration}  ;
say "";
# report
say "Estimate, that the image\n\t'$image'\nhas percent of following data types:";
foreach my $type (sort {
    $stats{type}->{$b} <=> $stats{type}->{$a}
}keys %{$stats{type}}) {
    my $value = 100 / $count_seeks * $stats{type}->{$type};
    # TODO: calc probability or Unsureness
    printf("\t%4.1f%% %s\n", $value, $type);
}
say "The next mimetype estimation is experimental and needs further work:";
foreach my $type (sort {
    $stats{mimetype}->{$b} <=> $stats{mimetype}->{$a}
} keys %{ $stats{mimetype} }) {
    my $value = 100 / $count_seeks * $stats{mimetype}->{$type};
    printf("\t%4.1f%% %s\n", $value, $type);
}
my $thr_string = $stats{throughput};
if ($stats{throughput} > (1024 * 1024 * 1024)) { $thr_string=sprintf("%0.1f GByte/s",$stats{throughput}/(1024*1024*1024));}
elsif ($stats{throughput} > (1024 * 1024)) { $thr_string=sprintf("%0.1f MByte/s",$stats{throughput}/(1024*1024));}
elsif ($stats{throughput} > (1024)) { $thr_string=sprintf("%0.1f kByte/s",$stats{throughput}/(1024));}
else {$thr_string=sprintf("%0.1f Byte/s",$stats{throughput});}
printf "Scanned in %f s, real throughput %s, speedup %dx\n", $stats{duration}, $thr_string, $stats{speedup};
foreach my $probsize (qw(1000000000 1000000 1000)) {
    my $notfind_prob =  calc_probability_of_not_finding_data($filesize, $sectorsize, $count_seeks, $probsize);
    if (defined $notfind_prob) {
        my $prob = 100 * (1 - $notfind_prob);
        printf "There was a %0.1f%% chance to find data files with size less than %d Bytes\n", $prob, $probsize;
    }
}
printf "The probability to pick one empty sector of %d  Bytes is: p_1=%0.4f\n", $sectorsize, calc_null_probability($filesize, $sectorsize, $count_seeks);
#use Data::Printer; p( $stats{puid});
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

crazy-fast-image-scan

=head1 VERSION

version 0.006

=head1 SYNOPSIS

   perl ./crazy_fast_image_scan.pl --image=/dev/sda

This scans the device /dev/sda.

   perl ./crazy_fast_image_scan.pl --percent=0.00001 --image=cdrom.img

This scans the image using 0.00001 (0.001 %) bytes of the image.

=head1 DESCRIPTION

This script scans devices or images very fast using random sampling and reports what kind of content could be found.
This is useful to decide whch image or media could have stuff of interest and allows to prioritize the order of further
examinations.

The script uses random sampling and is based on ideas by Simson Garfinkel in a
talk http://simson.net/ref/2014/2014-02-21_RPI_Forensics_Innovation.pdf

It calculates the sectors of a given image or device, select n sector samples, seek to the sector positions and read it.

Feel free to contact me if you find errors in statistical calculations or if you have any suggestions to improve
the script,

=head1 NAME

crazy fast image scan

=head1 AUTHORS

Andreas Romeyke

=head1 COPYRIGHT AND LICENSE

Script is distributed under GPL 3.0, see LICENSE.txt for details.

=head1 AUTHOR

Andreas Romeyke <pause@andreas-romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Andreas Romeyke.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
