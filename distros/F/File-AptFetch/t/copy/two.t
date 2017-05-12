# $Id: two.t 497 2014-03-17 23:44:36Z whynot $
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

my( $dira, $dirb, $fsra, $fsrb, $ftga, $ftgb );
my( $faf, $rv, $serr, $done );
my $Copy_Has_Md5hash = 1;

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib     ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib             ? ( skip_all =>       q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/copy| ? ( skip_all =>     q|missing method [copy:]| ) :
                          ( tests    =>                            18 );

$dira = FAFTS_tempdir nick => q|dtag8fa1|;
$dirb = FAFTS_tempdir nick => q|dtagdd5b|;
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( q|copy| ) };
ok !$serr, q|tag+bfa5 {STDERR} is empty|;

$fsra = FAFTS_tempfile
  nick => q|ftag00a2|, dir => $dira, content => q|copy two alpha|;
$fsrb = FAFTS_tempfile
  nick => q|ftag90d4|, dir => $dira, content => q|copy two bravo|;
$ftga = FAFTS_tempfile nick => q|ftagf2fc|, dir => $dirb;
unlink $ftga;
$ftgb = FAFTS_tempfile nick => q|ftage578|, dir => $dirb;
unlink $ftgb;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftga, $fsra, $ftgb, $fsrb ) };
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv,                   stderr => $serr,
  status => $faf->{Status}, log => $faf->{log}        },
{ rc => '',    stderr => '',
  status => 100, log => [ ]                           },
  q|[copy:] accepts two requests for in directory copy|;
is_deeply [ FAFTS_wait_and_gain $faf ], [ '', '' ], q|tag+48d9|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
my %samples =
( qq|copy:$fsra| =>
  { filename => $ftga,      uri => qq|copy:$fsra|,     size => -s $ftga,
    md5hash => $Copy_Has_Md5hash && q|5111cad44ab3f7285cbacfadba834811| },
  qq|copy:$fsrb| =>
  { filename => $ftgb,     uri => qq|copy:$fsrb|,      size => -s $ftgb,
    md5hash => $Copy_Has_Md5hash && q|a484a364925091b4e7b575b89740cb90| } );
is_deeply
{ rc => $rv,        stderr => $serr,         status => $faf->{Status},
  filename => $faf->{message}{filename},  uri => $faf->{message}{uri},
  size => $faf->{message}{size}, md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 201,
      %{$samples{$faf->{message}{uri}}}                               },
                                               q|[gain] succeedes once|;
$done = $faf->{message}{md5_hash} || $faf->{message}{filename};
is_deeply [ FAFTS_wait_and_gain $faf ], [ '', '' ], q|tag+8f12|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
$samples{qq|copy:$fsra|}{size} = -s $ftga;
$samples{qq|copy:$fsrb|}{size} = -s $ftgb;
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 201, log => [ ],
                  %{$samples{$faf->{message}{uri}}}                        },
                                                   q|[gain] succeedes twice|;
isnt $faf->{message}{md5_hash} || $faf->{message}{filename}, $done,
  q|and those files differ|;
ok -f $ftga, q|first file is really copied|;
ok -f $ftgb, q|second file is really copied|;

$fsra = FAFTS_tempfile
  nick => q|ftag742d|, dir => $dira, content => q|copy two charlie|;
$ftga = FAFTS_tempfile nick => q|ftage5a4|, dir => $dirb;
unlink $ftga;
$fsrb = FAFTS_tempfile
  nick => q|ftagf803|, dir => $dirb, content => q|copy two delta|;
$ftgb = FAFTS_tempfile nick => q|ftag2883|, dir => $dira;
unlink $ftgb;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftga, $fsra ) };
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log} },
{ rc => '',        stderr => '',         status => 201,         log => [ ] },
                     q|[copy:] 1st accepts request for inter directory copy|;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftgb, $fsrb ) };
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log} },
{ rc => '',         stderr => '',        status => 201,         log => [ ] },
                     q|[copy:] 2nd accepts request for inter directory copy|;
is_deeply [ FAFTS_wait_and_gain $faf ], [ '', '' ], q|tag+0d03|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
%samples =
( qq|copy:$fsra| =>
  { filename => $ftga,      uri => qq|copy:$fsra|,     size => -s $fsra,
    md5hash => $Copy_Has_Md5hash && q|b0f81a7ab3506710399d06b2d9e00ddb| },
  qq|copy:$fsrb| =>
  { filename => $ftgb,     uri => qq|copy:$fsrb|,      size => -s $ftgb,
    md5hash => $Copy_Has_Md5hash && q|9a18605db9a2cdcddb8c5b9da163d485| } );
is_deeply
{ rc => $rv,         stderr => $serr,        status => $faf->{Status},
  filename => $faf->{message}{filename},  uri => $faf->{message}{uri},
  size => $faf->{message}{size}, md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 201,          
      %{$samples{$faf->{message}{uri}}}                               },
                                         q|[gain] succeedes once again|;
$done = $faf->{message}{md5_hash} || $faf->{message}{uri};
is_deeply [ FAFTS_wait_and_gain $faf ], [ '', '' ], q|tag+c0a5|;
( $rv, $serr ) = FAFTS_wait_and_gain $faf;
$samples{qq|copy:$fsra|}{size} = -s $ftga;
$samples{qq|copy:$fsrb|}{size} = -s $ftgb;
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status}, log => $faf->{log},
  filename => $faf->{message}{filename},       uri => $faf->{message}{uri},
  size => $faf->{message}{size},      md5hash => $faf->{message}{md5_hash} },
{ rc => '', stderr => '', status => 201, log => [ ],
                  %{$samples{$faf->{message}{uri}}}                        },
                                             q|[gain] succeedes twice again|;
isnt $faf->{message}{md5_hash} || $faf->{message}{uri}, $done,
  q|and those files differ|;
ok -f $ftga, q|third file is really copied|;
ok -f $ftgb, q|fourth file is really copied|;

# vim: syntax=perl
