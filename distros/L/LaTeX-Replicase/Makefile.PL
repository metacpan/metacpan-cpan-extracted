use 5.010000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'LaTeX::Replicase',
    VERSION_FROM      => 'lib/LaTeX/Replicase.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    MIN_PERL_VERSION  => '5.010000',
    ABSTRACT_FROM     => 'lib/LaTeX/Replicase.pm', # retrieve abstract from module
    AUTHOR            => 'Alessandro Gorohovski <an.gorohovski@gmail.com>',
    LICENSE           => 'perl', #Value must be from legacy list of licenses here http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    PREREQ_PM         => {
      'File::Basename'     => '2.00',
      'File::Path'         => '2.18',
      'File::Compare'      => '1.00',
      'Carp'               => '0',
      'Test::More'         => '0.98', # for tests only
      'Test::More::UTF8'   => '0.05', # for tests only
      'Test::Pod'          => '1.22', # for tests only
      'Test::Exception'    => '0.43', # for tests only
      'Test::Output'       => '1.01', # for tests only
      'Storable'           => '2.19', # for tests only
      'Data::Dumper'       => '2.183', # for tests only
    },
    test => {
      TESTS => 't/*.t t/*/*.t',
    },
    META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url  => 'git://github.com/AlessandroGorohovski/LaTeX-Replicase.git',
          web  => 'https://github.com/AlessandroGorohovski/LaTeX-Replicase',
        },
        bugtracker => {
          web => 'https://github.com/AlessandroGorohovski/LaTeX-Replicase/issues'
        },
      },
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/LaTeX/Replicase.pm',
       AUTHOR         => 'Alessandro Gorohovski <an.gorohovski@gmail.com>') : ()),
);

