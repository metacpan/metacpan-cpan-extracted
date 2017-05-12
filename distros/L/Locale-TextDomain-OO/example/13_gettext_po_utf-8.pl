#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use utf8;
use Carp qw(confess);
use English qw(-no_match_vars $OS_ERROR);
use Locale::TextDomain::OO;
use Locale::TextDomain::OO::Lexicon::File::PO;

our $VERSION = 0;

Locale::TextDomain::OO::Lexicon::File::PO
    ->new(
        logger => sub {
            my ($message, $arg_ref) = @_;
            () = print "$arg_ref->{type}: $message\n";
            return;
        },
    )
    ->lexicon_ref({
        search_dirs => [ './LocaleData' ],
        decode      => 1, # from UTF-8, see header of po/mo file
        data        => [
            # map category and domain to q{}
            '*::' => '*/LC_MESSAGES/example.po',
        ],
    });

my $loc = Locale::TextDomain::OO->new(
    language => 'ru',
    logger   => sub { () = print shift, "\n" },
    plugins  => [ qw( Expand::Gettext ) ],
);
$loc->expand_gettext->modifier_code(
    sub {
        my ( $value, $attribute ) = @_;
        $loc->language eq 'ru'
            or return $value;
        if ( $attribute eq 'accusative' ) {
            $value =~ s{ква}{кве}xms; # very primitive, only for this example
        }
        return $value;
    },
);

# all unicode chars encode to UTF-8
binmode STDOUT, ':encoding(utf-8)'
    or confess "Binmode STDOUT\n$OS_ERROR";

# run translations
() = print map {"$_\n"}
    $loc->__(
        'not existing text',
    ),
    $loc->__(
        'book',
    ),
    $loc->__x(
        'He lives in {town}.',
        town => 'Москва',
    ),
    $loc->__nx(
        '{books :num} book',
        '{books :num} books',
        1,
        books => 1,
    ),
    $loc->__nx(
        '{books :num} book',
        '{books :num} books',
        3, ## no critic (MagicNumbers)
        books => 3,
    ),
    $loc->__nx(
        '{books :num} book',
        '{books :num} books',
        5, ## no critic (MagicNumbers)
        books => 5,
    ),
    $loc->__p(
        'appointment',
        'date',
    ),
    $loc->__npx(
        'appointment',
        'This is {dates :num} date.',
        'This are {dates :num} dates.',
        1,
        dates => 1,
    ),
    $loc->__npx(
        'appointment',
        'This is {dates :num} date.',
        'This are {dates :num} dates.',
        3, ## no critic (MagicNumbers)
        dates => 3,
    ),
    $loc->__npx(
        'appointment',
        'This is {dates :num} date.',
        'This are {dates :num} dates.',
        5, ## no critic (MagicNumbers)
        dates => 5,
    );

# $Id: 13_gettext_po_utf-8.pl 546 2014-10-31 09:35:19Z steffenw $

__END__

Output:

debug: Lexicon "de::" loaded from file "LocaleData/de/LC_MESSAGES/example.po".
debug: Lexicon "ru::" loaded from file "LocaleData/ru/LC_MESSAGES/example.po".
Using lexicon "ru::". msgstr not found for msgctxt=undef, msgid="not existing text".
not existing text
книга
Он живет в Москве.
1 книга
3 книги
5 книг
воссоединение
Это 1 воссоединение.
Это 3 воссоединения.
Эти 5 воссоединения.
