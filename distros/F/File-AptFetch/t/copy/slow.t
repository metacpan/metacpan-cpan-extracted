# $Id: slow.t 510 2014-08-11 13:26:00Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.3 );

use t::TestSuite qw| :temp :mthd :diag |;
use File::AptFetch;
use Test::More;

my( $dsrc, $dtrg, $fsrc, $ftrg, $furi );
my( $to, $tk );
my( $tag, $faf, $rv, $serr, @data, $tick );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
my $TS_Conf = t::TestSuite::FAFTS_discover_config;

=pod

Requested config section is I<%TSC{copy_slow}>.
Used keys are:

=over

=item I<$TSC{copy_slow}{block}>

Unless set forbids unit.

=item I<$TSC{copy_slow}{source}>

Collection of copy source configuration items.

=item I<$TSC{copy_slow}{source}{dir}>

Dirname where source file must be placed.

=item I<$TSC{copy_slow}{source}{size}>

Size of source file to create.

=item I<$TSC{copy_slow}{target}>

Collection of copy target configuration items.

=item I<$TSC{copy_slow}{target}{dir}>

Dirname where target file must be located.
Should be on different devices.
USB-sticks are prefered, especially for writing.
Reading might be fine too.

=back

=cut

plan
  !defined $Apt_Lib ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib           ?     ( skip_all => q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/copy| ? ( skip_all => q|missing method [copy:]| ) :
  !defined $TS_Conf        ?   ( skip_all => q|can't read config| ) :
  !$TS_Conf                   ?   ( skip_all => q|not configured| ) :
  !$TS_Conf->{copy_slow}{block}   ?    ( skip_all => q|forbidden| ) :
                                               ( tests => 3 + 5*8 );

my $tdpa = q|might fail for extremely unfair {tick} (%s)|;
my $tdpb = q|might fail for unfair {tick} (%s)|;

sub just_do_it ( $$ )                            {

    $tag = shift;
    $faf->{tick} = $_[0];
    File::AptFetch::ConfigData->set_config( tick => shift );
    $fsrc = FAFTS_tempfile nick => qq|$tag-sr|, dir => $dsrc,
      content => "\c@" x $TS_Conf->{copy_slow}{source}{size};
    $ftrg = FAFTS_tempfile nick => qq|$tag-tg|, dir => $dtrg, unlink => !0;
    @data = ( );

    ( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
    FAFTS_show_message %{$faf->{message}};
    is_deeply
    { rc => $rv, stderr => $serr, log => $faf->{log} },
    { rc => '',       stderr => '',       log => [ ] },      
                                    qq|$tag [request]|;

    ( $rv, $serr ) = FAFTS_wrap { $faf->gain };
    $furi = $faf->{message}{uri};
    FAFTS_show_message %{$faf->{message}};
    FAFTS_show_message %{$faf->{trace}{$furi}};
    is_deeply
    { rc => $rv,                   stderr => $serr,
      status => $faf->{Status}, log => $faf->{log},
            file => $faf->{trace}{$furi}{filename} },
    { rc => '',    stderr => '',
      status => 200, log => [ ],
                  file => $ftrg                    },
                         qq|$tag (URI Start) [gain]|;

    ( $rv, $serr ) = FAFTS_wait_and_gain $faf,
      File::AptFetch::ConfigData->config( q|timeout| ) * 1.5;
    FAFTS_show_message %{$faf->{message}};
    FAFTS_diag q|+++ that's the last one +++|;
    FAFTS_show_message %{$faf->{trace}{$furi}};
    FAFTS_diag q|+++ there're all except last +++|;
    FAFTS_show_message %$_                                      foreach @data;
    $tick = 1;
    $tick++           while defined $data[$tick] && defined $data[$tick]{tmp};
    FAFTS_diag q|+++ that's TP +++|;
    FAFTS_show_message %{$data[$tick]}                if defined $data[$tick];
    is_deeply
    { rc => $rv,                                 stderr => $serr,
      status => $faf->{Status},               log => $faf->{log},
      uri => $faf->{message}{uri}, size => $faf->{message}{size} },
    { rc => '',                  stderr => '',
      status => 201,               log => [ ],
      uri => qq|copy:$fsrc|, size => -s $fsrc                    },
                                        qq|$tag (URI Done) [gain]|;
    SKIP:                                                         {
        skip qq|$tag tag+56ca no samples|, 1                    unless defined
          $faf->{trace}{$furi}{tmp};
        is $faf->{trace}{$furi}{size}, -s $fsrc, q|{size} is size| }
    SKIP:                              {
      skip qq|$tag tag+afa8 no samples|, 1                unless $data[$tick];
      isnt $data[$tick]{size}, $data[$tick]{back},
        qq|$tag {size} != {back} at TP| }
    SKIP:                                                            {
      skip qq|$tag tag+aaea no samples|, 1              unless $data[$tick+1];
      is_deeply
      { ctag6fef =>    $data[$tick+1]{size} != $data[$tick+1]{back},
        ctaga4f3 => $data[$tick+1]{filename} eq $data[$tick+1]{tmp} },
      { ctag6fef => !0,
        ctaga4f3 => !0                                              },
                                                    qq|$tag after TP| }
    SKIP:                                       {
      skip qq|$tag tag+92e6 no samples|, 1              unless $data[$tick+2];
      is $data[$tick+2]{size}, $data[$tick+2]{back},
        qq|$tag {size} == {back} after after TP| }
    SKIP:                                       {
        skip qq|$tag tag+a9f2 no samples|, 1              unless $data[$tick];
        isnt $data[$tick-1]{filename}, $data[$tick-1]{tmp},
          qq|$tag {filename} ne {tmp} before TP| }}

$dsrc = FAFTS_tempdir
  nick => q|dtag9b89|, dir => $TS_Conf->{copy_slow}{source}{dir};
$dtrg = FAFTS_tempdir
  nick => q|dtag714f|, dir => $TS_Conf->{copy_slow}{target}{dir};

File::AptFetch::set_callback read => sub {
    push @data, { %{$_[0]} } if $_[0]{filename} eq $ftrg;
          &File::AptFetch::_read_callback };

$to = 10 * int $TS_Conf->{copy_slow}{source}{size} / (15*1024*1024) + 1;
File::AptFetch::ConfigData->set_config( timeout => $to );
cmp_ok $to, q|>|, 70, qq|timout is fair ($to)|;

$tk = int $to / 10 + 1;
cmp_ok $tk, q|>=|, 10, qq|tick isn't fair ($tk)|;

( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( q|copy| ) };
is $serr, '', qq|{STDERR} is empty|;

just_do_it q|tag+87af|, 5;
just_do_it q|tag+1b17|, 2;
just_do_it q|tag+8683|, 10;
just_do_it q|tag+8b5d|, $tk;
just_do_it q|tag+8332|, 2*$tk;

# XXX:201403151744:whynot: Refer to F<t/0/EmMn80.t> why it's required.
# XXX:201403170034:whynot: Also, for additional weirdness F<t/0/9raCtd.t>.
undef $faf; $tag = '';

# vim: syntax=perl
