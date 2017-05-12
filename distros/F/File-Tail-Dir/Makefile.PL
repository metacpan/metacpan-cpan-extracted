use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::Tail::Dir',
    AUTHOR              => 'Jon Schutz <jon at jschutz.net>',
    VERSION_FROM        => 'lib/File/Tail/Dir.pm',
    ABSTRACT_FROM       => 'lib/File/Tail/Dir.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Cwd' => 0,
	'Digest::MD5' => 0,
	'File::ChangeNotify' => 0,
	'File::Spec' => 0,
	'File::Temp' => 0,
	'Moose' => 0,
	'Moose::Util::TypeConstraints' => 0,
        'Test::More' => 0,
	'YAML::Any' => 0,
	'Time::HiRes' => 0,
	'Config' => 0,
	'POSIX' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Tail-Dir-*' },
);
