package ILCPPConfig::OldCompilerGuess;

use strict;
use warnings;
use Config;
use Exporter;

our @ISA       = 'Exporter';
our @EXPORT_OK = 'guess_compiler';
our $VERSION   = '0.01';

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

sub guess_compiler {

  my( $cc_guess, $libs_guess );
  
  if ( $Config{osname} eq 'darwin' ) {
    my $stdlib_query
        = 'find /usr/lib/gcc -name "libstdc++*" | grep $( uname -p )';
    my $stdcpp = `$stdlib_query`;
    +$stdcpp =~ s/^(.*)\/[^\/]+$/$1/;
    $cc_guess   = 'g++';
    $libs_guess = "-L$stdcpp -lstdc++";
  }
  elsif ( $Config{osname} ne 'darwin'
    and $Config{gccversion}
    and $Config{cc} =~ m#\bgcc\b[^/]*$#
  ) {
    ( $cc_guess = $Config{cc} ) =~ s[\bgcc\b([^/]*)$(?:)][g\+\+$1];
    $libs_guess = '-lstdc++';
  }
  elsif ( $Config{osname} =~ m/^MSWin/ ) {
    $cc_guess   = 'cl -TP -EHsc';
    $libs_guess = 'MSVCIRT.LIB';
  }
  elsif ( $Config{osname} eq 'linux' ) {
    $cc_guess   = 'g++';
    $libs_guess = '-lstdc++';
  }
# Dragonfly patch is just a hunch... (still doesn't work)
  elsif ( $Config{osname} eq 'netbsd' || $Config{osname} eq 'dragonfly' ) {
    $cc_guess   = 'g++';
    $libs_guess = '-lstdc++ -lgcc_s';
  }
  elsif ( $Config{osname} eq 'cygwin' ) {
    $cc_guess   = 'g++';
    $libs_guess = '-lstdc++';
  }
  elsif ( $Config{osname} eq 'solaris' or $Config{osname} eq 'SunOS' ) {
    if ( $Config{cc} eq 'gcc'
      || ( exists( $Config{gccversion} ) && $Config{gccversion} > 0 ) )
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
  elsif ( $Config{osname} eq 'mirbsd' ) {
    my $stdlib_query
      = 'find /usr/lib/gcc -name "libstdc++*" | grep $( uname -p ) | head -1';
    my $stdcpp = `$stdlib_query`;
    +$stdcpp =~ s/^(.*)\/[^\/]+$/$1/;
    $cc_guess   = 'g++';
    $libs_guess = "-L$stdcpp -lstdc++ -lc -lgcc_s";
  }
  elsif( $Config{osname} eq 'freebsd'
    and $Config{osvers} =~ /^(\d+)/
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
  
  if( $cc_guess eq 'g++' && $Config{cc} eq 'clang') {
    $cc_guess = 'clang++';
  }

  return( $cc_guess, $libs_guess );
}

1;
