use 5.014;
use warnings;
use strict;
use Test::More;
use Finance::MIFIR::CONCAT qw/mifir_concat/;
use utf8;

subtest 'mifir config' => sub {
    my $config    = $Finance::MIFIR::CONCAT::config;
    my $countries = $config->{countries};
    is_deeply(
        [sort grep { exists $countries->{$_}->{CONCAT} } keys %$countries],
        [qw/AT BG CY CZ DE DK FI FR GB GR HR HU IE LI LT LV LX NL NO PT RO SE SK SL/],
        'Correct list of countries code with CONCAT present'
    );
};

subtest 'mifir concat' => sub {
    is mifir_concat({
            cc         => 'fr',
            date       => '17-03-1986',
            first_name => 'Elisabeth',
            last_name  => 'Doe',
        }
        ),
        'FR19860317ELISADOE##', 'Elisabeth Doe, born 17th March 1986, French national:';

    is mifir_concat({
            cc         => 'fr',
            date       => '17-03-1986',
            first_name => 'Juan Cvzxasd',
            last_name  => 'Casdffbass Fasdff',
        }
        ),
        'FR19860317JUAN#CASDF', 'Juan Casdffbass, born 17th March 1986, French national:';

    is mifir_concat({
            cc         => 'fr',
            date       => '17-03-1986',
            first_name => 'ZqweO ANDRES',
            last_name  => 'CASTEbeed ROggas',
        }
        ),
        'FR19860317ZQWEOCASTE', 'ZqweO ANDRES, born 17th March 1986, French national:';

    is mifir_concat({
            cc         => 'se',
            date       => '02-12-1944',
            first_name => 'Robert',
            last_name  => 'O’Neal',
        }
        ),
        'SE19441202ROBERONEAL', 'Robert O\'Neal, born 2nd December 1944, national of Sweden and Canada';

    is mifir_concat({
            cc         => 'se',
            date       => '02-12-1944',
            first_name => 'MAPULA Robert',
            last_name  => 'MOGASNS CAR',
        }
        ),
        'SE19441202MAPULMOGAS', 'MAPULA Robert, born 2nd December 1944, national of Sweden and Canada';

    is mifir_concat({
            cc         => 'AT',
            date       => '27-05-1955',
            first_name => 'Dr Joseph',
            last_name  => 'van der Strauss',
        }
        ),
        'AT19550527JOSEPSTRAU', 'Dr Joseph van der Strauss, born 27th May 1955, national of Austria and Germany';

    my @test_cases = (
        ['ßŚáŹł',    'ssazl', 'character check'],
        ['ĄŴÇĎŇ',    'awcdn', 'character check'],
        ['êŽǍţš',    'ezats', 'character check'],
        ['ěęŐÒñ',    'eeoon', 'character check'],
        ['ĝœëşĚ',    'goese', 'character check'],
        ['åÝćųĺ',    'aycul', 'character check'],
        ['ĵăżÔť',    'jazot', 'character check'],
        ['ÄĥÆÜĘ',    'ahaue', 'character check'],
        ['ÁďľĐą',    'adlda', 'character check'],
        ['àÕìÍÂ',    'aoiia', 'character check'],
        ['řïůŰÖ',    'riuuo', 'character check'],
        ['õŒØŁȚ',    'ooolt', 'character check'],
        ['ĽÃĤæè',    'lahae', 'character check'],
        ['éĞğçț',    'eggct', 'character check'],
        ['űŃģÿó',    'ungyo', 'character check'],
        ['ÊúĻčÅ',    'eulca', 'character check'],
        ['ĉâÀŮő',    'caauo', 'character check'],
        ['îŨĹĢÙ',    'iulgu', 'character check'],
        ['ıŢÎýŝ',    'itiys', 'character check'],
        ['ŤŕòŲČ',    'trouc', 'character check'],
        ['íśÏșÛ',    'isisu', 'character check'],
        ['đûËŵĈ',    'duewc', 'character check'],
        ['ùüžĴð',    'uuzjd', 'character check'],
        ['ŜŠÈŔã',    'ssera', 'character check'],
        ['ĆŶäȘũ',    'cyasu', 'character check'],
        ['ÚŞǎöĂ',    'usaoa', 'character check'],
        ['þŻÓøẞ',    'tzoos', 'character check'],
        ['ôļŘķň',    'olrkn', 'character check'],
        ['źĶŷÉń',    'zkyen', 'character check'],
        ['ÌÞŸĜÑ',    'itygn', 'character check'],
        ['heŸĜÑ',    'heygn', 'ascii will be kept'],
        ['heŸ`1ĜÑ',  'heygn', 'other character will be dropped'],
        ['helloooo', 'hello', 'Only first 5 characters will be kept'],
        ['he',       'he###', '# will be filled if less than 5 characters'],
    );

    for my $t (@test_cases) {
        is Finance::MIFIR::CONCAT::_process_name($t->[0]), $t->[1], $t->[2];
    }
};
done_testing();
