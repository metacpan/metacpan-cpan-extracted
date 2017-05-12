#!/usr/bin/perl
use strict;
use warnings;

# generate_tests.plx
#
# Grab a sampling of vocab diffs from Snowball project and generate test pairs
# in both the default encoding and UTF-8.

use Encode;
use Getopt::Long qw( GetOptions );
use File::Spec::Functions qw( catfile catdir );

# --snowdir must be the "snowball_all" directory
my $snowdir;
GetOptions( 'snowdir=s' => \$snowdir );
die "Usage: perl devel/generate_tests.plx --snowdir=SNOWDIR"
    unless defined $snowdir;

my %languages = (
    en => 'english',
    da => 'danish',
    de => 'german',
    es => 'spanish',
    fi => 'finnish',
    fr => 'french',
    it => 'italian',
    nl => 'dutch',
    hu => 'hungarian',
    no => 'norwegian',
    pt => 'portuguese',
    ro => 'romanian',
    ru => 'russian',
    sv => 'swedish',
    tr => 'turkish',
);

# Create t/test_voc if it doesn't exist already.
my $test_voc_dir = catdir( 't', 'test_voc' );
if ( !-d $test_voc_dir ) {
    mkdir $test_voc_dir or die $!;
}

while ( my ( $iso, $language ) = each %languages ) {
    # Only create new files, don't mod existing ones.
    my $utf8_filepath    = catfile( $test_voc_dir, "$iso.utf8" );
    my $default_filepath = catfile( $test_voc_dir, "$iso.default_enc" );
    next if ( -e $utf8_filepath and -e $default_filepath );
    my ( $utf8_fh, $default_fh );
    if ( 1 or !-e $utf8_filepath ) {
        open( $utf8_fh, '>:utf8', $utf8_filepath ) or die $!;
    }
    if ( 1 or !-e $default_filepath ) {
        if ( $iso ne 'tr' ) {    # Turkish is UTF-8 only.
            open( $default_fh, '>', $default_filepath ) or die $!;
        }
    }

    # Suck in all the lines of the relevant vocabulary example files.
    my $voc_filepath
        = catfile( $snowdir, 'algorithms', $language, 'voc.txt' );
    my $answers_filepath
        = catfile( $snowdir, 'algorithms', $language, 'output.txt' );

    open( my $voc_fh,     '<:utf8', $voc_filepath )     or die $!;
    open( my $answers_fh, '<:utf8', $answers_filepath ) or die $!;
    my @voc     = <$voc_fh>;
    my @answers = <$answers_fh>;

    # These files are in UTF-8, so we'll have to encode tests for the default
    # encoding.
    my $default_enc
        = $iso eq 'ru' ? 'koi8-r'
        : $iso eq 'ro' ? 'iso-8859-2'
        : $iso eq 'tr' ? undef
        :                'iso-8859-1';

    # Grab 100 random pairs.
    for ( 1 .. 100 ) {
        my $tick = int( rand @voc );
        my $voc  = $voc[$tick];
        chomp $voc;
        my $pair = "$voc $answers[$tick]";
        if ($default_fh) {
            my $encoded = encode( $default_enc, $pair );
            print $default_fh $encoded or die $!;
        }
        if ($utf8_fh) {
            print $utf8_fh $pair or die $!;
        }
    }
}

