# this is obsolete as of EU::CppG 0.13, and will be removed in a future version
package ILCPPConfig::CompilerGuess;

use strict;
use warnings;
use ExtUtils::CppGuess;
use Config;

our $VERSION   = '0.01';

# Repackage results from ExtUtils::CppGuess into a form that is most useful
# to Inline::CPP's Makefile.PL.

sub guess_compiler {
  if( $Config::Config{osname} eq 'freebsd'
    && $Config::Config{osvers} =~ /^(\d+)/
    && $1 >= 10
  ){
    return ( 'clang++', '-lc++' );
  }
  else {
    my $guesser = ExtUtils::CppGuess->new;
    my %configuration = $guesser->module_build_options;
    my( $cc_guess, $libs_guess );
    if( $guesser->is_gcc ) {
      $cc_guess = $Config{cc} eq 'clang' ? 'clang++' : 'g++';
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
}

sub _trim_whitespace {
  my $string = shift;
  $string =~ s/^\s+|\s+$//g;
  return $string;
}

1;
