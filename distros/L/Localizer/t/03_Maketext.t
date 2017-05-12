use strict;
use warnings;
use utf8;
use Test::More;

use Localizer::Style::Maketext;
use Localizer::Resource;

subtest 'maketext style' => sub {
    my $de = Localizer::Resource->new(
        dictionary => +{
'Hello, World!' => 'Hallo, Welt!',
'Double [dubbil,_1]' => 'Doppelt [dubbil,_1]',
'You have [*,_1,piece] of mail.' => 'Sie haben [*,_1,Poststueck,Poststuecken].',
'Price: [#,_1]' => 'Preis: [#,_1]',
'[_1]()' => '[_1]()',
'[_1] [_2] [_*]' => '[_*] [_2] [_1]',
'[_1,_2,_*]' => '[_*][_2][_1]',
'\n\nKnowledge\nAnd\nNature\n\n' => "\n\nIch wuenschte recht gelehrt zu werden,\nUnd moechte gern, was auf der Erden\nUnd in dem Himmel ist, erfassen,\nDie Wissenschaft und die Natur.\n\n",
'_key' => '_schlüssel',
            'this is ] an error' => 'this is ] an error',
        },
        style => Localizer::Style::Maketext->new,
        functions => {
            dubbil => sub { return $_[0] * 2 },
        },
        precompile => 0,
    );

    is $de->maketext('Hello, World!'), 'Hallo, Welt!', 'simple case';
    is $de->maketext('Double [dubbil,_1]', 7), 'Doppelt 14';
    is $de->maketext('You have [*,_1,piece] of mail.', 1), 'Sie haben 1 Poststueck.';
    is $de->maketext('You have [*,_1,piece] of mail.', 10), 'Sie haben 10 Poststuecken.';
    is $de->maketext('Price: [#,_1]', 1000000), 'Preis: 1,000,000';
    is $de->maketext('[_1] [_2] [_*]', 1, 2, 3), '123 2 1', 'asterisk interpolation';
    is $de->maketext('[_1,_2,_*]', 1, 2, 3), '12321', 'concatenated variables';
    is $de->maketext('[_1]()', 10), '10()', "concatenated variables";
    is $de->maketext('_key'), '_schlüssel', "keys which start with";
    is $de->maketext("\\n\\nKnowledge\\nAnd\\nNature\\n\\n"), "\n\nIch wuenschte recht gelehrt zu werden,\nUnd moechte gern, was auf der Erden\nUnd in dem Himmel ist, erfassen,\nDie Wissenschaft und die Natur.\n\n", 'multiline';

    my $err = eval { $de->maketext('this is ] an error') };
    my $e = $@;
    note $e;
    is $err, undef, "no return from eval";
    like $e, qr/Unbalanced\s'\]',\sin/ms, '$@ shows that ] was unbalanced';
};

done_testing;

