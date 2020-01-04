#!/usr/local/bin/perl

use lib qw(lib blib/arch);
use Geo::Coder::DAMS qw(dams_init dams_retrieve);
use YAML::Syck;

dams_init();
my $result = dams_retrieve("駒場4-6-1");
print Dump $result;

__END__

% ./ex/synopsis.pl
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
