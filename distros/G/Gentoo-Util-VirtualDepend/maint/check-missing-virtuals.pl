#!/usr/bin/env perl
# FILENAME: check-gentoo-names.pl
# CREATED: 10/11/14 06:19:18 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Check gentoo side of map

use strict;
use warnings;
use utf8;

use Path::Tiny;
use Capture::Tiny qw( capture );
use FindBin;
use lib 'lib';
use Test::File::ShareDir::Dist { 'Gentoo-Util-VirtualDepend' => "$FindBin::Bin/../share/" };
use Gentoo::Util::VirtualDepend;
my $vdep = Gentoo::Util::VirtualDepend->new();

my ( $out, $err, $exit ) = capture {
  system( 'eix', '--in-overlay', 'gentoo', '--only-names', '-c', 'virtual/perl-*' );
};
if ( $exit != 0 and $exit != 1 and $exit != 256 ) {
  die "Halt: $err $exit";
}
for my $name ( split /\n/, $out ) {
  if ( not $vdep->has_gentoo_package($name) ) {
    print $name . qq[ is missing\n];
  }
}
