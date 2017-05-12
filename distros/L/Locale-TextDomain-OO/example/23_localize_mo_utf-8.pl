#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use utf8;
use Carp qw(confess);
use English qw(-no_match_vars $OS_ERROR);
use Locale::TextDomain::OO;
use Locale::TextDomain::OO::Lexicon::File::MO;

our $VERSION = 0;

Locale::TextDomain::OO::Lexicon::File::MO
    ->new(
        logger => sub { () = print shift, "\n" },
    )
    ->lexicon_ref({
        search_dirs => [ './LocaleData' ],
        decode      => 1,
        data        => [
            # map category and domain to q{}
            '*::' => '*/LC_MESSAGES/example.mo',
        ],
    });

my $loc = Locale::TextDomain::OO->new(
    language => 'ru',
    logger   => sub { () = print shift, "\n" },
    plugins  => [ qw( Expand::Maketext::Localize ) ],
);

# all unicode chars encode to UTF-8
binmode STDOUT, ':encoding(utf-8)'
    or confess "Binmode STDOUT\n$OS_ERROR";

# run all translations
() = print map {"$_\n"}
    $loc->localize(
        'book',
    ),
    $loc->localize(
        '§ book',
    ),
    $loc->localize_mp(
        'appointment',
        'date',
    ),
    $loc->Nlocalize(
        'book',
    ),
    $loc->Nlocalize_mp(
        'appointment',
        'date',
    );

# $Id: 23_localize_mo_utf-8.pl 546 2014-10-31 09:35:19Z steffenw $

__END__

Output:

Lexicon "de::" loaded from file "LocaleData/de/LC_MESSAGES/example.mo".
Lexicon "ru::" loaded from file "LocaleData/ru/LC_MESSAGES/example.mo".
книга
§ книга
воссоединение
book
appointment
date
