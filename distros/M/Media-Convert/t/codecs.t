#!/usr/bin/env perl

use Test::More;
use Media::Convert::FfmpegInfo;

my $info = Media::Convert::FfmpegInfo->instance;

ok(keys(%{Media::Convert::FfmpegInfo->instance->codecs}) > 0, "at least some codecs were detected");

done_testing
