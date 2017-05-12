#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: gm.t,v 1.9 2008/07/23 18:16:57 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use FindBin;

use GraphViz::Makefile;

BEGIN {
    if (!eval q{
	use Test::More;
	use File::Temp;
	1;
    }) {
	print "1..0 # skip: no Test::More and/or File::Temp modules\n";
	exit;
    }
}

my @makefile_tests = (["$FindBin::RealBin/../Makefile", "all"],
		      ["$FindBin::RealBin/Make-nosubst", "model"],
		      ["$FindBin::RealBin/Make-subst", "model"],
		     );
plan tests => 1 + @makefile_tests * 3;

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }

SKIP: {
    skip("tkgvizmakefile test only with BATCH=0 mode", 1) if $ENV{BATCH};
    system("$^X", "-Mblib", "blib/script/tkgvizmakefile", "-reversed", "-prefix", "test-");
    pass("Run tkgvizmakefile ...");
}

for my $def (@makefile_tests) {
    my($makefile, $target) = @$def;
    my $gm = GraphViz::Makefile->new(undef, $makefile);
    isa_ok($gm, "GraphViz::Makefile");
    $gm->generate($target);

    my $png = eval { $gm->GraphViz->as_png };
 SKIP: {
	skip("Cannot create png file: $@", 2)
	    if !$png;

	my($fh, $filename) = File::Temp::tempfile(SUFFIX => ".png",
					      UNLINK => 1);
	print $fh $gm->GraphViz->as_png;
	close $fh;

	ok(-s $filename, "Non-empty png file for makefile $makefile");

	skip("Display png file only with BATCH=0 mode", 1) if $ENV{BATCH};
	skip("ImageMagick/display not available", 1) if !is_in_path("display");

	system("display", $filename);
	pass("Displayed...");
    }
}

######################################################################
# REPO BEGIN
# REPO NAME file_name_is_absolute /home/e/eserte/work/srezic-repository 
# REPO MD5 89d0fdf16d11771f0f6e82c7d0ebf3a8

=head2 file_name_is_absolute($file)

=for category File

Return true, if supplied file name is absolute. This is only necessary
for older perls where File::Spec is not part of the system.

=cut

BEGIN {
    if (eval { require File::Spec; defined &File::Spec::file_name_is_absolute }) {
	*file_name_is_absolute = \&File::Spec::file_name_is_absolute;
    } else {
	*file_name_is_absolute = sub {
	    my $file = shift;
	    my $r;
	    if ($^O eq 'MSWin32') {
		$r = ($file =~ m;^([a-z]:(/|\\)|\\\\|//);i);
	    } else {
		$r = ($file =~ m|^/|);
	    }
	    $r;
	};
    }
}
# REPO END

# REPO BEGIN
# REPO NAME is_in_path /home/e/eserte/work/srezic-repository 
# REPO MD5 81c0124cc2f424c6acc9713c27b9a484

=head2 is_in_path($prog)

=for category File

Return the pathname of $prog, if the program is in the PATH, or undef
otherwise.

DEPENDENCY: file_name_is_absolute

=cut

sub is_in_path {
    my($prog) = @_;
    return $prog if (file_name_is_absolute($prog) and -f $prog and -x $prog);
    require Config;
    my $sep = $Config::Config{'path_sep'} || ':';
    foreach (split(/$sep/o, $ENV{PATH})) {
	if ($^O eq 'MSWin32') {
	    # maybe use $ENV{PATHEXT} like maybe_command in ExtUtils/MM_Win32.pm?
	    return "$_\\$prog"
		if (-x "$_\\$prog.bat" ||
		    -x "$_\\$prog.com" ||
		    -x "$_\\$prog.exe" ||
		    -x "$_\\$prog.cmd");
	} else {
	    return "$_/$prog" if (-x "$_/$prog" && !-d "$_/$prog");
	}
    }
    undef;
}
# REPO END

