#!perl -T

use Lingua::FreeLing3::Utils qw/ngrams/;
use Test::More tests => 21;

my $text=<<'EOT';
E o tempo responde ao tempo
que o tempo tem tanto tempo
quanto tempo o tempo tem.
EOT

### -- Unigrams
my $data = ngrams({n=>1, l=>'pt'}, $text);

is $data->{'tempo'}{count}, 6, 'simple unigram count';
is $data->{'E'}{count}, 1, 'simple unigram count';
is $data->{'tem'}{count}, 2, 'simple unigram count';

is sprintf("%.8f", $data->{'E'}{p}), '0.05000000', 'simple unigram p';
is sprintf("%.8f", $data->{'tempo'}{p}), '0.30000000', 'simple unigram p';
is sprintf("%.8f", $data->{'tem'}{p}), '0.10000000', 'simple unigram p';


### -- Unigrams without <s></s>
$data = undef;
$data = ngrams({n=>1, t=>0, l=>'pt'}, $text);
is $data->{'tempo'}{count}, 6, 'simple unigram count';
is $data->{'E'}{count}, 1, 'simple unigram count';
is $data->{'tem'}{count}, 2, 'simple unigram count';


### -- Bigrams
$data = ngrams({n=>2, l=>'pt'}, $text);

is $data->{'tempo tem'}{count}, 2, 'simple bigram count';
is $data->{'o tempo'}{count}, 3, 'simple bigram count';

is sprintf("%.8f", $data->{'tempo tem'}{p}), '0.33333333', 'simple bigram p';
is sprintf("%.8f", $data->{'o tempo'}{p}), '1.00000000', 'simple bigram p';

### -- Trigrams with accumulative

$data = ngrams({n=>3, l=>'pt', a=>1}, $text);
is ref $data, "ARRAY";
is @$data, 3;
is ref $data->[0], "HASH";
is ref $data->[1], "HASH";
is ref $data->[2], "HASH";
is $data->[0]{tempo}{count}, 6;
is $data->[1]{'tempo tem'}{count}, 2;
is $data->[2]{'o tempo tem'}{count}, 2;

