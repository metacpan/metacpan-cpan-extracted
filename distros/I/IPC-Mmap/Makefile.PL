# -*- perl -*-

require 5.008;

use strict;
require ExtUtils::MakeMaker;

BEGIN {
#
#	only install module for platform
#
	my $skip = ($^O eq 'MSWin32') ?
		"lib/IPC/Mmap/POSIX.pm\n" :
		"lib/IPC/Mmap/Win32.pm\n";

	print FH $skip and
	close FH
		if open(FH, '>MANIFEST.SKIP');
}

eval { require 5.008; } or die << 'EOD';
#######################################
#
#	This module requires a minimum Perl version of 5.8.0
#	Please upgrade!
#
#######################################
EOD

print "\nConfiguring IPC::Mmap...\n
";

my %prereqs = ();

$prereqs{'Win32::MMF'} = '0.09'
	if ($^O eq 'MSWin32');

my %opts = (
	'NAME' => 'IPC::Mmap',
	'VERSION_FROM' => 'lib/IPC/Mmap.pm',
	'dist'         => {
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf'
    },
	'AUTHOR'       => 'Dean Arnold, Presicient Corp. (darnold@presicient.com)',
	'ABSTRACT'     => 'minimal unified mmap for POSIX and Win32',
	'PREREQ_PM'    => \%prereqs
);

my $ok = 1;
$ok &= CheckModule($_, $prereqs{$_})
	foreach (keys %prereqs);

print "
Missing modules are available from CPAN (search.cpan.org).

"
	unless $ok;

ExtUtils::MakeMaker::WriteMakefile(%opts);

sub CheckModule ($$;$) {
    my($module, $version, $package) = @_;
    $package ||= $module;
    $prereqs{$module} = $version || 0;
    if ($version) {
		print "Checking for $package, $version or later ... ";
		eval "use $module $version";
		if ($@) {
		    print("\nYou don't have the $package package",
			  " version $version or later, installed.\n");
		    return 0;
		}
    } else {
		print "Checking for $package ... ";
		eval "use $module";
		if ($@) {
		    print("\nYou don't have the $package package installed.\n");
		    return 0;
		}
    }
    print "ok\n";
    return 1;
}
