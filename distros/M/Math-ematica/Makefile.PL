#                              -*- Mode: Perl -*- 
# $Basename: Makefile.PL $
# $Revision: 1.8 $
# Author          : Ulrich Pfeifer
# Created On      : Sat Dec 20 14:42:50 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Apr 17 18:17:55 2005
# Language        : CPerl
# Update Count    : 52
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
# 
# 

use ExtUtils::MakeMaker;

my (%conf, $LIBDIR, $INCDIR);

%conf = find_math_installation();

unless ($conf{bindir}) {
  print
    "Using hardcoded paths! You probably will have to edit line ",
    (__LINE__+ 3), " to line ", (__LINE__+ 5), "\nin $0\n";
  
  my $MLINKDIR  = '/usr/local/mathematica/AddOns/MathLink/DevelopersKits';
  my $SYS       = 'Linux';
  my $ADDONSDIR = "${MLINKDIR}/${SYS}/CompilerAdditions";
  $INCDIR    = $ADDONSDIR;
  $LIBDIR    = $ADDONSDIR;
} else {
  if ($conf{bindir} =~ s:/Executables$::) {
    # This seems to work with Mathematica 5.0
    $INCDIR    = "$conf{bindir}/AddOns/MathLink/DeveloperKit/Linux/CompilerAdditions";
    $LIBDIR    = "$conf{bindir}/AddOns/MathLink/DeveloperKit/Linux/CompilerAdditions";
  } else {
    # this used to work with Mathematica 2.0
    $INCDIR    = $conf{bindir};
    $LIBDIR    = $conf{bindir};
  }
}

WriteMakefile
  (
   'NAME'	  => 'Math::ematica',
   'VERSION_FROM' => 'ematica.pm',
   'dist'         => {COMPRESS => 'gzip -9f'},
   'LIBS'	  => ["-L$LIBDIR -lML", '-lm'],
   'DEFINE'	  => '',
   'INC'	  => "-I$INCDIR",
   'OBJECT'       => 'ematica.o constants.o',
   'MAN3PODS'     => { 'ematica.pm' => 'blib/man3/Math::ematica.3'},
   'XSPROTOARG'   => '-prototypes',
   'dist'         => {
                      COMPRESS => 'gzip -9f',
                      PREOP    => 'pod2text ematica.pm > README',
                     },
  );

sub find_math_installation {
  my $mcc;
  my %var;

  # look for mcc
  for (split /:/, $ENV{PATH}) {
    if (-x "$_/mcc") {
      $mcc = "$_/mcc";
    }
  }
  unless ($mcc) {
    warn "Could not find mcc in your \$PATH\n";
    return;
  }

  # set a reasonable default, as the stuff does not seem to work with
  # newer Mathematica versions

  my $mccdir = -l $mcc ? readlink $mcc : $mcc;
  $mccdir =~ s:/[^/]+$::;
  $var{bindir} = $mccdir;

  # Read mcc script and exract path information
  open(MCC, "< $mcc") or die "Could not open '$mcc' for reading\n";
  while (<MCC>) {
    if (m{^ \s* (\w+) \s* = \s* (\S+)}x) {
      my ($var_name, $value) = ($1, $2);
      $value =~ s/\$(\w+)/$var{$1}/eg;
      $var{$var_name} = $value;
    }
  }
  close MCC;

  %var;
}
