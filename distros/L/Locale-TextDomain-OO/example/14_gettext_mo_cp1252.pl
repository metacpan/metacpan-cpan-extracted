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
        decode      => 1, # from cp1252, see header of po/mo file
        data        => [
            # map category and domain to q{}
            '*::' => '*/LC_MESSAGES/example_cp1252.mo',
        ],
    });

my $loc = Locale::TextDomain::OO->new(
    language => 'de',
    logger   => sub { () = print shift, "\n" },
    plugins  => [ qw( Expand::Gettext ) ],
);

# all unicode chars encode to UTF-8
binmode STDOUT, ':encoding(utf-8)'
    or confess "Binmode STDOUT\n$OS_ERROR";

# run all translations
() = print map {"$_\n"}
    $loc->__(
        'This are German umlauts: ä ö ü ß Ä Ö Ü.',
    );

# $Id: 14_gettext_mo_cp1252.pl 546 2014-10-31 09:35:19Z steffenw $

__END__

Output:

Lexicon "de::" loaded from file "LocaleData/de/LC_MESSAGES/example_cp1252.mo".
Das sind deutsche Umlaute: ä ö ü ß Ä Ö Ü.
