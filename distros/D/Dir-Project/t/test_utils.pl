# DESCRIPTION: Perl ExtUtils: Common routines required by package tests
#
# Copyright 2000-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use IO::File;
use Cwd;
use strict;
use vars qw($PERL $Dist);

BEGIN { $Dist = getcwd(); }
mkdir 'test_dir',0777;

$PERL = "$^X '-I$Dist/blib/arch' '-I$Dist/blib/lib'";

if (!$ENV{HARNESS_ACTIVE}) {
    use lib '.';
    use lib '..';
    use lib "$Dist/blib/lib";
    use lib "$Dist/blib/arch";
}

sub test_setup_area {
    mkdir				'test_dir/prefix',0777;
    mkdir				'test_dir/prefix/bin',0777;
    symlink "${Dist}/project_dir",	'test_dir/prefix/bin/project_dir';
    symlink "${Dist}/project_bin",	'test_dir/prefix/bin/project_bin';
    symlink "project_bin",		'test_dir/prefix/bin/project_which';
    symlink  "project_bin",		'test_dir/prefix/bin/testprog';
    _projrun("testprog",		'test_dir/prefix/bin/testrun');
    mkdir				'test_dir/prefix/lib',0777;
    symlink "${Dist}/project_dir.mk",	'test_dir/prefix/lib/project_dir.mk';
    mkdir				'test_dir/checkout',0777;
    mkdir				'test_dir/checkout/bin',0777;
    mkdir				'test_dir/checkout/Project_Root',0777;
    symlink "${Dist}/t/30_project_bin.pl",'test_dir/checkout/bin/testprog';
    symlink 'checkout',			'test_dir/project';
    $ENV{DIRPROJECT_PREFIX} = "${Dist}/test_dir/prefix";
    $ENV{DIRPROJECT_PATH} = "project/bin";
    $ENV{DIRPROJECT_PROJECTDIREXE} = "${PERL} $ENV{DIRPROJECT_PREFIX}/bin/project_dir";
}

sub _projrun {
    my $torun = shift;
    my $filename = shift;
    my $fh = IO::File->new (">$filename") or die "%Error: $! writing $filename,";
    (my $shebang = $PERL) =~ s/\'//g;
    print $fh "#!${shebang}\n";
    print $fh "exec '${Dist}/project_bin','--project_bin-run','$torun',\@ARGV;\n";
    $fh->close();
    chmod 0777, $filename;
}

######################################################################

sub run_system {
    # Run a system command, check errors
    my $command = shift;
    print "\t$command\n";
    system "$command";
    my $status = $?;
    ($status == 0) or die "%Error: Command Failed $command, $status, stopped";
}

sub wholefile {
    my $file = shift;
    my $fh = IO::File->new ($file) or die "%Error: $! $file";
    my $wholefile = join('',$fh->getlines());
    $fh->close();
    return $wholefile;
}

sub files_identical {
    my $fn1 = shift;
    my $fn2 = shift;
    my $f1 = IO::File->new ($fn1) or die "%Error: $! $fn1,";
    my $f2 = IO::File->new ($fn2) or die "%Error: $! $fn2,";
    my @l1 = $f1->getlines();
    my @l2 = $f2->getlines();
    my $nl = $#l1;  $nl = $#l2 if ($#l2 > $nl);
    for (my $l=0; $l<=$nl; $l++) {
	if (($l1[$l]||"") ne ($l2[$l]||"")) {
	    warn ("%Warning: Line ".($l+1)." mismatches; $fn1 != $fn2\n"
		  ."F1: ".($l1[$l]||"*EOF*\n")
		  ."F2: ".($l2[$l]||"*EOF*\n"));
	    return 0;
	}
    }
    return 1;
}

1;
