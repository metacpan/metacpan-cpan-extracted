package Guess;

use strict;
use warnings;
BEGIN{ use Config; }
use ExtUtils::CppGuess;

# Repackage results from ExtUtils::CppGuess into a form that is most useful
# to Inline::CPP's Makefile.PL.

sub new {
  my( $class, $config ) = @_;
  return bless { config => $config }, $class;
}


sub guess_compiler {
  my $self = shift;
  local %Config::Config = %{$self->{config}}; # Use our own configuration.
  
  my( $cc_guess, $libs_guess, $guesser, %configuration );

  $guesser = ExtUtils::CppGuess->new;
  %configuration = $guesser->module_build_options;
  if( $guesser->is_gcc ) {
    $cc_guess = 'g++';
  }
  elsif ( $guesser->is_msvc ) {
    $cc_guess = 'cl';
  }

  $cc_guess .= $configuration{extra_compiler_flags};
  $libs_guess = $configuration{extra_linker_flags};

  ( $cc_guess, $libs_guess )
    = map { _trim_whitespace($_) } ( $cc_guess, $libs_guess );

  return ( $cc_guess, $libs_guess );
}

sub _trim_whitespace {
  my $string = shift;
  $string =~ s/^\s+|\s+$//g;
  return $string;
}

1;
