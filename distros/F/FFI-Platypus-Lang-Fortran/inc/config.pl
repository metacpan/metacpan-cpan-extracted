use strict;
use warnings;
use FFI::Platypus 2.00;
use File::Which qw( which );
use ExtUtils::F77;
use File::chdir;
use File::ShareDir::Dist::Install qw( install_config_set );

unless(caller)
{
  *File::ShareDir::Dist::Install::install_dir = sub {
    'share';
  };
}

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

1;
