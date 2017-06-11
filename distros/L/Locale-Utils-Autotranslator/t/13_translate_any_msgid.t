#!perl

use strict;
use warnings;

use Moo;
use Test::More tests => 14;
use Test::Differences;
use Test::NoWarnings;

extends qw(
    Locale::Utils::Autotranslator
);

sub translate_text {
    my ($self, $msgid) = @_;

    return "<$msgid>";
}

NOTHING: {
    my $obj = __PACKAGE__
        ->new(
            language  => 'de',
            bytes_max => 80,
        );
    my $msgstr = $obj->translate_any_msgid(<<'EOT');
This is a long message with foo1, bar1, baz1, foo2, bar2, baz2, foo3, bar3, baz3.
EOT
    is
        $msgstr,
        q{},
        'msgstr';
    is
        $obj->translation_count,
        0,
        'translation count';
    is
        $obj->item_translation_count,
        0,
        'item translation count';
    like
        $obj->error,
        qr{ \A \QByte limit exceeded, \E .* \Q ...\E \z }xms,
        'msgid too long';
}

PARAGRAPHS: {
    my $obj = __PACKAGE__
        ->new(
            language  => 'de',
            bytes_max => 2 * 10 + 2,
        );
    my $msgstr = $obj->translate_any_msgid(<<'EOT');
1234567890
1234567890

1234567890
1234567890
EOT
    eq_or_diff
        $msgstr,
        <<'EOT',
<1234567890
1234567890>

<1234567890
1234567890>
EOT
        'msgstr';
    is
        $obj->translation_count,
        1,
        'translation count';
    is
        $obj->item_translation_count,
        2,
        'item translation count';
}

LINES: {
    my $obj = __PACKAGE__
        ->new(
            language  => 'de',
            bytes_max => 2 * 10,
        );
    my $msgstr = $obj->translate_any_msgid(<<'EOT');
1234567890
1234567890

1234567890
1234567890
EOT
    eq_or_diff
        $msgstr,
        <<'EOT',
<1234567890>
<1234567890>

<1234567890>
<1234567890>
EOT
        'msgstr';
    is
        $obj->translation_count,
        1,
        'translation count';
    is
        $obj->item_translation_count,
        4,
        'item translation count';
}

PARAGRAPGS_AND_LINES: {
    my $obj = __PACKAGE__
        ->new(
            language  => 'de',
            bytes_max => 2 * 10 + 2,
        );
    my $msgstr = $obj->translate_any_msgid(<<'EOT');
1234567890
1234567890

1234567890
1234567890
1234567890
EOT
    eq_or_diff
        $msgstr,
        <<'EOT',
<1234567890
1234567890>

<1234567890>
<1234567890>
<1234567890>
EOT
        'msgstr';
    is
        $obj->translation_count,
        1,
        'translation count';
    is
        $obj->item_translation_count,
        4,
        'item translation count';
}
