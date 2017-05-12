
require 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Devel::FileProfile',
	DISTNAME	=> 'Devel-FileProfile',
	VERSION_FROM	=> 'lib/Devel/FileProfile.pm',
	dist		=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
	PREREQ_PM	=> {
		'Time::HiRes'	=> 0,
	},
);

package MY;

sub postamble {
    <<'END_OF_POSTAMBLE';

pm_to_blib: README

README: lib/Devel/FileProfile.pm
	pod2text  lib/Devel/FileProfile.pm >README

END_OF_POSTAMBLE
}
