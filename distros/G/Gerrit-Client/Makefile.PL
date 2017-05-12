use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME               => 'Gerrit::Client',
  AUTHOR             => q{Rohan McGovern <rohan@mcgovern.id.au>},
  VERSION_FROM       => 'lib/Gerrit/Client.pm',
  ABSTRACT_FROM      => 'lib/Gerrit/Client.pm',
  LICENSE            => 'lgpl_2_1',
  PL_FILES           => {},
  MIN_PERL_VERSION   => 5.010,
  CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
  BUILD_REQUIRES     => {
    'Archive::Zip'    => 0,
    'Dir::Self'       => 0,
    'Env::Path'       => 0,
    'File::chdir'     => 0,
    'LWP'             => 0,
    'List::MoreUtils' => 0,
    'Sub::Override'   => 0,
    'Test::More'      => 0,
    'Test::Warn'      => 0,
    'autodie'         => 0,
  },
  PREREQ_PM => {
    'AnyEvent'         => 0,
    'AnyEvent::HTTP'   => 0,
    'Capture::Tiny'    => 0,
    'Data::Alias'      => 0,
    'File::chdir'      => 0,
    'JSON'             => 0,
    'Params::Validate' => 0,
    'URI'              => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'Gerrit-Client-*' },
  ( MM->can('signature_target') ? ( SIGN => 1 ) : () ),
);
