package mymm;

use strict;
use warnings;
use ExtUtils::MakeMaker qw( WriteMakefile );
use ExtUtils::CppGuess;
#use Data::Dumper;

sub myWriteMakefile
{
  my %args = @_;
  $args{XSMULTI} = 1;
  delete $args{PM};

  my $guess = ExtUtils::CppGuess->new;
  my %cpp = $guess->makemaker_options;

  #warn Data::Dumper::Dumper(\%cpp);

  %args = ( %args, %cpp );

  $args{XSBUILD} = {
    xs => {
      'lib/FFI/Platypus/Lang/CPP/Demangle/XS' => {
        INC    => "-I.",
        OBJECT => 'lib/FFI/Platypus/Lang/CPP/Demangle/XS$(OBJ_EXT) demangle$(OBJ_EXT)',
      },
    },
  };
  
  WriteMakefile(%args);
}

1;
