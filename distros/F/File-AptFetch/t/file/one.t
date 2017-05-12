# $Id: one.t 501 2014-05-14 22:19:48Z whynot $
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
File::AptFetch::ConfigData->set_config( tick    =>  1 );

my( $dir, $fsrc );
my( $faf, $rv, $serr, $fdat );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib           ?     ( skip_all => q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/file| ? ( skip_all => q|missing method [file:]| ) :
                                                     ( tests => 7 );

$dir = FAFTS_tempdir nick => q|dtag387d|;
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( q|file| ) };
is $serr, '', q|tag+5f28 {STDERR} is empty|;

$fsrc = FAFTS_tempfile
  nick => q|ftag2ea1|, dir => $dir, content => q|file one alpha|;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $fsrc, $fsrc ) };
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log} },
{ rc => '',         stderr => '',        status => 100,         log => [ ] },
                                                  q|[file:] accepts request|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '',      stderr => '',      status => 201,      log => [ ],
  filename => $fsrc,                         uri => qq|file:$fsrc|,
  size => -s $fsrc, md5hash => q|5eb986e6affbe6f32f88638e7e3af63d|         },
                                                         q|[gain] succeedes|;
like $faf->{message}{last_modified}, qr(\d{1,2} \w{3} \d{4} [0-9:]{8}),
  q|{$message{Last-Modified}} seems to be OK|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status},
                  md5hash => $faf->{message}{md5_hash}    },
{ rc => q|(file): timeouted|, stderr => '', status => 201,
           md5hash => q|5eb986e6affbe6f32f88638e7e3af63d| },
                                           q|then timeouts|;

$fsrc = FAFTS_tempfile
  nick => q|ftag9a2f|, $dir => $dir, content => q|file one bravo|;
is_deeply [ FAFTS_wrap { $faf->request( $fsrc, $fsrc ) } ], [ '', '', '' ],
  q|tag+dfe9|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '',      stderr => '',      status => 201,      log => [ ],
  filename => $fsrc,                         uri => qq|file:$fsrc|,
  size => -s $fsrc, md5hash => q|2ee638f0f7595b7ea01f3c0edcf45f54|         },
                                                            q|then recovers|;

# vim: syntax=perl
