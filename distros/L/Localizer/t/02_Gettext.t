use strict;
use warnings;
use utf8;
use Test::More;

use Localizer::Style::Gettext;
use Localizer::Resource;

subtest 'gettext style' => sub {
    my $de = Localizer::Resource->new(
        dictionary => +{
            'Hello, World!'                  => 'Hallo, Welt!',
            'Double %dubbil(%1)'             => 'Doppelt %dubbil(%1)',
            'You have %*(%1,piece) of mail.' => 'Sie haben %*(%1,Poststueck,Poststuecken).',
            'Price: %#(%1)'                  => 'Preis: %#(%1)',
            '%1()'                           => '%1()',
            '%1 %2 %*'                       => '%* %2 %1',
            '%1%2%*'                         => '%*%2%1',
            '\n\nKnowledge\nAnd\nNature\n\n' =>
"\n\nIch wuenschte recht gelehrt zu werden,\nUnd moechte gern, was auf der Erden\nUnd in dem Himmel ist, erfassen,\nDie Wissenschaft und die Natur.\n\n",
            '_key'            => '_schlüssel',
            '%% ~ [ ]'        => '%% \\% ~ [ ]',
            '%% \\% ~ [ ]'    => '%% \\% ~ [ ]',
            '%unknown()'      => '%unknown()',
            q{'}              => q{'},
            q{rock'n'roll %1} => q{rock'n'roll %1},
            q{f'b!m!}         => q{f'b!m!},
        },
        format    => Localizer::Style::Gettext->new,
        functions => {
            dubbil => sub { return $_[0] * 2 },
        },
        precompile => 0,
    );

    is $de->maketext('Hello, World!'), 'Hallo, Welt!', 'simple case';
    is $de->maketext('Double %dubbil(%1)', 7), 'Doppelt 14';
    is $de->maketext('You have %*(%1,piece) of mail.', 1), 'Sie haben 1 Poststueck.';
    is $de->maketext('You have %*(%1,piece) of mail.', 10), 'Sie haben 10 Poststuecken.';
    is $de->maketext('Price: %#(%1)', 1000000), 'Preis: 1,000,000';
    is $de->maketext('%1 %2 %*', 1, 2, 3), '123 2 1', 'asterisk interpolation';
    is $de->maketext('%1%2%*', 1, 2, 3), '12321', 'concatenated variables';
    is $de->maketext('%1()', 10), '10()', 'concatenated variables';
    is $de->maketext('_key'), '_schlüssel', "keys which start with";
    is $de->maketext("\\n\\nKnowledge\\nAnd\\nNature\\n\\n"), "\n\nIch wuenschte recht gelehrt zu werden,\nUnd moechte gern, was auf der Erden\nUnd in dem Himmel ist, erfassen,\nDie Wissenschaft und die Natur.\n\n", 'multiline';
    is $de->maketext('%% \\% ~ [ ]'), '%% \\\\% ~ [ ]', 'Special chars';

    is $de->maketext(q{'}), q{'}, 'One more special char';
    is $de->maketext(q{rock'n'roll %1}, 'show'), q{rock'n'roll show}, 'Include single quote in text';
    is $de->maketext(q{f'b!m!}), q{f'b!m!}, 'One more special char';

    eval { $de->maketext('%unknown()') };
    like $@, qr(Language resource compilation error.);
};

done_testing;

