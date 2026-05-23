use strict; use warnings;
use Test::More;
use Email::Address::List;

# An addr-spec (local-part@domain) should never contain
# whitespace or invisible format characters. They sneak in via
# copy/paste and produce undeliverable mail.
#
# Test the following:
#   - ASCII whitespace (space, tab, ...)
#   - Unicode whitespace (NBSP, EM SPACE, IDEOGRAPHIC SPACE, ...)
#   - Unicode format characters \p{Cf} (ZWSP, ZWJ, ZWNJ, BOM,
#     soft hyphen, bidi marks, ...)

sub addr_of {
    my $line = shift;
    my @list = Email::Address::List->parse($line);
    return undef unless @list == 1 && $list[0]{type} eq 'mailbox';
    return $list[0]{value}->address;
}

# name => character. Mix of Unicode general categories \p{Z}
# (separators), other \p{White_Space}, and \p{Cf} (format).
my @cases = (
    [ 'SPACE'                  => " "        ],
    [ 'TAB'                    => "\t"       ],
    [ 'U+00A0 NO-BREAK SPACE'  => "\x{00A0}" ],
    [ 'U+1680 OGHAM SPACE MARK'=> "\x{1680}" ],
    [ 'U+2003 EM SPACE'        => "\x{2003}" ],
    [ 'U+202F NARROW NBSP'     => "\x{202F}" ],
    [ 'U+3000 IDEOGRAPHIC SP'  => "\x{3000}" ],
    [ 'U+00AD SOFT HYPHEN'     => "\x{00AD}" ],
    [ 'U+200B ZERO WIDTH SP'   => "\x{200B}" ],
    [ 'U+200C ZWNJ'            => "\x{200C}" ],
    [ 'U+200D ZWJ'             => "\x{200D}" ],
    [ 'U+200E LRM'             => "\x{200E}" ],
    [ 'U+200F RLM'             => "\x{200F}" ],
    [ 'U+2060 WORD JOINER'     => "\x{2060}" ],
    [ 'U+FEFF ZWNBSP / BOM'    => "\x{FEFF}" ],
);

# Each character, in every position around or inside the addr-spec.
for my $case (@cases) {
    my ($name, $char) = @$case;

    is addr_of("foo\@example.com$char"), 'foo@example.com',
        "trailing $name stripped";

    is addr_of("${char}foo\@example.com"), 'foo@example.com',
        "leading $name stripped";

    is addr_of("foo${char}\@example.com"), 'foo@example.com',
        "$name before \@ stripped";

    is addr_of("foo\@${char}example.com"), 'foo@example.com',
        "$name after \@ stripped";

    is addr_of("foo\@example${char}.com"), 'foo@example.com',
        "$name inside domain stripped";

    is addr_of("<foo\@example.com$char>"), 'foo@example.com',
        "$name inside <...> stripped";
}

# Display name + angle-addr: address cleaned, phrase preserved.
{
    my @list = Email::Address::List->parse(
        qq{"Jane Doe" <foo\@example.com\x{200B}>});
    is scalar @list, 1, 'name-addr with U+200B parsed as one mailbox';
    is $list[0]{type}, 'mailbox', '...of type mailbox';
    is $list[0]{value}->address, 'foo@example.com',
        '...with U+200B stripped from address part';
    is $list[0]{value}->phrase, 'Jane Doe',
        '...and display name unchanged';
}

# After cleanup the address is pure ASCII -- not_ascii must be 0
# so downstream skip_not_ascii / loop-prevention checks behave.
{
    my @list = Email::Address::List->parse("foo\@example.com\x{200B}");
    is $list[0]{not_ascii}, 0,
        'cleaned address reported as ASCII (not_ascii=0)';
}

# Comma-separated list: one address with invisibles, one without.
{
    my @list = Email::Address::List->parse(
        "foo\@example.com\x{200B}, bar\@example.com");
    is scalar @list, 2, 'two mailboxes in comma list';
    is $list[0]{value}->address, 'foo@example.com',
        '...first address cleaned';
    is $list[1]{value}->address, 'bar@example.com',
        '...second address unaffected';
}

# Multiple distinct invisibles in one address all stripped.
is addr_of("\x{FEFF}foo\x{200B}\@example.com\x{200D}"),
    'foo@example.com',
    'multiple distinct invisible chars all stripped';

done_testing();
