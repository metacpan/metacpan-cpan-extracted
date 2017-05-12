# $Id: one.t 497 2014-03-17 23:44:36Z whynot $
# Copyright 2009, 2010, 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.4 );

use t::TestSuite qw| :temp :mthd :diag |;
use File::AptFetch;
use Test::More;

File::AptFetch::ConfigData->set_config( timeout => 10 );

my( $dsrc, $dtrg, $fsrc, $ftrg );
my( $faf, $rv, $serr, $fdat );
my $Copy_Has_Md5hash = 1;

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib     ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib             ? ( skip_all =>       q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/copy| ? ( skip_all =>     q|missing method [copy:]| ) :
                          ( tests    =>                            17 );

$dsrc = FAFTS_tempdir nick => q|dtag9b89|;
$dtrg = FAFTS_tempdir nick => q|dtag714f|;
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( q|copy| ) };
ok !$serr, q|tag+3d48 {STDERR} is empty|;

$fsrc = FAFTS_tempfile
  nick => q|ftag0099|, dir => $dsrc, content => q|copy one alpha|;
sleep 2;
$ftrg = FAFTS_tempfile nick => q|ftag72bb|, dir => $dsrc;
unlink $ftrg;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log} },
{ rc => '',         stderr => '',        status => 100,         log => [ ] },
                            q|[copy:] accepts request for in directory copy|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv,    stderr => $serr,    status => $faf->{Status},
  uri => $faf->{message}{uri}, size => $faf->{message}{size} },
{ rc => '',  stderr => '',  status => 200,
  uri => qq|copy:$fsrc|, size => -s $fsrc                    },
         q|[gain] succeedes while requested file isn't gained|;
like $faf->{message}{last_modified}, qr(\d{1,2} \w{3} \d{4} [0-9:]{8}),
  q|{$message{Last-Modified}} seems to be OK|;
$fdat = $faf->{message}{last_modified};
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
# XXX:20090509024202:whynot: If I<$message{md5-hash}> happens to be 0 or empty space...
$Copy_Has_Md5hash = $faf->{message}{md5_hash};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
 filename => $faf->{message}{filename},        uri => $faf->{message}{uri},
                                             size => $faf->{message}{size},
                                      md5hash => $faf->{message}{md5_hash} },
{ rc => '',       stderr => '',       status => 201,       log => [ ],
  filename => $ftrg,                            uri => qq|copy:$fsrc|,
                                                     size => -s $ftrg,
  md5hash => $Copy_Has_Md5hash && q|bb0d3ea842422fc60f85d8e8f6ebf7ab|      },
                                                   q|[gain] succeedes again|;
ok -f $ftrg, q|and file is really copied|;
like $faf->{message}{last_modified}, qr(\d{1,2} \w{3} \d{4} [0-9:]{8}),
  q|{$message{Last-Modified}} seems to be OK|;
is $faf->{message}{last_modified}, $fdat, q|mtimes are reported equal|;
is +( stat $fsrc )[9], ( stat $ftrg )[9], q|and mtimes are the same|;

$fsrc = FAFTS_tempfile
  nick => q|ftagafea|, dir => $dsrc, content => q|copy one bravo|;
sleep 2;
$ftrg = FAFTS_tempfile nick => q|ftag9e81|, dir => $dtrg;
unlink $ftrg;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
                                      md5hash => $faf->{message}{md5_hash} },
{ rc => '',       stderr => '',       status => 201,       log => [ ],
  md5hash => $Copy_Has_Md5hash && q|bb0d3ea842422fc60f85d8e8f6ebf7ab|      },
                         q|[copy:] accepts request for inter directory copy|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv,    stderr => $serr,    status => $faf->{Status},
  uri => $faf->{message}{uri}, size => $faf->{message}{size}     },
{ rc => '', stderr => $serr, status => 200,
  uri => qq|copy:$fsrc|,  size => -s $fsrc                       },
  q|[gain] succeedes yet again while requested file isn't gained|;
like $faf->{message}{last_modified}, qr(\d{1,2} \w{3} \d{4} [0-9:]{8}),
  q|{$message{Last-Modified}} seems to be OK|;
$fdat = $faf->{message}{last_modified};
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
 filename => $faf->{message}{filename},        uri => $faf->{message}{uri},
                                             size => $faf->{message}{size},
                                      md5hash => $faf->{message}{md5_hash} },
{ rc => '',       stderr => '',       status => 201,       log => [ ],
  filename => $ftrg,                            uri => qq|copy:$fsrc|,
                                                     size => -s $ftrg,
  md5hash => $Copy_Has_Md5hash && q|1c0607dcd86a78ed1e30c894d0862a75|      },
  q|[gain] succeedes yet again|;
ok -f $ftrg, q|and file is really copied|;
like $faf->{message}{last_modified}, qr(\d{1,2} \w{3} \d{4} [0-9:]{8}),
  q|{$message{Last-Modified}} seems to be OK|;
is $faf->{message}{last_modified}, $fdat,
  q|mtimes are reported equal|;
is +( stat $fsrc )[9], ( stat $ftrg )[9], q|and mtimes are the same|;

# FIXME: Find the way to check for inter device copy

# vim: syntax=perl
