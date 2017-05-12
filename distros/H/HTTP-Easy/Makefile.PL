use 5.008008;
use ExtUtils::MakeMaker;

$ENV{AUTHOR} and require CPAN::Meta;

WriteMakefile(
	NAME              => 'HTTP::Easy',
	VERSION_FROM      => 'lib/HTTP/Easy.pm', # finds $VERSION
	ABSTRACT_FROM     => 'lib/HTTP/Easy.pm', # retrieve abstract from module
	PREREQ_PM         => {
	},
	AUTHOR            => 'Mons Anderson <mons@cpan.org>',
);
