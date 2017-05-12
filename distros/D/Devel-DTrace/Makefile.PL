use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Embed;
use Config;

require 5.008001;

use constant IS_SOLARIS => ( $^O =~ /solaris/ );

my @dtrace = qw(
 /usr/sbin/dtrace
);

sub find_bin {
  for ( @_ ) {
    return $_ if -x $_;
  }
  return;
}

my $dtrace = find_bin( @dtrace );

unless ( $dtrace ) {
  warn "Can't find dtrace executable. "
   . "I looked in the following places:\n";
  warn "  $_\n" for @dtrace;
  warn "Can't continue.\n";
  exit 0;    # == NA test result
}

# Find out whether we have a dtrace that supports -h

if (
    system "$dtrace -h -s plxsdtrace.d -o plxsdtrace.tmp "
  . ">/dev/null 2>&1 "
  . "&& rm plxsdtrace.tmp" ) {
  warn "It seems that $dtrace doesn't support the -h flag.\n";
  warn "Can't continue.\n";
  exit 0;    # == NA test result
}

# Whether we need to have dtrace create an object file and link
# against it.
my $DTRACE_OBJ = 0;
unless (
    system "$dtrace -G -s plxsdtrace.d -o plxsdtrace.tmp "
  . ">/dev/null 2>&1 "
  . "&& rm plxsdtrace.tmp" ) {
  $DTRACE_OBJ = 1;
}

if ( $Config{usedtrace} ) {
  print "Your Perl already supports DTrace natively.\n"
   . "Will still build Devel::DTrace but you probably don't need it.\n\n";
}

if ( $] < 5.008008 ) {
  print "The dtperl instrumented Perl executable doesn't seem to work\n"
   . "with Perls older than 5.8.8 (your $^X is $]).\n"
   . "I'll build it but be aware that it will be untested and may\n"
   . "be unusable. Sorry about that\n\n";
}

if ( IS_SOLARIS ) {
  print "The dtperl instrumented Perl executable doesn't seem to work\n"
   . "on Solaris. I'll build it but be aware that it will be\n"
   . "untested and may be unusable. Sorry about that\n\n";
}

my @obj = ( 'runops.o', ( $DTRACE_OBJ ? ( 'plxsdtrace.o' ) : () ) );

my %args = (
  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),

  NAME          => 'Devel::DTrace',
  AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
  LICENSE       => 'perl',
  VERSION_FROM  => 'lib/Devel/DTrace.pm',
  ABSTRACT_FROM => 'lib/Devel/DTrace.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More'        => 0,
    'Test::Differences' => 0,
    'List::Util'        => 0,
  },
  OBJECT    => join( ' ', @obj, 'DTrace.o' ),
  EXE_FILES => ['dtperl'],

  dist => {
    COMPRESS => 'gzip -9f',
    SUFFIX   => 'gz',
  },

  clean =>
   { FILES => [ 'Devel-DTrace-*', 'plxsdtrace.h', '*.o', 'dtperl' ] },

  depend => { 'runops.o' => 'plxsdtrace.h' },
);

WriteMakefile( %args );

sub rule {
  my ( $target, $dep, @steps ) = @_;
  return "$target: $dep\n" . ( join "\n", map { "\t$_" } @steps );
}

sub MY::postamble {
  chomp( my ( $ccopts, $ldopts ) = ( ccopts(), ldopts() ) );

  my @mf = (
    rule(
      'plxsdtrace.h' => 'plxsdtrace.d',
      "$dtrace \$(DTRACEFLAGS) -h -s plxsdtrace.d -o plxsdtrace.h"
    ),
    (
      $DTRACE_OBJ
      ? rule(
        'plxsdtrace.o' => 'plxsdtrace.d runops.o',
        "$dtrace \$(DTRACEFLAGS) -G -s plxsdtrace.d runops.o -o plxsdtrace.o"
       )
      : ()
    ),
    rule(
      'dtperl' => 'dtperl.o runops.o',
      join( ' ', "\$(LD) $ccopts -o dtperl $ldopts", @obj, 'dtperl.o' )
    ),
  );

  ( my $postamble = join "\n\n", @mf ) =~ s/^ +/\t/mg;

  return $postamble;
}
