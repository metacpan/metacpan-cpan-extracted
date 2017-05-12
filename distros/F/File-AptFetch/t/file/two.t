# $Id: two.t 501 2014-05-14 22:19:48Z whynot $
# Copyright 2009, 2010, 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.6 );

use t::TestSuite qw| :temp :mthd :diag |;
use File::AptFetch;
use Test::More;

File::AptFetch::ConfigData->set_config( timeout => 10 );
File::AptFetch::ConfigData->set_config( tick    =>  1 );

my( $dir, $fsra, $fsrb );
my( $faf, $rv, $serr, $done );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib           ?     ( skip_all => q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/file| ? ( skip_all => q|missing method [file:]| ) :
                                                    ( tests => 13 );

$dir = FAFTS_tempdir nick => q|dtag5017|;
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( q|file| ) };
is $serr, '', q|tag+02f2 {STDERR} is empty|;

$fsra = FAFTS_tempfile
  nick => q|ftag4b42|, dir => $dir, content => q|file two alpha|;
$fsrb = FAFTS_tempfile
  nick => q|ftagb8c8|, dir => $dir, content => q|file two bravo|;
is_deeply [ FAFTS_wrap { $faf->request( $fsra, $fsra ) } ], [ '', '', '' ],
  q|tag+14d3|;
is_deeply [ FAFTS_wrap { $faf->request( $fsrb, $fsrb ) } ], [ '', '', '' ],
  q|tag+f6f9|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
my %samples =
( qq|file:$fsra| =>
  { filename => $fsra, uri => qq|file:$fsra|, size => -s $fsra, 
                md5hash => q|5b17fdef964d9b01f2e6e595fb0034b7| },
  qq|file:$fsrb| =>
  { filename => $fsrb, uri => qq|file:$fsrb|, size => -s $fsrb, 
                md5hash => q|0e3186ccab6bc750fd707b159875e596| } );
is_deeply
{ rc => $rv,        stderr => $serr,         status => $faf->{Status},
  filename => $faf->{message}{filename},  uri => $faf->{message}{uri},
  size => $faf->{message}{size}, md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 201,          
      %{$samples{$faf->{message}{uri}}}                               },
                                               q|[gain] succeedes once|;
$done = $faf->{message}{md5_hash} || $faf->{message}{filename};
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 201, log => [ ],
                  %{$samples{$faf->{message}{uri}}}                        },
                                                   q|[gain] succeedes twice|;
isnt $faf->{message}{md5_hash} || $faf->{message}{filename}, $done,
 q|retrieved files are different|;

$fsra = FAFTS_tempfile
  nick => q|ftagd7d3|, dir => $dir, content => q|file two charlie|;
$fsrb = FAFTS_tempfile
  nick => q|ftag022a|, dir => $dir, content => q|file two delta|;
is_deeply
[ FAFTS_wrap { $faf->request( $fsra, $fsra, $fsrb, $fsrb ) } ], [ '', '', '' ],
  q|tag+b5e2|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
%samples =
( qq|file:$fsra| =>
  { filename => $fsra, uri => qq|file:$fsra|, size => -s $fsra,
                md5hash => q|0f59302257116cc357cdee1d02687c41| },
  qq|file:$fsrb| =>
  { filename => $fsrb, uri => qq|file:$fsrb|, size => -s $fsrb,
                md5hash => q|2cdfe7217d54310df2caebcd0df8b124| } );
is_deeply
{ rc => $rv,         stderr => $serr,        status => $faf->{Status},
  filename => $faf->{message}{filename},  uri => $faf->{message}{uri},
  size => $faf->{message}{size}, md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 201,          
      %{$samples{$faf->{message}{uri}}}                               },
                                           q|[gain] succeedes once yet|;
$done = $faf->{message}{md5_hash};
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 201, log => [ ],
                  %{$samples{$faf->{message}{uri}}}                        },
                                               q|[gain] succeedes twice yet|;
isnt $faf->{message}{md5_hash}, $done, q|retrieved files are different|;
$done = $faf->{message}{md5_hash};
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status},
                  md5hash => $faf->{message}{md5_hash}    },
{ rc => q|(file): timeouted|, stderr => '', status => 201,
                                         md5hash => $done },
                                           q|then timeouts|;

$fsra = FAFTS_tempfile
  nick => q|ftag6ac5|, dir => $dir, content => q|file two echo|;
is_deeply [ FAFTS_wrap { $faf->request( $fsra, $fsra ) } ], [ '', '', '' ],
  q|tag+291e|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '',      stderr => '',      status => 201,      log => [ ],
  filename => $fsra,                         uri => qq|file:$fsra|,
  size => -s $fsra, md5hash => q|ee1a9331bbcdb86687a484a7e0583201|         },
                                                            q|then recovers|;

# vim: syntax=perl
