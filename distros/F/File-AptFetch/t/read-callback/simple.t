# $Id: simple.t 499 2014-04-19 19:24:45Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.1 );

use t::TestSuite qw| :temp :mthd :diag |;
use File::AptFetch::Simple;
use Test::More;

our( @units, $dsrc, $dtrg, $file, $faux );
our( $faf, $rv, $serr, $fdat );

require t::ReadCallback;

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan                        !defined $Apt_Lib ?
( skip_all => q|not *nix, or misconfigured| ) : ( tests => scalar @units );

$dsrc = FAFTS_tempdir nick => q|dtag0675|;

while( my $unit = shift @units )                                     {
    $t::TestSuite::Diag_Tag = $unit->[0]{tag};
    $unit->[1]->();
    $unit->[2][2]{$_} = eval $unit->[2][2]{$_}    foreach @{$unit->[0]{eval}};
    ( $rv, $serr ) = FAFTS_wrap                        {
        File::AptFetch::Simple::_read_callback( $fdat ) };
    FAFTS_show_message %$fdat;
    if( $unit->[0]{init} )                                          {
        ok !$serr, $unit->[0]{tag}                                   }
    else                                                            {
        $serr = $serr =~ m($unit->[0]{stderr})          if $unit->[0]{stderr};
        is_deeply [ $rv, $serr, $fdat ], $unit->[2], $unit->[0]{tag} }}

# vim: syntax=perl
