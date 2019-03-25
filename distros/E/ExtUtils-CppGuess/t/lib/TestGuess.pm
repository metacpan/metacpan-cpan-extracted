package TestGuess;

use strict;
use warnings;

# This is the logic we used to keep in Makefile.PL that was used to make an
# educated guess as to what compiler, compiler flags, standard libraries, and
# linker flags to configure into Inline::CPP.

# Inline::CPP shifted to using ExtUtils::CppGuess instead, but retains this
# logic for testing purposes, as well as for working toward improving
# ExtUtils::CppGuess.

# my( $cc_guess, $libs_guess ) = guess_compiler();


#============================================================================
# Make an intelligent guess about what compiler to use
#============================================================================

sub new {
  my( $class, $config ) = @_;
  return bless { config => $config }, $class;
}

sub guess_compiler {
  my $self = shift;

  my( $cc_guess, $libs_guess );
  
  if ( $self->{config}{osname} eq 'darwin' ) {
    my $stdlib_query
        = 'find /usr/lib/gcc -name "libstdc++*" | grep $( uname -p )';
    my $stdcpp = `$stdlib_query`;
    +$stdcpp =~ s/^(.*)\/[^\/]+$/$1/;
    $cc_guess   = 'g++';
    $libs_guess = "-L$stdcpp -lstdc++";
  }
  elsif ( $self->{config}{osname} ne 'darwin'
    and $self->{config}{gccversion}
    and $self->{config}{cc} =~ m#\bgcc\b[^/]*$#
  ) {
    ( $cc_guess = $self->{config}{cc} ) =~ s[\bgcc\b([^/]*)$(?:)][g\+\+$1];
    $libs_guess = '-lstdc++';
  }
  elsif ( $self->{config}{osname} =~ m/^MSWin/ ) {
    $cc_guess   = 'cl -TP -EHsc';
    $libs_guess = 'MSVCIRT.LIB';
  }
  elsif ( $self->{config}{osname} eq 'linux' ) {
    $cc_guess   = 'g++';
    $libs_guess = '-lstdc++';
  }
# Dragonfly patch is just a hunch... (still doesn't work)
  elsif ( $self->{config}{osname} eq 'netbsd' || $self->{config}{osname} eq 'dragonfly' ) {
    $cc_guess   = 'g++';
    $libs_guess = '-lstdc++ -lgcc_s';
  }
  elsif ( $self->{config}{osname} eq 'cygwin' ) {
    $cc_guess   = 'g++';
    $libs_guess = '-lstdc++';
  }
  elsif ( $self->{config}{osname} eq 'solaris'
          || $self->{config}{osname} eq 'SunOS' ) {
    if ( $self->{config}{cc} eq 'gcc'
      || ( exists( $self->{config}{gccversion} ) && $self->{config}{gccversion} > 0 ) )
    {
        $cc_guess   = 'g++';
        $libs_guess = '-lstdc++';
    }
    else {
        $cc_guess   = 'CC';
        $libs_guess = '-lCrun';
    }
  }
  # MirBSD: Still problematic.
  elsif ( $self->{config}{osname} eq 'mirbsd' ) {
    my $stdlib_query
      = 'find /usr/lib/gcc -name "libstdc++*" | grep $( uname -p ) | head -1';
    my $stdcpp = `$stdlib_query`;
    +$stdcpp =~ s/^(.*)\/[^\/]+$/$1/;
    $cc_guess   = 'g++';
    $libs_guess = "-L$stdcpp -lstdc++ -lc -lgcc_s";
  }
  elsif( $self->{config}{osname} eq 'freebsd'
    and $self->{config}{osvers} =~ /^(\d+)/
    and $1 >= 10
  ){
    $cc_guess = 'clang++';
    $libs_guess = '-lc++';
  }
  # Sane defaults for other (probably unix-like) operating systems
  else {
    $cc_guess   = 'g++';
    $libs_guess = '-lstdc++';
  }

  return( $cc_guess, $libs_guess );
}

1;
