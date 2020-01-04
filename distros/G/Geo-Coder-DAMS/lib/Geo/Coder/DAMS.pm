package Geo::Coder::DAMS;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Geo::Coder::DAMS', $VERSION);

use Exporter 'import';
our @EXPORT    = ();
our @EXPORT_OK = qw(
    dams_init
    dams_retrieve
    dams_debugmode
    dams_set_check_new_address
    dams_set_limit
    dams_set_exact_match_level
    dams_get_exact_match_level
    dams_elapsedtime
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

1;

=head1 NAME

Geo::Coder::DAMS - Perl bindings for Japanese Geocoder DAMS

=head1 SYNOPSIS

    use Geo::Coder::DAMS qw(dams_init dams_retrieve);
    use YAML::Syck;

    dams_init();
    my $result = dams_retrieve("駒場4-6-1");
    print Dump $result;

    ---
    candidates:
      -
        -
          level: 1
          name: 茨城県
          x: '140.445465087891'
          "y": '36.3440399169922'
        -
          level: 3
          name: 取手市
          x: '140.050384521484'
          "y": '35.9114608764648'
        -
          level: 5
          name: 駒場
          x: '140.0546875'
          "y": '35.9143371582031'
        -
          level: 6
          name: 四丁目
          x: '140.05012512207'
          "y": '35.9146995544434'
        -
          level: 7
          name: ６番
          x: '140.053268432617'
          "y": '35.9151306152344'
      -
        -
          level: 1
          name: 東京都
          x: '139.691635131836'
          "y": '35.6894989013672'
        -
          level: 3
          name: 目黒区
          x: '139.698699951172'
          "y": '35.6404609680176'
        -
          level: 5
          name: 駒場
          x: '139.686813354492'
          "y": '35.6557998657227'
        -
          level: 6
          name: 四丁目
          x: '139.679428100586'
          "y": '35.6616668701172'
        -
          level: 7
          name: ６番
          x: '139.677383422852'
          "y": '35.6618995666504'
    score: 4
    tail: 1

=head1 DESCRIPTION

This module is Perl bindings for DAMS.

Geocoder DAMS (Distributed Address Matching System)
L<http://newspat.csis.u-tokyo.ac.jp/geocode/>

=head1 METHODS

=head2 dams_init()

=head2 $result_hashref = dams_init(dic_string)

=head2 dams_retrieve(query_string)

=head2 dams_debugmode(bool_flag)

=head2 dams_set_check_new_address(bool_flag)

=head2 dams_set_limit(limit_int)

=head2 dams_set_exact_match_level(int_level)

=head2 $long_level = dams_get_exact_match_level()

=head2 $int_sec = dams_elapsedtime()

=head1 AUTHOR

Tomohiro Hosaka, E<lt>bokutin@bokut.inE<gt>

=head1 COPYRIGHT AND LICENSE

The Geo::Coder::DAMS module is

Copyright (C) 2019 by Tomohiro Hosaka

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
