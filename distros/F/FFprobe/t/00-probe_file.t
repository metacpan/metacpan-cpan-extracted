#!/usr/bin/env perl

use common::sense;
use Test::More tests => 10;
use File::Spec::Functions;
use File::Basename 'dirname';

BEGIN { use_ok 'FFprobe' or BAIL_OUT("Could not find the 'ffprobe' binary.") }

ok !defined FFprobe->probe_file(__FILE__ . "/i-dont-exist"), "invalid path";
ok !defined FFprobe->probe_file(__FILE__), "non-multimedia file";

my $probe = FFprobe->probe_file(catfile(dirname(__FILE__), 'test.ogg'));

ok defined $probe && ref $probe eq 'HASH', "multimedia file" or
    BAIL_OUT("Could not probe t/test.ogg");

is $$probe{format}{nb_streams}, 1, "number of streams";
is $$probe{format}{format_name}, 'ogg', "format name";
is scalar @{$$probe{stream}}, $$probe{format}{nb_streams}, "stream array size";
is $$probe{stream}[0]{codec_type}, 'audio', "stream codec type";
is $$probe{stream}[0]{codec_name}, 'vorbis', "stream codec name";
is $$probe{stream}[0]{'TAG:TEST'}, 'テスト', "unicode tags";
