# -*- perl -*-

require 5.008;

use strict;
require ExtUtils::MakeMaker;

eval { require 5.008; } or die << 'EOD';
#######################################
#
#	This module requires a minimum Perl version of 5.8.0
#	Please upgrade!
#
#######################################
EOD

print "
Configuring Devel::RingBuffer...

";

my %prereqs = ( 'IPC::Mmap' => '0.11' );

my %opts = (
	'NAME' => 'Devel::RingBuffer',
	'VERSION_FROM' => 'lib/Devel/RingBuffer.pm',
	'dist'         => {
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf'
    },
	'AUTHOR'       => 'Dean Arnold, Presicient Corp. (darnold@presicient.com)',
	'ABSTRACT'     => 'Memory mapped ring buffer for Perl script debuggers/diagnostics',
	'PREREQ_PM'    => \%prereqs,
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
