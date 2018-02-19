#!perl
use Test::More;
use Test::Exception;

use_ok 'MIDI::Ngram';

my $obj;

throws_ok {
    $obj = MIDI::Ngram->new
} qr/Missing required arguments: in_file/, 'file required';

throws_ok {
    $obj = MIDI::Ngram->new( in_file => 'foo' )
} qr/File foo does not exist!/, 'bogus file';

$obj = MIDI::Ngram->new(
    in_file    => 'eg/twinkle_twinkle.mid',
    ngram_size => 3,
    weight     => 1,
);

isa_ok $obj, 'MIDI::Ngram';

is $obj->score, undef, 'score undef';

$obj->process;

my $expected = {
    0 => {
        '67 52 67' => 4,
        '62 55 60' => 3,
        '48 60 67' => 2,
        '48 64 62' => 2,
        '50 65 64' => 2,
        '52 65 50' => 2,
        '52 67 65' => 2,
        '52 67 69' => 2,
        '53 62 55' => 2,
        '53 65 64' => 2,
    }
};

is_deeply $obj->notes, $expected, 'processed weighted notes';

$obj->populate;

isa_ok $obj->score, 'MIDI::Simple';

done_testing();
