use 5.005000;
use ExtUtils::MakeMaker;
use strict;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %test_requires = (
	'Test::Mock::LWP::Dispatch' => 0.02,
	'File::Temp' => 0
);

my $not_installed_test_modules = '';
while (my ($module, $ver) = each %test_requires) {
	
	eval "use $module $ver";
	if ($@) {
		$not_installed_test_modules .= "\t$module $ver\n";
	}
}

if ($not_installed_test_modules) {
	my $choose = prompt(
		"We need few optional additional modules to test this package on your system:\n".
		$not_installed_test_modules.
		"If you'll choose `n' this tests will be skipped.\n".
		"Append this modules to installation queue?",
		"y"
	);
	
	if ($choose =~ /n/) {
		%test_requires = ();
	}
}

$test_requires{'Test::More'} = 0.88;

WriteMakefile(
	NAME              => 'LWP::UserAgent::Cached',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/LWP/UserAgent/Cached.pm', # finds $VERSION
	PREREQ_PM         => { 'LWP::UserAgent' => 0 }, # e.g., Module::Name => 1.1
	BUILD_REQUIRES    => \%test_requires,
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => { 
		resources => {repository => 'https://github.com/olegwtf/p5-LWP-UserAgent-Cached'},
	},
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	(ABSTRACT_FROM  => 'lib/LWP/UserAgent/Cached.pm', # retrieve abstract from module
	AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
