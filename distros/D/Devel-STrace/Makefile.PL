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

print "\nConfiguring Devel::STrace...\n
";

use Config;
my @executables = ();
foreach my $src ('plstrace') {
	open  SCRIPT,       ">$src.pl" or die "Can't create $src.pl: $!";
	open  SOURCE,        "$src.source" or die "Missing $src.source";
	chmod 0755,          "$src.pl";
	push @executables, "$src.pl";
	print SCRIPT "$Config{startperl}\n";
	print SCRIPT $_
		while (<SOURCE>);

	close SCRIPT;
	close SOURCE;
}

my %prereqs = (
	'IPC::Mmap' => '0.11',
	'Devel::RingBuffer' => '0.31'
);

my %opts = (
	'NAME' => 'Devel::STrace',
	'VERSION_FROM' => 'lib/Devel/STrace.pm',
	'dist'         => {
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf'
    },
    'EXE_FILES'    => \@executables,
	'AUTHOR'       => 'Dean Arnold, Presicient Corp. (darnold@presicient.com)',
	'ABSTRACT'     => 'strace for Perl scripts',
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
