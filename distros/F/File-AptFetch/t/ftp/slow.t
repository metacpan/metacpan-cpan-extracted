# $Id: slow.t 498 2014-04-02 19:19:15Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.1 );

use t::TestSuite qw| :temp :mthd :diag |;
use File::AptFetch;
use Test::More;

my( $dtrg, $fsrc, $ftrg, $furi );
my( $faf, $rv, $serr, @data, $tick );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
my $TS_Conf = t::TestSuite::FAFTS_discover_config;

=pod

Requested config section is I<%TSC{ftp_slow}>.
Required keys are:

=over

=item I<$TSC{ftp_slow}{block}>

Unless set forbids unit.

=item I<$TSC{ftp_slow}{source}>

Hierachial part of request.
Supposed to be something big (couple handreds of megs should be fine).
No schema.

=item I<$TSC{ftp_slow}{target}>

Collection of ftp target configuration items.

=item I<$TSC{ftp_slow}{target}{dir}>

Dirname where target file must be located.
Good idea would be to put it on something slow
(just like with F<t/copy/slow.t>).

=back

=cut

plan
  !defined $Apt_Lib ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib           ?     ( skip_all => q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/ftp|  ?  ( skip_all => q|missing method [ftp:]| ) :
  !defined $TS_Conf        ?   ( skip_all => q|can't read config| ) :
  !$TS_Conf                   ?   ( skip_all => q|not configured| ) :
  !$TS_Conf->{ftp_slow}{block}    ?    ( skip_all => q|forbidden| ) :
                                                    ( tests => 12 );

$dtrg = FAFTS_tempdir
  nick => q|dtag714f|, dir => $TS_Conf->{ftp_slow}{target}{dir};

File::AptFetch::set_callback read => sub {
    push @data, { %{$_[0]} }   if $_[0]{filename} eq $ftrg;
          &File::AptFetch::_read_callback };

File::AptFetch::ConfigData->set_config( timeout => 300 );
File::AptFetch::ConfigData->set_config( tick    =>   5 );

$fsrc = $TS_Conf->{ftp_slow}{source};
$ftrg = FAFTS_tempfile nick => q|ftag0075|, dir => $dtrg, unlink => !0;
@data = ( );

( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( q|ftp| ) };
is $serr, '', q|{STDERR} is empty|;

( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
FAFTS_show_message %{$faf->{message}};
is_deeply
{ rc => $rv, stderr => $serr, log => $faf->{log} },
{ rc => '',       stderr => '',       log => [ ] },      
                                      q|[request]|;

( $rv, $serr ) = FAFTS_wrap { $faf->gain };
$furi = $faf->{message}{uri};
FAFTS_show_message %$_          foreach $faf->{message}, $faf->{trace}{$furi};
is_deeply
{ rv => $rv, stderr => $serr, status => $faf->{Status},
                file => $faf->{trace}{$furi}{filename} },
{ rv => '', stderr => '', status => 102,
                          file => $ftrg                },
                                      q|tag+8a80 [gain]|;

# FIXME:201403282008:whynot: That will fail if there's no IPv6.
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
FAFTS_show_message %$_          foreach $faf->{message}, $faf->{trace}{$furi};
is_deeply
{ rv => $rv, stderr => $serr, status => $faf->{Status},
                file => $faf->{trace}{$furi}{filename} },
{ rv => '', stderr => '', status => 102,
                          file => $ftrg                },
                                      q|tag+b788 [gain]|;

( $rv, $serr ) = FAFTS_wrap { $faf->gain };
FAFTS_show_message %$_          foreach $faf->{message}, $faf->{trace}{$furi};
is_deeply
{ rv => $rv, stderr => $serr, status => $faf->{Status},
                file => $faf->{trace}{$furi}{filename} },
{ rv => '', stderr => '', status => 102,
                          file => $ftrg                },
                                      q|tag+3d42 [gain]|;

( $rv, $serr ) = FAFTS_wrap { $faf->gain };
FAFTS_show_message %$_          foreach $faf->{message}, $faf->{trace}{$furi};
is_deeply
{ rv => $rv, stderr => $serr, status => $faf->{Status},
                file => $faf->{trace}{$furi}{filename} },
{ rv => '', stderr => '', status => 102,
                          file => $ftrg                },
                                      q|tag+b63b [gain]|;

( $rv, $serr ) = FAFTS_wrap { $faf->gain };
FAFTS_show_message %$_          foreach $faf->{message}, $faf->{trace}{$furi};
is_deeply
{ rv => $rv, stderr => $serr, status => $faf->{Status},
                file => $faf->{trace}{$furi}{filename} },
{ rv => '', stderr => '', status => 102,
                          file => $ftrg                },
                                      q|tag+78ef [gain]|;

( $rv, $serr ) = FAFTS_wrap { $faf->gain };
FAFTS_show_message %$_          foreach $faf->{message}, $faf->{trace}{$furi};
is_deeply
{ rc => $rv,    stderr => $serr,    status => $faf->{Status},
  log => $faf->{log}, file => $faf->{trace}{$furi}{filename} },
{ rc => '', stderr => '', status => 200,
  log => [ ],             file => $ftrg                      },
                                         q|(URI Start) [gain]|;

( $rv, $serr ) = FAFTS_wait_and_gain $faf,
  File::AptFetch::ConfigData->config( q|timeout| ) * 1.5;
FAFTS_show_message %$_          foreach $faf->{message}, $faf->{trace}{$furi};
FAFTS_diag q|+++ there're all except last +++|;
FAFTS_show_message %$_                                          foreach @data;
cmp_ok @data, q|>|, 3, sprintf q|there're ticks (%i)|, @data - 1;
cmp_ok $faf->{trace}{$furi}{flag}, q|>|, 1,
  qq|there're spare {tick}s left ($faf->{trace}{$furi}{flag})|;
$tick = 1;
$tick++               while defined $data[$tick] && defined $data[$tick]{tmp};
if( defined $data[$tick] )            {
    FAFTS_diag q|+++ that's TP +++|;
    FAFTS_show_message %{$data[$tick]} }
is $data[$tick], undef, q|there's no TP|;
is_deeply
{ rc => $rv, stderr => $serr, status => $faf->{Status},
  log => $faf->{log},      uri => $faf->{message}{uri} },
{ rc => '', stderr => '', status => 201,
  log => [ ],              uri => $furi                },
                                    q|(URI Done) [gain]|;

# vim: syntax=perl
