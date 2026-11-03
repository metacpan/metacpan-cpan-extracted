use strict;
use warnings;
use Test::More;

use Test::InDistDir;
use Capture::Tiny 'capture';
use Locale::Simple::Scraper 'scrape';

# Only literals whose text the program looks up go into the .pot. A Perl or
# PHP double-quoted literal (or PHP heredoc) holding a variable is not one, nor
# is a Python f-string or bytes literal, nor a JavaScript template literal with
# ${ or a tag. In Perl double quotes every unescaped $ names a variable (or
# does not compile), and so does an @ before a name, ::, ', $, +, -, a digit or
# {. Such a call is skipped and reported; the calls in its arguments
# are still read. Python raw and triple-quoted strings are msgids, raw ones
# keeping their backslashes, and adjacent Python literals join. A JavaScript
# template literal without ${ is a msgid. Whitespace before a literal that is
# read as a whole (PHP heredoc, Rust raw string) is skipped as before any other.

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
        entry('PL inner of interpolation'),
        entry('PL escaped $name and @items and ${name} and %2$s'),
        entry('PL at @ sign, 100% and 5 $'),
        entry('PL single $name @items ${name}'),
        entry('PL lone @ and @. and @! and @, and @% and @@ stay'),
        entry( u8("PL euro \@\x{20ac} and arabic digit \@\x{663} stay") ),
    ],
    php => [
        entry('PHP inner of interpolation'),
        entry('PHP escaped $name and {$name} and %2$s'),
        entry('PHP lone 5 $ and $1 and { brace }'),
        entry('PHP heredoc escaped $name'),
        entry('PHP nowdoc $name stays'),
        entry('PHP single $name {$name} stays'),
        entry('PHP heredoc after a space'),
        entry('PHP joined PHP heredoc after a dot'),
    ],
    rs => [
        entry(q{RS raw after a space \n}),
        entry(q{RS raw with "quotes"}),
        entry( 'RS raw context after a space', msgctxt => 'RS_ctx' ),
    ],
    py => [
        entry(q{PY raw \n stays \d}),
        entry(q{PY raw single \t stays}),
        entry(qq{PY triple "quoted" \t tab\nand a second line}),
        entry(q{PY triple single 'quoted' }),
        entry(q{PY raw triple \n stays}),
        entry( u8("PY unicode prefix \x{e4}") ),
        entry('PY adjacent joined three'),
        entry('PY adjacent over lines'),
        entry('PY adjacent with a comment between'),
        entry('PY adjacent and plus'),
        plural( 'PY one', q{PY many raw \n} ),
        entry( 'PY triple with context', msgctxt => q{PY ctx \d} ),
        entry('0'),
        entry('PY inner of f-string'),
    ],
    js => [
        entry('JS template plain'),
        entry( u8(qq{JS template "double" 'single' ` backtick \x{e4} \n newline}) ),
        entry("JS template\nover two lines"),
        entry('JS template joined'),
        entry('JS dollar $ and brace { alone'),
        entry('JS escaped ${name}'),
        entry('JS inner of template'),
    ],
);

# The call each report shows. Spelled so that t/50, which scrapes this file,
# finds no calls in it.
my $func     = lc 'L';
my %reported = (
    pl  => [ '("PL hello $name', '("PL total $%.2f', '("PL final dollar' ],
    php => ['("PHP hello $name'],
    py  => ['(f"PY f-string'],
    js  => ['(`JS template ${name}'],
);

for my $lang ( sort keys %expected ) {
    my ( $entries, $err ) = scrape_entries("literals.$lang");
    is_deeply( $entries, [ sort_entries( @{ $expected{$lang} } ) ], "$lang: only constant literals give a msgid" );
    for my $call ( @{ $reported{$lang} || [] } ) {
        like(
            $err,
            qr/Expected translation token:\n \|\Q$func$call\E/,
            "$lang: the skipped $func$call... is reported"
        );
    }
}

done_testing;

sub scrape_entries {
    my ($file) = @_;
    my ( $out, $err ) = capture {
        scrape( '--only', "literal-fixtures/\Q$file\E\$", '--output', 'perl' );
    };
    my $VAR1;
    eval $out or die "Cannot read scraper output for $file: $@\n$err";
    my @entries = map {
        my $e = $_;
        +{ map { defined $e->{$_} ? ( $_ => $e->{$_} ) : () } qw( msgid msgid_plural msgctxt domain ) }
    } @{$VAR1};
    return [ sort_entries(@entries) ], $err;
}

sub sort_entries {
    return sort {
        join( "\0", map { $_ // '' } @{$a}{qw( msgctxt msgid )} )
          cmp join( "\0", map { $_ // '' } @{$b}{qw( msgctxt msgid )} )
    } @_;
}
