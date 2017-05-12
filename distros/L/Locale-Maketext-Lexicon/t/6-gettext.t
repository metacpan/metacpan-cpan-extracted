#!/usr/bin/perl -w
use strict;
use Test::More tests => 30;

package Hello::I18N;
use Test::More;
use Tie::Hash;

my $warned;
$SIG{__WARN__} = sub { $warned++ };

use_ok(base => 'Locale::Maketext');
use_ok(
    'Locale::Maketext::Lexicon' => {
	en	=> ['Auto'],
	fr	=> ['Tie'	=> [ 'Tie::StdHash' ]],
	de	=> ['Gettext'	=> \*::DATA],
	zh_tw	=> ['Gettext'	=> 't/messages.mo'],
	zh_cn	=> ['Msgcat'	=> 't/gencat.m'],
	zh_hk   => [
	    'Msgcat'	=> 't/gencat.m',
	    'Gettext'   => 't/messages.po',
	],
	ru	=> ['Gettext'	=> 't/notexist.po'],
        _style => 'gettext',
    },
);

ok(!$warned, 'no warnings on blank lines');

Locale::Maketext::Lexicon->import({
    de_de => ['Gettext'	=> \*::DATA],
    ru    => ['Gettext'	=> 't/notexist.po'],
    _use_fuzzy => 1,
});

package main;

################################################################

ok(my $lh = Hello::I18N->get_handle('en-us'), 'Auto - get_handle');

is(
    $lh->maketext('Heute die Welt'),
    'Heute die Welt',
    'Auto - autofilling'
);

################################################################

ok($lh = Hello::I18N->get_handle('de'), 'Gettext - get_handle');

is(
    $lh->maketext('Hello, World!'),
    'Hallo, Welt!',
    'Gettext - simple case'
);
is(
    $lh->maketext('You have %*(%1,piece) of mail.', 10),
    'Sie haben 10 Poststuecken.',
    'Gettext - complex case'
);
is(
    $lh->maketext('%1 %2 %*', 1, 2, 3),
    '123 2 1',
    'Gettext - asterisk interpolation'
);
is(
    $lh->maketext('%1%2%*', 1, 2, 3),
    '12321',
    'Gettext - concatenated variables'
);
is(
    $lh->maketext('%1()', 10),
    '10()',
    'Gettext - correct parens'
);
is(
    $lh->maketext('__Content-Type'),
    'text/plain; charset=ISO-8859-1',
    'Gettext - metadata'
);
is(
    $lh->maketext('%1()', 10),
    '10()',
    'Gettext - correct parens'
);
is(
    $lh->maketext("\n\nKnowledge\nAnd\nNature\n\n"),
"\n\n".
"Ich wuenschte recht gelehrt zu werden,\n".
"Und moechte gern, was auf der Erden\n".
"Und in dem Himmel ist, erfassen,\n".
"Die Wissenschaft und die Natur.\n\n",
    'Gettext - multiline'
);

is(
    eval { $lh->maketext("The Hitchhiker's Guide to the Galaxy") },
    undef,
    'Gettext - fuzzy entries are ignored'
);

ok($lh = Hello::I18N->get_handle('de_de'), 'Gettext - get_handle on DATA again');
is(
    eval { $lh->maketext("The Hitchhiker's Guide to the Galaxy") },
    'Der Fuehrer des Trampers zur Galaxie',
    'Gettext - fuzzy entries are recognized with _use_fuzzy'
);

################################################################

SKIP: {
    skip("no msgunfmt available", 2) unless `msgunfmt -V` and !$?;

    ok($lh = Hello::I18N->get_handle('zh_tw'), 'Gettext - get_handle');

    is(
	$lh->maketext('This is a test'),
	'這是測試',
	'Gettext - MO File'
    );
}

################################################################

ok($lh = Hello::I18N->get_handle('fr'), 'Tie - get_handle');
$Hello::I18N::fr::Lexicon{"Good morning"} = 'Bon jour';
$Hello::I18N::fr::Lexicon{"Good morning, [_1]"} = 'Bon jour, [_1]';

is(
    $lh->maketext('Good morning'),
    'Bon jour',
    'Tie - simple case'
);

is(
    $lh->maketext('Good morning, %1', 'Sean'),
    'Bon jour, Sean',
    'Tie - complex case'
);

################################################################

ok($lh = Hello::I18N->get_handle('zh_cn'), 'Msgcat - get_handle');
is(
    $lh->maketext(1, 1),
    'First string',
    'Msgcat - simple case'
);
is(
    $lh->maketext(1, 2),
    'Second string',
    'Msgcat - continued string'
);
is(
    $lh->maketext(1, 3),
    'Third string',
    'Msgcat - quote character'
);
is(
    $lh->maketext(1, 4),
    'Fourth string',
    'Msgcat - quote character + continued string'
);

################################################################

ok($lh = Hello::I18N->get_handle('zh_hk'), 'Multiple lexicons - get_handle');

is(
    $lh->maketext(1, 1),
    'First string',
    'Multiple lexicons - first'
);

is(
    $lh->maketext('This is a test'),
    '這是測試',
    'Multiple lexicons - second'
);


__DATA__
msgid ""
msgstr ""
"Project-Id-Version: Test App 0.01\n"
"POT-Creation-Date: 2002-05-02 11:36+0800\n"
"PO-Revision-Date: 2002-05-13 02:00+0800\n"
"Last-Translator: <cpan@audreyt.org>\n"
"Language-Team: German <cpan@audreyt.org>\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=ISO-8859-1\n"
"Content-Transfer-Encoding: 8bit\n"

#: Hello.pm:10
msgid "Hello, World!"
msgstr "Hallo, Welt!"

#: Hello.pm:11
msgid "You have %*(%1,piece) of mail."
msgstr "Sie haben %*(%1,Poststueck,Poststuecken)."

#: Hello.pm:12
msgid "%1()"
msgstr "%1()"

#: Hello.pm:13
msgid "%1 %2 %*"
msgstr "%* %2 %1"

#: Hello.pm:14
msgid "%1%2%*"
msgstr "%*%2%1"

#: Hello.pm:15
msgid ""
"\n"
"\n"
"Knowledge\n"
"And\n"
"Nature\n"
"\n"
msgstr ""
"\n"
"\n"
"Ich wuenschte recht gelehrt zu werden,\n"
"Und moechte gern, was auf der Erden\n"
"Und in dem Himmel ist, erfassen,\n"
"Die Wissenschaft und die Natur.\n"
"\n"

#: Hello.pm:16
#, big, furry, fuzzy
msgid "The Hitchhiker's Guide to the Galaxy"
msgstr "Der Fuehrer des Trampers zur Galaxie"

