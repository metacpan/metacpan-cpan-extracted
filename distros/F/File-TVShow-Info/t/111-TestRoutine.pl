#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use File::TVShow::Info;

use vars qw(@filePatterns @test_data);
use Term::ANSIColor qw(:constants);
use Data::Dumper;

$Term::ANSIColor::AUTORESET = 1;

@test_data = (
  { # TV Show Support -   By Season and Episode
  test_bool_results => [ 1, 0, 0], # is_tv_show is_tv_subtitle is_multi_episode
  test_keys => [qw(filename show_name country year season episode extra_meta ext)],
  season => 1,
  name => 'Shows by Season without year tests',
  test_files => [
    ['Series Name.S01E01.EXTRA_META.avi', 'Series Name', '', '', "01", "01", 'EXTRA_META', 'avi'],
    ['Series Name.S01E02.EXTRA_META.avi', 'Series Name', '', '', "01", "02", 'EXTRA_META', 'avi'],
    ['Series Name S01E03.EXTRA_META.avi', 'Series Name', '', '', "01", "03", 'EXTRA_META', 'avi'],
    ['Series Name S01E04.EXTRA_META.avi', 'Series Name', '', '', "01", "04", 'EXTRA_META', 'avi'],
    ['Series Name.S01E05.EXTRA_META.avi', 'Series Name', '', '', "01", "05", 'EXTRA_META', 'avi'],
    ['Series Name.S01E06.avi', 'Series Name', '', '', "01", "06", '', 'avi'],
    ],
  },
  { # TV Show Support -   By Season and Episode
  test_bool_results => [ 1, 0, 0], # is_tv_show is_tv_subtitle is_multi_episode
  test_keys => [qw(filename show_name country year season episode extra_meta ext)],
  season => 1,
  name => 'Shows by Season with year tests',
  test_files => [
    ['Series Name 2018.S01E01.EXTRA_META.avi', 'Series Name', '', '2018', "01", "01", 'EXTRA_META', 'avi'],
    ['Series Name.(2018).S01E02.EXTRA_META.avi', 'Series Name', '', '2018', "01", "02", 'EXTRA_META', 'avi'],
    ['Series Name 1971 S01E03.EXTRA_META.avi', 'Series Name', '', '1971', "01", "03", 'EXTRA_META', 'avi'],
    ['Series Name S01E04.EXTRA_META.avi', 'Series Name', '', '', "01", "04", 'EXTRA_META', 'avi'],
    ['Series Name.S01E05.EXTRA_META.avi', 'Series Name', '', '', "01", "05", 'EXTRA_META', 'avi'],
    ['Series Name.S01E06.avi', 'Series Name', '', '', "01", "06", '', 'avi'],
    ],
  },
  { # TV Show Support -   By Date no Season or Episode

  test_bool_results => [1, 0, 0], # is_tv_show is_tv_subtitle is_multi_episode
  test_keys => [qw(filename show_name year month date extra_meta ext)],
  name => 'Shows by Date',
  test_files => [
    ['Series Name.2018.01.03.EXTRA_META.avi', 'Series Name', '2018', '01', '03', 'EXTRA_META', 'avi'],
    ['Series Name 2018 02 03 EXTRA_META.avi', 'Series Name', '2018', '02', '03', 'EXTRA_META', 'avi'],
    ['Series.Name.2018.03.03.EXTRA_META.avi', 'Series.Name', '2018', '03', '03', 'EXTRA_META', 'avi'],
    ['Series Name 2018 04 03.avi', 'Series Name', '2018', '04', '03', '', 'avi'],
    ['Series.Name.2018.05.03.avi', 'Series.Name', '2018', '05', '03', '', 'avi'],
    ],
  },
  { # TV Show Support -   By Season and Episode Real Data
  test_bool_results => [ 1, 0, 0], # is_tv_show is_tv_subtitle is_multi_episode
  test_keys => [qw(filename show_name country year season episode episode_name extra_meta ext)],
  season => 1,
  name => 'Shows by Season without year tests',
  test_files => [
    ['life on mars - S01E01.avi', 'life on mars', '', '', "01", "01", '', '', 'avi'],
    ['Luther.S05E03.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv', 'Luther', '', '', '05', '03', '', '720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv]', 'mkv'],
    ['Luther.S05E03.Bogus.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv', 'Luther', '', '', '05', '03', 'Bogus', 'Bogus.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv]', 'mkv'],
    ],
  },
  { # TV Show Support -   By Season and Episode Real Data with Country
  test_bool_results => [ 1, 0, 0], # is_tv_show is_tv_subtitle is_multi_episode
  test_keys => [qw(filename show_name country year season episode extra_meta ext)],
  season => 1,
  name => 'Shows by Season with country but without year tests',
  test_files => [
    ['Life.on.Mars.US.S01E01.HDTV.XViD-DOT.avi', 'Life.on.Mars.US', 'US', '', "01", "01", 'HDTV.XViD-DOT', 'avi'],
    ['Life.on.Mars.(US).S01E01.HDTV.XViD-DOT.avi', 'Life.on.Mars.(US)', 'US', '', "01", "01", 'HDTV.XViD-DOT', 'avi'],
    ],
  },
);

sub testVideoFilename {
    print "Running Tests:\n";
    # Boolean Functions
    my @bool_funcs = qw(is_tv_show is_tv_subtitle is_multi_episode);
    my @get_funcs;
    for my $test_case (@test_data) {
      if (defined $test_case->{season}) {
        @get_funcs = qw(show_name country year season episode);
      } else {
        @get_funcs = qw(show_name year month date);
      }

      print "Testing $test_case->{name}\n";
      for my $test (@{$test_case->{test_files}}) {
        my $file = File::TVShow::Info->new($test->[0]);
        # Make the correct rule fired
        if (!defined $file->{regex}) {
          print RED "FAILED: $file->{file} (No Match found!)\n";
          print Dumper($file); exit;
        }
        # Make sure all the attributes were correctly parsed
        my $keys = $test_case->{test_keys};
        # Get the number of attr to be checked in the text_case
        # Off by one error as array goes from 0 to max - 1
        for my $i (0 .. (scalar @{$keys} - 1)) {
          my $attr = $file->{$keys->[$i]};
          my $value = $test->[$i];
          # Skip test if the key does not exit in Info obj
          next if (!defined $attr);
          if ($attr ne $value) {
            print BLUE "{$keys->[$i]}: ";
            print RED "'$attr' ne '$value'\nFAILED: $file->{file}\n";
            print Dumper($file); exit;
            }
        } # end for $i attr and value check
        # Make sure all the is_XXXX() functions work properly
        for my $i (0..$#bool_funcs) {
          unless (eval "\$file->$bool_funcs[$i]()" == $test_case->{test_bool_results}->[$i]) {
            print RED "\$file->$bool_funcs[$i]() != $test_case->{test_bool_results}->[$i]\nFAILED: $file->{file}\n";
            print Dumper($file); exit;
          }
        } # for $i bool_funcs check
        for my $j (1..$#get_funcs) {
          # Checking get methods
          unless ( eval "\$file->$get_funcs[$j]" eq $test->[$j+1]) {
            print RED "$\file->$get_funcs[$j]() != $test->[$j]\nFailed $file->{file}\n";
            print Dumper($file); exit;
          };
        } # end get method tests $j
        print GREEN "PASSED: $file->{file}\n";
      }
      print "$test_case->{name} Complete\n\n";
    }
    print "Testing Complete.\n";
}

testVideoFilename();

done_testing();
