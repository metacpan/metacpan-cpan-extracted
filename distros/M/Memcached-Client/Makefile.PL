
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'All-singing, all-dancing Perl client for Memcached',
  'AUTHOR' => 'Michael Alan Dorman <mdorman@ironicdesign.com>',
  'BUILD_REQUIRES' => {
    'IO::Socket::INET' => '0',
    'JSON::XS' => '0',
    'POSIX' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Memcached-Client',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Memcached::Client',
  'PREREQ_PM' => {
    'AnyEvent' => '0',
    'AnyEvent::Handle' => '0',
    'Compress::Zlib' => '0',
    'Config' => '0',
    'Data::Dumper' => '0',
    'Exporter' => '0',
    'IO::File' => '0',
    'JSON' => '0',
    'Module::Load' => '0',
    'Scalar::Util' => '0',
    'Storable' => '0',
    'String::CRC32' => '0',
    'bytes' => '0',
    'constant' => '0'
  },
  'VERSION' => '2.01',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



