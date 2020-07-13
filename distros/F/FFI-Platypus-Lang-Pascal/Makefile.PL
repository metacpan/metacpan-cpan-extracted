use strict;
use warnings;
use lib 'inc';

BEGIN {
  unless(eval q{ use 5.008004; 1 }) {
    print "Perl 5.008004 or better required\n";
    exit;
  }
}

use ExtUtils::MakeMaker 6.64;

use lib 'lib';
use FFI::Build::MM;
use File::Which qw( which );

unless(which('fpc'))
{
  print "Unable to find Free Pascal.  Please make sure it is in the PATH.\n";
  print "You should still be able to use pre-compiled Free Pascal dynamic libs.\n";
}

my %WriteMakefileArgs = (
  NAME               => 'FFI::Platypus::Lang::Pascal',
  DISTNAME           => 'FFI-Platypus-Lang-Pascal',
  AUTHOR             => "Graham Ollis <plicease\@cpan.org>",
  VERSION_FROM       => 'lib/FFI/Platypus/Lang/Pascal.pm',
  ABSTRACT_FROM      => 'lib/FFI/Platypus/Lang/Pascal.pm',
  LICENSE            => 'perl',
  MIN_PERL_VERSION   => '5.008004',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64',
    'FFI::Build::MM' => 1.00,
    'File::Which'    => 0,
    'Path::Tiny'     => 0,
    'File::chdir'    => 0,
  },
  BUILD_REQUIRES => {
    # ...
  },
  TEST_REQUIRES => {
    'Test2::V0' => 0,
  },
  PREREQ_PM => {
    'perl',               => '5.008001',
    'FFI::Platypus'       => '0.19',
    'FFI::ExtractSymbols' => 0,
    'File::Which'         => 0,
    'Path::Tiny'          => 0,
    'File::chdir'         => 0,
    'FFI::CheckLib'       => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      bugtracker => {
        web => 'https://github.com/PerlFFI/FFI-Platypus-Lang-Pascal/issues',
      },
      repository => {
        type => 'git',
        url => 'https://github.com/PerlFFI/FFI-Platypus-Lang-Pascal.git',
        web => 'https://github.com/PerlFFI/FFI-Platypus-Lang-Pascal',
      },
      x_IRC => 'irc://irc.perl.org/#native',
    },
    no_index => {
      directory => [ 'examples' ],
    },
  },
  clean => {
    FILES => join(' ',
      '*.bak',
      '*.ppu',
      'examples/*.o',
      'examples/*.so',
      'examples/*.ppu',
      'examples/*.ppl',
      't/ffi/*.o',
      't/ffi/*.so',
      't/ffi/*.ppu',
      't/ffi/*.ppl',
      'FFI-Platypus-Lang-Pascal-*',
    )
  },
);

my $fbmm = FFI::Build::MM->new;

WriteMakefile($fbmm->mm_args(%WriteMakefileArgs));

sub MY::postamble {
  $fbmm->mm_postamble;
}
