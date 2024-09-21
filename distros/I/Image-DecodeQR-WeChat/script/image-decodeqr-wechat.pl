#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = '2.2';

use Image::DecodeQR::WeChat qw/:all/;
use Getopt::Long;
use Data::Roundtrip qw/perl2dump/;

my %params;

if( ! Getopt::Long::GetOptions(
	'input=s' => sub { $params{$_[0]} = $_[1] },
	'modelsdir=s' => sub { $params{$_[0]} = $_[1] },
	'outbase=s' => sub { $params{$_[0]} = $_[1] },
	'verbosity=s' => sub { $params{$_[0]} = $_[1] },
	'graphicaldisplayresult' => sub { $params{$_[0]} = 1 },
	'dumpqrimagestofile' => sub  { $params{$_[0]} = 1 },
	'help|h' => sub { usage($0); exit(0) } 
) ){ print STDERR usage($0) . "\n$0 : something wrong with command line parameters.\n"; exit(1); }

my $ret = Image::DecodeQR::WeChat::detect_and_decode_qr(\%params);
die Data::Roundtrip::perl2dump(\%params)."\ncall to Image::DecodeQR::WeChat::detect_and_decode_qr() has failed for above parameters."
	unless $ret and scalar @{$ret->[0]};

#my ($payloads, $bboxes) = @$ret;

print "\n$0 : results (payloads and their bounding boxes):\n".Data::Roundtrip::perl2dump($ret);

sub	usage {
	print "Usage : $0 <options>\nwhere options are:\n"
."  --input F : the filename of the input image which supposedly contains QR codes to be detected.\n"
."  --modelsdir M : optionally use your own models contained in this directory instead of the ones this program was shipped with.\n"
."  --outbase O : basename for all output files (if any, depending on whether --dumpqrimagestofile is on).\n"
."  --verbosity L : verbosity level, 0:mute, 1:C code, 10:C+XS code.\n"
."  --graphicaldisplayresult : display a graphical window with input image and QR codes outlined. Using --dumpqrimagestofile and specifying --outbase, images and payloads and bounding boxes will be saved to files, if you do not have graphical interface.\n"
."  --dumpqrimagestofile : it has effect only of --outbase was specified. Payloads, Bounding Boxes and images of each QR-code detected will be saved in separate files.\n"
."\n\nThe STDOUT output contains a payload and its matching bounding box (of 4 coordinates).\n"
."\n\nAndreas Hadjiprocopis (bliako\@cpan.org) 2022\n\n"
}
