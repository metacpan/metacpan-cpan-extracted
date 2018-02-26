package
  Env::Modulecmd;

use strict;
use warnings;
use feature 'say';
use File::Temp qw{tempdir};

our $PATH_TO_ADD = tempdir( CLEANUP => 1 );

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _modulecmd {
  my ($cmd) = shift;
  say STDERR 'list'    if $cmd eq 'list';
  say STDERR 'avail'   if $cmd eq 'avail';
  say STDERR "$cmd @_" if $cmd =~ m/^(show|load|unload)$/;
  if ($cmd eq 'load') {
    _prepend_path('PERL5LIB', $PATH_TO_ADD, ":", 1);
    $ENV{FOO_BAR_BAZ} = 1;
  } elsif($cmd eq 'unload') {
    _prepend_path('PERL5LIB', $PATH_TO_ADD, ":", 0);
    delete $ENV{FOO_BAR_BAZ};
  }
  return 1;
}

sub _prepend_path {
  my ($name, $path, $sep, $add) = (shift, shift, shift || ":", shift || 0);
  if ($add) {
    $ENV{$name} = join $sep, $path, split /\Q$sep\E/, $ENV{$name} || '';
  } else {
    if ($path =~ m/\Q\$sep\E/) {
      for my $part(split /\Q$sep\E/, $path) {
        $ENV{$name} = join $sep, grep { ! m{^\Q$part\E$} }
          split /\Q$sep\E/, $ENV{$name} || '';
      }
    } else {
      $ENV{$name} = join $sep, grep { ! m{^\Q$path\E$} }
        split /\Q$sep\E/, $ENV{$name} || '';
    }
  }
  return;
}

sub import {
  die "do not import";
}

1;
