#!/usr/bin/perl

# This script sets copyright information
# in image files that use EXIF

use warnings;
use strict;
use Image::ExifTool;
use Getopt::Flex;
use Time::Format;
use File::Find::Rule;

my $name = '';
my $camera = '';
my $manufacturer = '';
my $recurse = 0;
my $verbose = 0;
my @formats = qw(jpg);
my $help = 0;

my $cfg = {
    'usage' => 'imgcopyrighter.pl [OPTIONS...] [FILES...]',
    'desc' => 'Use this to batch process copyrighting of image files',
};

my $sp = {
    'name|n' => {
        'var' => \$name,
        'type' => 'Str',
        'desc' => 'The individuals name to enter for the copyright',
    },
    'camera|model|c' => {
        'var' => \$camera,
        'type' => 'Str',
        'desc' => 'The camera model to enter',
    },
    'manufacturer|manuf|man|make|m' => {
        'var' => \$manufacturer,
        'type' => 'Str',
        'desc' => 'The camera manufacturer to enter',
    },
    'recurse|r' => {
        'var' => \$recurse,
        'type' => 'Bool',
        'desc' => 'Recursively process any subdirectories',
    },
    'verbose|v' => {
        'var' => \$verbose,
        'type' => 'Bool',
        'desc' => 'Talk loudly while processing',
    },
    'format|f' => {
        'var' => \@formats,
        'type' => 'ArrayRef[Str]',
        'desc' => 'Valid extensions for files to process',
    },
    'help|h|?' => {
        'var' => \$help,
        'type' => 'Bool',
        'desc' => 'Print out this help',
    }
};

my $op = Getopt::Flex->new({config => $cfg, spec => $sp});
if(!$op->getopts()) {
    print "**ERROR**: ", $op->error();
    print $op->get_help();
    exit(1);
}
           
if($help) {
    print $op->get_help();
    exit(0);
}
  
if($verbose) {
    print "Using the following values:\n";
    print "   name=$name\n";
    print "   camera=$camera\n";
    print "   manufacturer=$manufacturer\n";
    print "   recurse=$recurse\n";
    print "   verbose=$verbose\n";
    print "   format(s)=", join(',',@formats), "\n";
}

if(!($name || $camera || $manufacturer)) {
    die "must set one of name, camera, or manufacturer!\n";
}
           
@formats = grep { /\S/ } split(/,/,join(',',@formats));
my $s = '('.join('|',@formats).')$';
my $re = qr/$s/i;

my @dirs = grep { -d } @ARGV;
my @files = grep { !-d } @ARGV;

if($recurse) {
    push(@files, File::Find::Rule->file()->name( $re )->in( @dirs ));
} else {
    push(@files, File::Find::Rule->file()->maxdepth(1)->name( $re )->in( @dirs ));
}

my $et = new Image::ExifTool;

if($verbose) {
    print "Going to process ", ($#files + 1), " file", ($#files == 0 ? "" : "s"), "\n";
}

foreach my $file (@files) {
    if($verbose) {
        print "processing $file:";
        print "\n   setting Copyright to \"Copyright $name $time{'yyyy', time}\"" if($name);
        print "\n   setting Model to \"$camera\"" if($camera);
        print "\n   setting Make to \"$manufacturer\"" if($manufacturer);
        print "\n";
    }
    $et->SetNewValue("Copyright", "Copyright $name $time{'yyyy', time}") if($name);
    $et->SetNewValue("Model", $camera) if($camera);
    $et->SetNewValue("Make", $manufacturer) if($manufacturer);
    $et->WriteInfo($file);
}
