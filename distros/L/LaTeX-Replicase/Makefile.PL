use 5.010000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

# install_share 'share';
install_share  module => 'LaTeX::Replicase' => 'share';

WriteMakefile(
    NAME              => 'LaTeX::Replicase',
    VERSION_FROM      => 'lib/LaTeX/Replicase.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    MIN_PERL_VERSION  => '5.010000',
    ABSTRACT_FROM     => 'lib/LaTeX/Replicase.pm', # retrieve abstract from module
    AUTHOR            => 'Alessandro Gorohovski <an.gorohovski@gmail.com>',
    LICENSE           => 'perl_5', #Value must be from legacy list of licenses here http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker'     => 0,
      'File::ShareDir::Install' => '0.14',
    },
    PREREQ_PM         => {
      'File::ShareDir::Install' => '0.14',
      'File::ShareDir'     => '1.10',
      'File::Basename'     => '2.00',
      'File::Path'         => '2.18',
      'File::Compare'      => '1.00',
      'Carp'               => '0',
      'Storable'           => '2.00',
      'Data::Dumper'       => '2.183',
#      'File::Remove'       => '1.42',
#      'Module::Install'    => '1.19',
#      'Module::Build'      => '0.29',
#      'Module::ScanDeps'   => '1.09',
    },
    TEST_REQUIRES      => { # for tests only
      'Test::More'          => '0.96',
      'Test::More::UTF8'   => '0.05',
      'Test::File::ShareDir' => '1.001000',
      'Test::Pod'          => '1.22',
      'Test::Exception'    => '0.43',
      'Test::Output'       => '1.01',
      'Test::Warn'         => '0.30',
      'Text::Hyphen'       => '0.12',
      'Text::Hyphen::RU'   => '0.12',
      'Storable'           => '2.00',
      'Data::Dumper'       => '2.183',
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

# Mandatory integration of rules into the Makefile
package MY;
use File::ShareDir::Install qw(postamble);

1;
