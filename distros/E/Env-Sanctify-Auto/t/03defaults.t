#!/usr/bin/perl -T

# t/03defaults.t
#  Tests that defaults are set properly per operating system
#
# $Id: 03defaults.t 8622 2009-08-18 04:46:41Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;

use Env::Sanctify::Auto;

sub for_os {
  my ($os) = @_;

  $^O = $os;

  my $sanctify = Env::Sanctify::Auto->new;
  return $ENV{PATH};
}

is(for_os('Unix'), '/usr/bin:/usr/bin/local', 'Unix default path set');
is(for_os('MSWin32'), '%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem',
  'Win32 default path set');
