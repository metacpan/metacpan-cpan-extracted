use strict;
use warnings;
use utf8;
use Test::More;

use Localizer::Resource;
use Localizer::Style::Maketext;

subtest 'basic' => sub {
    my $ja = Localizer::Resource->new(
        dictionary => {
            'Hi, %1.'          => 'こんにちは、%1',
            'Wow'              => 'おー',
            'Oops [numf,1000]' => 'うーぷす [numf,1000]',
        },
    );
    is($ja->maketext('Hi, %1.', 'じごろうさん'), 'こんにちは、じごろうさん');
    is($ja->maketext('Wow'), 'おー');
};

subtest 'basic' => sub {
    my $ja = Localizer::Resource->new(
        dictionary => {
            'Oops [sprintf,%.1f,103.14]' => 'うーぷす [sprintf,%.1f,103.14]',
        },
        style  => Localizer::Style::Maketext->new,
    );
    is($ja->maketext('Oops [sprintf,%.1f,103.14]'), 'うーぷす 103.1');
};

done_testing;

