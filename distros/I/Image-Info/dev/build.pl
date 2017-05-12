#!/usr/bin/perl -w

use strict;
use File::Spec;
use Getopt::Long;

#############################################################################
#############################################################################
# Write the Info.pm file with system specific code from Info.pm.tmpl:

# This is run by the developer, and there is no need to rerun this at build
# time.

BEGIN
  {
  chdir 'dev' if -d 'dev';
  }

# Sort order for image formats. This is just used to have more common
# (where the "more common" is currently a subjective guess by the
# author) image formats in front of the magic list.
#
# The list was setup like following: the popular image formats in the
# web (jpeg, png, gif) at the front. Microsoft formats like bmp and
# ico are probably in wider use than X11 formats like xpm and xbm. svg
# is quite different from other formats in this list as it is a vector
# format, not a raster format.
my @format_priority = qw(JPEG PNG GIF TIFF BMP ICO PPM XPM XBM SVG);
my %format_to_priority = do {
    my $priority = 0;
    map { ($_ => $priority++) } reverse @format_priority;
};

my $updir = File::Spec->updir();
my $tmpl = File::Spec->catfile("Info.pm.tmpl");
my $info_pm = File::Spec->catfile($updir,"lib", "Image", "Info.pm");
my $idir = File::Spec->catdir($updir,"lib", "Image", "Info");

GetOptions("o=s" => \$info_pm)
    or die "Usage: $0 [-o output]";

opendir(DIR, $idir) || die "Can't opendir $idir: $!";
my (@code,@desc, $desc);
for my $file (sort readdir(DIR)) {
    next unless $file =~ /^([a-zA-Z]\w*)\.pm$/;
    my $format = $1;

    open(F, File::Spec->catfile($idir, $file)) || die "Can't open '$idir/$file': $!";
    my @magic;
    my $no_magic;
    my @desc;
    while (<F>) {
	if (/^=begin\s+register\b/ ... /^=end\s+register\b/) {
	    next if /^=(begin|end)/;
	    if (/^MAGIC:\s+(.*)/) {
		push(@magic, $1);
		next;
	    }
	    elsif (/^NO MAGIC:\s+true/) {
		$no_magic = 1;
		next;
	    }
	    push(@desc, $_);
	}
    }
    if (!$no_magic) {
	die "Missing magic for $format" unless @magic;
	for (@magic) {
	    if (m:^/:) {
		push(@code, [$format_to_priority{$format}||0, qq(return "$format" if $_;)]);
	    }
	    else {
		push(@code, [$format_to_priority{$format}||0, qq(return "$format" if \$_ eq $_;)]);
	    }
	}
    }

    # trim
    shift(@desc) while @desc && $desc[0]  =~ /^\s*$/;
    pop(@desc)   while @desc && $desc[-1] =~ /^\s*$/;

    $desc .= "\n=item $format\n" unless @desc && $desc[0] =~ /^=item/;
    $desc .= "\n" . join("", @desc);

}
closedir(DIR);

my $code = "sub determine_file_format
{
   local(\$_) = \@_;
   " . join("\n   ", map { $_->[1] } sort { $b->[0] <=> $a->[0] } @code) . "
   return undef;
}
";

# Copy template to top level module with substitutions
open(TMPL, $tmpl) || die "Can't open $tmpl: $!";
open(INFO, ">$info_pm") || die "Can't create $info_pm: $!";

while (<TMPL>) {
    if (/^%%DETERMINE_FILE_FORMAT%%/) {
        $_ = $code;
    }
    elsif (/^%%FORMAT_DESC%%/) {
       $_ = $desc;
    }
    print INFO $_;
}
close(INFO);
close(TMPL);

