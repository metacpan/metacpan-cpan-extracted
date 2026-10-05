#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 13;

use_ok('Media::Convert::Asset');
use_ok('Media::Convert::Pipe');

my $input = Media::Convert::Asset->new(url => 't/testvids/bbb.mp4');
my $output = Media::Convert::Asset->new(url => 't/testvids/out.ts', video_codec => 'mpeg2video');

# Test 1: has_progress returns falsy when class_progress is not set
my $pipe = Media::Convert::Pipe->new(inputs => [$input], output => $output, vcopy => 0, acopy => 0);
ok(!$pipe->has_progress, "has_progress returns falsy when class_progress is not set");
$pipe->run;  # Run to avoid destructor warning

# Test 2: has_class_progress returns falsy initially
ok(!Media::Convert::Pipe->has_class_progress, "has_class_progress returns falsy initially");

# Set up a test progress callback
my $callback_called = 0;
my $progress_values = [];
sub test_callback {
    my $perc = shift;
    $callback_called++;
    push @$progress_values, $perc;
}

# Test 3: Set class_progress and verify it's set
Media::Convert::Pipe->class_progress(\&test_callback);
ok(Media::Convert::Pipe->has_class_progress, "has_class_progress returns truthy after setting class_progress");

# Test 4: Create new pipe object - has_progress should be truthy without manual access
my $pipe2 = Media::Convert::Pipe->new(inputs => [$input], output => $output, vcopy => 0, acopy => 0);
ok($pipe2->has_progress, "has_progress returns truthy when class_progress is set (transparent)");

# Test 5: Verify the progress callback is the same as class_progress
is($pipe2->progress, \&test_callback, "progress callback matches class_progress after lazy initialization");

# Test 6: Verify the callback is actually called when running the pipe
$callback_called = 0;
$progress_values = [];
$pipe2->run;  # This should trigger the progress callback
ok($callback_called > 0, "progress callback was called during pipe run");
ok(grep { $_ == 100 } @$progress_values, "progress reached 100%");

# Test 10: Verify progress callback was called with increasing values
my @sorted_progress = sort { $a <=> $b } @$progress_values;
ok($sorted_progress[0] >= 0 && $sorted_progress[-1] == 100, "progress values are valid and reach 100%");

# Clean up output file from first pipe
unlink($output->url);

# Test 7: Clear class_progress and verify it's cleared
Media::Convert::Pipe->clear_class_progress;
ok(!Media::Convert::Pipe->has_class_progress, "has_class_progress returns falsy after clear_class_progress");

# Test 8: Create new pipe object after clearing - should have falsy has_progress
my $pipe3 = Media::Convert::Pipe->new(inputs => [$input], output => $output, vcopy => 0, acopy => 0);
ok(!$pipe3->has_progress, "has_progress returns falsy after clear_class_progress");
$pipe3->run;  # Run to avoid destructor warning

# Test 9: Previously created pipe should still have progress (lazy loaded objects keep their value)
ok($pipe2->has_progress, "previously created pipe still has progress after clear_class_progress");

# Clean up
unlink($output->url);
