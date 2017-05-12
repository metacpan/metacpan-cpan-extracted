use utf8;
use open qw(:std :utf8);

use Test::More qw(no_plan);
use Test::Exception;

use Lingua::RU::OpenCorpora::Tokenizer::List;
use Lingua::RU::OpenCorpora::Tokenizer::Vectors;

my %tests = (
    ok => {
        exceptions => [qw(
            Yahoo!
            AC/DC
        )],
        prefixes => [qw(
            квази
            анти
        )],
        hyphens => [qw(
            а-ля
            акустико-электрическая
            аль-джазира
        )],
        vectors => [qw(
            0
            8
            16
        )],
    },
    nok => {
        exceptions => [qw(
            хитрое_слово_с_нижним_подчеркиванием
        )],
        prefixes => [qw(
            несуществующийпрефикс
        )],
        hyphens => [qw(
            по-умолчанию
        )],
        vectors => [qw(
            9999999999
            -1
        )],
    },
);

for my $list (qw(exceptions prefixes hyphens)) {
    my $obj;
    lives_ok { $obj = Lingua::RU::OpenCorpora::Tokenizer::List->new($list) } "$list: constructor";

    ok defined $obj, "$list: defined";
    ok defined $obj->{version}, "$list: version";

    for my $t (@{ $tests{ok}->{$list} }) {
        ok $obj->in_list($t), "$list: $t";
    }

    for my $t (@{ $tests{nok}->{$list} }) {
        ok !$obj->in_list($t), "$list: $t";
    }
}

my $obj;
lives_ok { $obj = Lingua::RU::OpenCorpora::Tokenizer::Vectors->new } 'vectors: constructor';

ok defined $obj, 'vectors: defined';
ok defined $obj->{version}, 'vectors: version';

for my $t (@{ $tests{ok}->{vectors} }) {
    ok defined $obj->in_list($t), "vectors: $t";
}

for my $t (@{ $tests{nok}->{vectors} }) {
    ok !defined $obj->in_list($t), "vectors: $t";
}
