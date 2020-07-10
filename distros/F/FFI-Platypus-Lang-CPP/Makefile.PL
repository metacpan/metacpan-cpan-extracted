use strict;
use warnings;

BEGIN {
  unless(eval q{ use 5.008004; 1 }) {
    print "Perl 5.008004 or better required\n";
    exit;
  }
}

use 5.008004;
use ExtUtils::MakeMaker 6.64;
use ExtUtils::CBuilder;
use File::Which qw( which );
use FFI::Build::MM 1.00;

unless(ExtUtils::CBuilder->new->have_cplusplus)
{
  print "This dist requires a C++ compiler\n";
  exit;
}

my $fbmm = FFI::Build::MM->new;

my %WriteMakefileArgs = (
  NAME               => 'FFI::Platypus::Lang::CPP',
  DISTNAME           => 'FFI-Platypus-Lang-CPP',
  AUTHOR             => "Graham Ollis <plicease\@cpan.org>",
  VERSION_FROM       => 'lib/FFI/Platypus/Lang/CPP.pm',
  ABSTRACT_FROM      => 'lib/FFI/Platypus/Lang/CPP.pm',
  LICENSE            => 'perl',
  MIN_PERL_VERSION   => '5.008001',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64',
    'File::Which'         => 0,
    'FFI::Build::MM'      => '1.00',
  },
  BUILD_REQUIRES => {
    # ...
  },
  PREREQ_PM => {
    'FFI::Platypus'       => '1.00',
    'FFI::ExtractSymbols' => '0',
  },
  TEST_REQUIRES => {
    'FFI::CheckLib' => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      bugtracker => {
        web => 'https://github.com/PerlFFI/FFI-Platypus-Lang-Rust/issues',
      },
      repository => {
        type => 'git',
        url => 'https://github.com/PerlFFI/FFI-Platypus-Lang-Rust.git',
        web => 'https://github.com/PerlFFI/FFI-Platypus-Lang-Rust',
      },
      x_IRC => 'irc://irc.perl.org/#native',
    },
    no_index => {
      directory => [ 'examples' ],
    },
  },
  clean => {
    FILES => join(' ', qw(
      *.bak
      examples/*.o
      examples/*.obj
      examples/*.so
      examples/*.bundle
      examples/*.dylib
      examples/*.dll
      t/ffi/_build
      t/ffi/*.so
      t/ffi/*.bundle
      t/ffi/*.dll
      t/ffi/*.dylib
      fbx.json
    )),
  }
);

$WriteMakefileArgs{PM}->{'FFI::Platypus::Lang::CPP::Demangle::XS'} = 0
  unless which('c++filt');

WriteMakefile($fbmm->mm_args(%WriteMakefileArgs));

sub MY::postamble {
  $fbmm->mm_postamble;
}

