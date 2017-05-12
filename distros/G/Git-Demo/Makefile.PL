use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Git::Demo',
    AUTHOR              => q{Robin Clarke <rcl@cpan.org>},
    VERSION_FROM        => 'lib/Git/Demo.pm',
    ABSTRACT_FROM       => 'lib/Git/Demo.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
		'File::Basename' 		=> 2.78,
		'File::Copy'			=> 2.18,
		'File::HomeDir' 		=> 0.93,
		'File::Spec::Functions' => 3.33,
		'File::Temp' 			=> 0.22,
		'File::Util'            => 3.27,
		'Getopt::Long' 			=> 2.38,
		'Git::Repository'		=> 1.14,
		'IO::File'				=> 1.25,
		'Log::Log4perl' 		=> 1.31,
        'Test::More' 			=> 0,
		'YAML::Any'  			=> 0.72,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Git-Demo-*' },
);
