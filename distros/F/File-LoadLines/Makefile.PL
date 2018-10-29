use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::LoadLines',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/File/LoadLines.pm',
    ABSTRACT_FROM       => 'lib/File/LoadLines.pm',
    LICENSE		=> 'perl_5',
    PL_FILES            => {},
    MIN_PERL_VERSION	=> '5.010001',
    PREREQ_PM => {
        'Test::More' => 0,
    },
    META_MERGE => {
      license      => "perl_5",
      resources    => {
        repository => {
          type => 'git',
	   web  => 'https://github.com/sciurius/perl-File-LoadLines',
	   url  => 'https://github.com/sciurius/perl-File-LoadLines.git',
	 },
	 bugtracker => "https://github.com/sciurius/perl-File-LoadLines/issues",
	},
	'meta-spec' => {
	  version => '2',
	  url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
	},
    }
);
