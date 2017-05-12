use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'Geometry::AffineTransform',
	VERSION_FROM  => 'lib/Geometry/AffineTransform.pm', # finds $VERSION
	ABSTRACT_FROM => 'lib/Geometry/AffineTransform.pm', # retrieve abstract from module
	PREREQ_PM     => {
		'Test::Class' => 0.28,
		'Hash::Util'  => 0,
		'Math::Trig'  => 0,
	},
	AUTHOR        => 'Marc Liyanage <liyanage@cpan.org>',
	META_MERGE    => {
		'meta-spec' => { version => 2 },
		resources => {
 			repository => {
				type => 'git',
				url  => 'https://github.com/liyanage/perl-modules.git',
				web  => 'https://github.com/liyanage/perl-modules',
			},
		},
	},
);
