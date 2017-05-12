use strict;
use warnings;

#	This script is run by ./Build to copy files from where
#	ExtUtils::MakeMaker expects them to be to where Module::Build
#	expects them to be. It will go away if I can figure out how to
#	make ExtUtils::MakeMaker work with Module::Build's file
#	locations (rather than insisting on putting Pasteboard.xs in
#	blib), or how to tell Module::Build to move the files (and not
#	do something extra to them once it moves them).
#
#	It expects the output file names as arguments, and expects the
#	input files to be in the top-level distribution directory under
#	the same name as the output files.

use File::Basename;

foreach my $of (@ARGV) {
    my $if = basename ($of);
    local $/ = undef;
    open (my $ih, '<', $if) or die "Unable to open $if: $!\n";
    open (my $oh, '>', $of) or die "Unable to open $of: $!\n";
    print "$if -> $of\n";
    print $oh scalar <$ih>;
    close $ih;
    close $oh;
}
