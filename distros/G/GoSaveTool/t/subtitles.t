use strict;
use warnings;
use Test::More;
use GoSaveTool::Subtitles qw(to_ms from_ms parse is_vtt to_srt to_vtt convert shift_cues repair);

# The checks of @gosavetool/subtitles
my $srt = "1\r\n00:00:01,000 --> 00:00:03,500\r\nHello\r\nworld\r\n\r\n2\r\n00:00:03,000 --> 00:00:02,000\r\nSecond\r\n\r\n3\r\n00:00:00,500 --> 00:00:00,900\r\nFirst\r\n";
my $cues = parse($srt);
is scalar @$cues, 3, 'three cues';
is $cues->[0]{text}, "Hello\nworld", 'multi-line text';
like to_vtt($cues), qr/\AWEBVTT\n\n00:00:01\.000 --> 00:00:03\.500\nHello/, 'to_vtt';
is convert("WEBVTT\n\nNOTE hi\n\n01:02.5 --> 01:04.000 align:start\nA\n", 'srt'), "1\n00:01:02,500 --> 00:01:04,000\nA\n", 'WebVTT to SRT';
is convert("WEBVTT\n\n01:02.5 --> 01:04.000 align:start\nA\n", 'vtt'), "WEBVTT\n\n00:01:02.500 --> 00:01:04.000 align:start\nA\n", 'cue settings kept';
ok !eval { convert($srt, 'ass'); 1 }, 'unknown target format dies';
is_deeply [map { [$_->{start}, $_->{end}] } @{ shift_cues($cues, -1000) }], [[0, 2500], [2000, 1000]], 'shift';
my ($fixed, $n) = repair($cues);
is_deeply [map { $_->{text} } @$fixed], ['First', "Hello\nworld", 'Second'], 'repair sorts';
is $n, 3, 'repair counts the changes';
ok !(grep { $_->{end} <= $_->{start} } @$fixed), 'every cue ends after it starts';
is $cues->[1]{end}, 2000, 'the input is not changed';
is from_ms(3723004, ','), '01:02:03,004', 'from_ms';
is to_ms('1:02:03.4'), 3723400, 'to_ms';
is to_ms('nope'), undef, 'to_ms of something else';
ok is_vtt("\x{FEFF}WEBVTT\n"), 'is_vtt with a byte order mark';
is scalar @{ parse('no cues here') }, 0, 'no cues';

done_testing;
