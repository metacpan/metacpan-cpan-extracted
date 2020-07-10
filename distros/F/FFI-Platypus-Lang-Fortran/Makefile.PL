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
use FFI::Platypus 1.00;
use File::Which qw( which );
use ExtUtils::F77;
use File::ShareDir::Dist::Install qw( install_config_set );

{
  my $config = {
    runtime             => ExtUtils::F77::runtime(),
    trailing_underscore => ExtUtils::F77::trail_(),
    cflags              => ExtUtils::F77::cflags(),
    f77                 => ExtUtils::F77::compiler(),
  };

  unless(which($config->{f77}))
  {
    print "This distribution requires that you have a fortran compiler installed\n";
    exit;
  }

  # Just guessing...
  foreach my $compiler (qw( 90 95 ))
  {
    $config->{"f$compiler"} = $config->{f77};
    $config->{"f$compiler"} =~ s/77/$compiler/;
  }
  install_config_set 'FFI-Platypus-Lang-Fortran', f77 => $config;
}

{
  my %type;
  my $ffi = FFI::Platypus->new( api => 1 );

  foreach my $size (qw( 1 2 4 8 ))
  {
    my $bits = $size*8;
    $type{"integer_$size"}  = "sint$bits";
    $type{"unsigned_$size"} = "uint$bits";
    $type{"logical_$size"}  = "sint$bits";
  }

  # http://docs.oracle.com/cd/E19957-01/805-4939/z40007365fe9/index.html

  # should always be 32 bit... I believe, but use
  # the C int as a guide
  $type{'integer'} = 'sint' . $ffi->sizeof('int')*8;
  $type{'unsigned'} = 'uint' . $ffi->sizeof('int')*8;
  $type{'logical'} = 'sint' . $ffi->sizeof('int')*8;

  $type{byte} = 'sint8';
  $type{character} = 'uint8';

  $type{'double precision'} = $type{real_8} = 'double';
  $type{'real_4'} = $type{'real'} = 'float';

  $type{'complex'} = $type{'complex_8'} = 'complex' if eval { $ffi->type('complex'); 1 };
  $type{'double complex'} = $type{'complex_16'} = 'complex_double' if eval { $ffi->type('complex_double'); 1 };

  $type{'real_16'} = 'long double' if eval { $ffi->type('long double'); 1 };

  install_config_set 'FFI-Platypus-Lang-Fortran', type => \%type;
}

my %WriteMakefileArgs = (
  NAME               => 'FFI::Platypus::Lang::Fortran',
  DISTNAME           => 'FFI-Platypus-Lang-Fortran',
  AUTHOR             => "Graham Ollis <plicease\@cpan.org>",
  VERSION_FROM       => 'lib/FFI/Platypus/Lang/Fortran.pm',
  ABSTRACT_FROM      => 'lib/FFI/Platypus/Lang/Fortran.pm',
  LICENSE            => 'perl',
  MIN_PERL_VERSION   => '5.008004',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker'           => '6.64',
    'FFI::Platypus'                 => '1.00',
    'File::Which'                   => '0',
    'ExtUtils::F77'                 => '1.24',
    'File::ShareDir::Dist::Install' => '0.07',
  },
  BUILD_REQUIRES => {
    'File::ShareDir::Dist' => 0,
    'FFI::Build::MM'       => 0,
  },
  TEST_REQUIRES => {
  },
  PREREQ_PM => {
    'FFI::Platypus' => '1.00',
    'File::Which'   => '0',
    'FFI::Build'    => '1.00',
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      bugtracker => {
        web => 'https://github.com/PerlFFI/FFI-Platypus-Lang-Fortran/issues',
      },
      repository => {
        type => 'git',
        url => 'https://github.com/PerlFFI/FFI-Platypus-Lang-Fortran.git',
        web => 'https://github.com/PerlFFI/FFI-Platypus-Lang-Fortran',
      },
      x_IRC => 'irc://irc.perl.org/#native',
    },
    no_index => {
      directory => [ 'examples' ],
    },
  },
  clean => {
    FILES => join(' ', qq(
      *.bak
      examples/*.o
      examples/*.obj
      examples/*.so
      examples/*.dylib
      examples/*.bundle
      t/ffi/*.so
      t/ffi/*.dylib
      t/ffi/*.bundle
      t/ffi/_build
      FFI-Platypus-Lang-Fortran-*
      config.log
    ))
  },
);

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {

  my $pa = '';

  $pa .= "pure_all :: my_build\n\n";
  $pa .= "my_build:\n";
  $pa .= "\t\$(FULLPERL) inc/mymm-build.pl\n";

  $pa;
}
