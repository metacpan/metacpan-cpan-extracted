use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Digest::HighwayHash',
	VERSION_FROM      => 'lib/Digest/HighwayHash.pm',
	ABSTRACT_FROM     => 'lib/Digest/HighwayHash.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Math::Int64 0/,
	},
	INC               => '-I. -Ihighwayhash/c',
	OBJECT            => '$(O_FILES)',
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=digest-highwayhash.git',
		},
	}
);
