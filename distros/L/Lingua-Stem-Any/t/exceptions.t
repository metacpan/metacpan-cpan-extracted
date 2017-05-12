use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 8;
use Lingua::Stem::Any;

my $stemmer = new_ok 'Lingua::Stem::Any', [language => 'en'];

can_ok $stemmer, 'exceptions';

is_deeply(
    [$stemmer->stem(qw( mice pants ))],
    [qw( mice pant )],
    'stemming using defaults without exceptions'
);

$stemmer->exceptions({
    en => {
        mice  => 'mouse',
        pants => 'pants',
    }
});

is_deeply(
    [$stemmer->stem(qw( mice pants ))],
    [qw( mouse pants )],
    'stemming using exceptions via method'
);

$stemmer = new_ok 'Lingua::Stem::Any', [
    language   => 'en',
    exceptions => {
        en => {
            mice  => 'mouse',
            pants => 'pants',
        },
    },
];

is_deeply(
    [$stemmer->stem(qw( mice pants ))],
    [qw( mouse pants )],
    'stemming using exceptions via instantiator'
);

$stemmer = new_ok 'Lingua::Stem::Any', [language => 'en'];

is_deeply(
    [$stemmer->stem(qw( mice pants ))],
    [qw( mice pant )],
    'exceptions only affect object instance'
);
