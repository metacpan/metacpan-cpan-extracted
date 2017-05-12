#!/usr/bin/perl

# This script resizes image files

use warnings;
use strict;
use Imager;
use Getopt::Flex;
use File::Find::Rule;
use Image::ExifTool;

my $max_dim = 1024;
my $recurse = 0;
my @formats = qw(jpg);
my $verbose = 0;
my $help = 0;

my $cfg = {
    'usage' => 'imgresize.pl [OPTIONS...] [FILES...]',
    'desc' => 'Batch resizing from the command line',
};

my $sp = {
    'recurse|r' => {
        'var' => \$recurse,
        'type' => 'Bool',
        'desc' => 'Recursively process any subdirectories',
    },
    'format|f' => {
        'var' => \@formats,
        'type' => 'ArrayRef[Str]',
        'desc' => 'Valid extensions for files to process',
    },
    'verbose|v' => {
        'var' => \$verbose,
        'type' => 'Bool',
        'desc' => 'Talk loudly while processing',
    },
    'help|h|?' => {
        'var' => \$help,
        'type' => 'Bool',
        'desc' => 'Print out this help',
    },
    'size|s' => {
        'var' => \$max_dim,
        'type' => 'Int',
        'desc' => 'Maximum size of any side',
    },
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

@formats = grep { /\S/ } split(/,/,join(',',@formats));
my $s = '('.join('|',@formats).')$';
my $re = qr/$s/i;

if($verbose) {
    print "Using the following values:\n";
    print "   size=$max_dim\n";
    print "   recurse=$recurse\n";
    print "   verbose=$verbose\n";
    print "   format(s)=", join(',',@formats), "\n";
}

my @dirs = grep { -d } @ARGV;
my @files = grep { -f } @ARGV;

if($recurse) {
    push(@files, File::Find::Rule->file()->name( $re )->in( @dirs ));
} else {
    push(@files, File::Find::Rule->file()->maxdepth(1)->name( $re )->in( @dirs ));
}

if($verbose) {
    print "found ", ($#files + 1), " file", ($#files == 0 ? "" : "s"), "\n";
}

foreach my $file (@files) {
    my $et = new Image::ExifTool;
    $et->ExtractInfo($file, {});
    my $info = $et->SetNewValuesFromFile($file);
    
    my $img = Imager->new(file=>$file) or die Imager->errstr();
    if($img->getwidth() > $img->getheight()) {
        $img = $img->scale(xpixels=>$max_dim, qtype => 'mixing');
    } else {
        $img = $img->scale(ypixels=>$max_dim, qtype => 'mixing');
    }

    if($verbose) {
        print "processing $file:\n";
        print "   resizing to: x: ", $img->getwidth(), " y: ", $img->getheight(), "\n";
    }
    
    $img->write(file => $file) or die "Cannot write: ", $img->errstr;
    
    $et->WriteInfo($file) or die "Cannot set EXIF: ", $et->GetValue('Error');
}
