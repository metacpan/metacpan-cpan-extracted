#!/usr/bin/perl

use warnings; use strict;

use English qw( -no_match_vars );
use FindBin qw( $Bin );
use Test::More;

use lib $Bin .q{/../lib/};

plan tests =>
    + 1 # new

    + 1 # note
    + 1 # info

    + 1 # at_file
    + 1 # file_off
    + 1 # error_at_file
    + 1 # warning_at_file

    + 1 # progress_open
    + 1 # progress_tick
    + 1 # progress_close

    + 1 # enable_buffer
    + 1 # dump_buffer
    + 1 # pass_buffer
;

# At the moment, it's just an extended smoke test.

use Devel::CoverReport::Feedback;

# Create object. (Fixme: check all four combinations: 0+0, 1+1, 0+1, 1+0)
my $feed = Devel::CoverReport::Feedback->new(
    quiet   => 0,
    verbose => 1,
);
isa_ok($feed, q{Devel::CoverReport::Feedback});

is($feed->enable_buffer(), 1, q{enable_buffer()});

# Basic methods.
is($feed->note('Test note.'), undef, q{note()});
is($feed->info('Test info.'), undef, q{info()});

# File-related.
is($feed->at_file('Foo.pm'), undef, q{at_file()});

is($feed->error_at_file('This is an error'),         undef, q{error_at_file()});
is($feed->warning_at_file('You will get a warning'), undef, q{warning_at_file()});

is($feed->file_off(), undef, q{file_off});

# Progress related.
is($feed->progress_open("Testing"), undef, qq{progress_open()});
is($feed->progress_tick(),          undef, qq{progress_tick()});
$feed->progress_tick();
$feed->progress_tick();
is($feed->progress_close(),         undef, qq{progress_close()});

# Test buffer output
my $ref_data = [
    qq{Test note.},
    qq{\n},
    qq{Test info.},
    qq{\n},
    qq{-> },
    qq{Foo.pm},
    qq{\n},
    qq{   E: },
    qq{This is an error},
    qq{\n},
    qq{   W: },
    qq{You will get a warning},
    qq{\n},
    qq{   },
    qq{Testing},
    qq{ [},
    qq{.},
    qq{.},
    qq{.},
    qq{]\n},
];

my $test_data = $feed->dump_buffer();
#use Data::Dumper; warn Dumper $test_data;

is_deeply($test_data, $ref_data, q{dump_buffer()});

is ($feed->pass_buffer(), undef, q{pass_buffer()});

