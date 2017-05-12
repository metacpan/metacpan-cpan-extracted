#!perl
# htmltoframe.pl
#  Don't even THINK of using the FrameMaker::FromHTML module unless your HTML is
# pristine pure or at least you have HTML-tidy available
# to clean it up as shown below.   Even then, keep your eye on the
# FrameMaker console when you open any mif file.... The translations
# are make need debugging for a good while yet.

use base 'FrameMaker::FromHTML';
use File::Basename;
use strict;

my ($infile, $outfile);
$infile = shift;
($outfile = $infile) =~ s/\.htm[l]*$/\.mif/;



my $usage=<<EOUSAGEMSG;

                $0 -- An HTML to FrameMaker MIF file converter

                 Perl script
                 using FRAMEMAKER::FromHTML module (Peter Martin)

                In Windows, requires  tidy.exe
                Elsewhere, requires HTML-Tidy executable.
                Usage:   htmltofm  HTMLfile.html [miffile]
                where:   [miffile] is optional (default is HTMLfile.mif)

EOUSAGEMSG
die $usage unless($infile);

my ($inname, $inpath, $insuffix) = fileparse($infile, ("\.htm", ".html"));
my $tempfile=$inpath."new_".$inname.$insuffix;

if (!(-e "tidy_config.txt"))
  {
    my $config_details=<<EOCONFIG;
indent: auto
indent-spaces: 2
wrap: 69
markup: yes
clean: yes
output-xml: no
input-xml: no
show-warnings: no
numeric-entities: yes
quote-marks: yes
quote-nbsp: no
quote-ampersand: yes
break-before-br: no
uppercase-tags: no
uppercase-attributes: no
char-encoding: latin1
error-file: tidy-errors.txt
EOCONFIG
    open(CFG, "> tidy_config.txt") or die "Couldn't write config file: $!\n";
    print CFG $config_details;
    close(CFG);
  }
print "Tidying up HTML file...\n";
system ("tidy -config  tidy_config.txt -f tidy-errors.txt $infile > $tempfile");

print "Tidied.  Now converting...\n";
my $p = FrameMaker::FromHTML->new($outfile) ;
die "No parsing object created ?\n" unless defined $p;
defined $p->parse_file("$tempfile") or die "Parsing failed on $tempfile: $!\n";
print "MIF conversion done.\n";
# for Win32 launch
exec ("start $outfile") if($^O =~ /MSWin32/);;