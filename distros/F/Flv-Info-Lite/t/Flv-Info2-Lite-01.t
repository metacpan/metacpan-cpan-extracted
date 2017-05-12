use strict;
use warnings;

use Test::More tests => 7;
use Flv::Info::Lite qw(flv_info);

my %info = flv_info('t/material/test00.flv');
is($info{framerate}, 30);
is($info{have_video}, 1);
is($info{have_audio}, 1);
is($info{frame_count}, 103);
is($info{duration}, 4.2);
is($info{filesize}, 306268);
is($info{encoder}, 'Lavf55.19.104');


