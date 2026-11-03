use strict;
use warnings;
use Test::More;

use Test::InDistDir;
use Capture::Tiny 'capture';
use Locale::Simple::Scraper 'scrape';

# A msgid is stored as the program sees it at run time: each escape the
# language defines inside its string literal becomes the character it stands
# for, so the .pot shows "\n" for a newline. The scraper reads and writes
# bytes, so a character named by its code point arrives as its UTF-8 bytes;
# Go and PHP byte escapes arrive as those bytes. A literal with an escape the
# language rejects is not read, nor is one that changes case in Perl. The
# string "0" is a msgid like any other.

sub u8 {
    my ($text) = @_;
    utf8::encode($text);
    return $text;
}

sub entry {
    my ( $msgid, %more ) = @_;
    return { msgid => $msgid, %more };
}

sub plural {
    my ( $msgid, $msgid_plural ) = @_;
    return { msgid => $msgid, msgid_plural => $msgid_plural };
}

my %expected = (
    pl => [
        entry("PL newline\n"),
        entry("PL tab\tand return\r"),
        entry("PL backslash \\ quote \" dollar \$ at \@ unknown q"),
        entry( u8("PL hex A\x{e4}\x{263A} octal AA named \x{df}\x{f6} control \t") ),
        entry(q{PL single \n stays, \ is one, ' is a quote}),
        entry("PL joined\nPL raw\\t\tPL end"),
        plural( "PL one\n", "PL many\n" ),
        entry("0"),
        entry( "PL context zero", msgctxt => "0" ),
    ],
    js => [
        entry("JS newline\n"),
        entry("JS single 'quote' and tab\t"),
        entry("JS backslash \\ quote \" unknown q 8"),
        entry( u8("JS hex A unicode \x{e4} \x{263A} \x{1F600} pair \x{1F600} octal A") ),
        entry("JS continued line"),
        entry("JS joined\nJS end\t"),
        plural( "JS one\n", "JS many\n" ),
        entry("0"),
        entry( "JS context zero", msgctxt => "0" ),
    ],
    py => [
        entry("PY newline\n"),
        entry("PY single 'quote' and tab\t"),
        entry("PY backslash \\ quote \" keeps \\q"),
        entry( u8("PY hex A unicode \x{e4} \x{1F600} named \x{df} octal A") ),
        entry("PY continued line"),
        entry("PY joined\nPY end\t"),
        plural( "PY one\n", "PY many\n" ),
        entry("0"),
        entry( "PY context zero", msgctxt => "0" ),
    ],
    go => [
        entry("GO newline\n"),
        entry("GO tab\t quote \" backslash \\"),
        entry( u8("GO bytes \x{e4} octal \x{e4} unicode \x{e4} \x{1F600}") ),
        entry(q{GO raw \n stays}),
        entry("GO joined\nGO raw\\t\tGO end"),
        plural( "GO one\n", "GO many\n" ),
        entry("0"),
        entry( "GO context zero", msgctxt => "0" ),
    ],
    rs => [
        entry("RS newline\n"),
        entry("RS tab\t quote \" apostrophe ' backslash \\"),
        entry( u8("RS hex A unicode \x{e4} \x{1F600}") ),
        entry("RS continued line"),
        entry(q{RS raw \n stays}),
        plural( "RS one\n", "RS many\n" ),
        entry("0"),
        entry( "RS context zero", msgctxt => "0" ),
    ],
    tx => [
        entry("TX newline\n"),
        entry("TX tab\t return\r unknown q quote \" backslash \\"),
        entry(q{TX single \n stays, \ is one, ' is a quote}),
        entry("TX joined\nTX raw\\t\tTX end"),
        plural( "TX one\n", "TX many\n" ),
        entry("0"),
        entry( "TX context zero", msgctxt => "0" ),
    ],
    php => [
        entry("PHP newline\n"),
        entry("PHP tab\t dollar \$ quote \" backslash \\ keeps \\q"),
        entry( u8("PHP hex A\x{e4} octal A unicode \x{e4}") ),
        entry(q{PHP single \n stays, \ is one, ' is a quote}),
        entry(qq{PHP heredoc\tdone \\"quoted\\"}),
        entry(q{PHP nowdoc\t stays}),
        entry("PHP joined\nPHP raw\\t\tPHP end"),
        plural( "PHP one\n", "PHP many\n" ),
        entry("0"),
        entry( "PHP context zero", msgctxt => "0" ),
    ],
);

for my $lang ( sort keys %expected ) {
    is_deeply(
        scrape_entries("escapes.$lang"),
        [ sort_entries( @{ $expected{$lang} } ) ],
        "$lang: escapes give the msgid the program sees"
    );
}

{
    my ( $out, $err ) = capture {
        scrape( '--only', 'escape-fixtures/escapes\.pl$', '--no_line_numbers' );
    };
    like( $out, qr/^msgid "PL newline\\n"$/m,                        'po: a newline is written as \n' );
    like( $out, qr/^msgid "PL backslash \\\\ quote \\" dollar/m,     'po: backslash and quote are escaped again' );
    like( $out, qr/^msgid "0"$/m,                                    'po: the msgid "0" is written' );
    like( $out, qr/^msgctxt "0"\nmsgid "PL context zero"$/m,         'po: the context "0" is written' );
}

done_testing;

sub scrape_entries {
    my ($file) = @_;
    my ( $out, $err ) = capture {
        scrape( '--only', "escape-fixtures/\Q$file\E\$", '--output', 'perl' );
    };
    my $VAR1;
    eval $out or die "Cannot read scraper output for $file: $@\n$err";
    return [
        sort_entries(
            map {
                my $e = $_;
                +{ map { defined $e->{$_} ? ( $_ => $e->{$_} ) : () } qw( msgid msgid_plural msgctxt domain ) }
            } @{$VAR1}
        )
    ];
}

sub sort_entries {
    return sort { join( "\0", map { $_ // '' } @{$a}{qw( msgctxt msgid )} ) cmp join( "\0", map { $_ // '' } @{$b}{qw( msgctxt msgid )} ) } @_;
}
