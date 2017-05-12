#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess);
use English qw(-no_match_vars $OS_ERROR);
use Locale::TextDomain::OO;
use Locale::TextDomain::OO::Lexicon::File::PO;

# be able to read the the file example/lib/MyAutotranslatorCache.pm
use lib './lib';

our $VERSION = 0;

Locale::TextDomain::OO::Lexicon::File::PO
    ->new(
        logger => sub { () = print shift, "\n" },
    )
    ->lexicon_ref({
        search_dirs => [ './LocaleData' ],
        decode      => 1, # from ISO-8859-1, see header of po file
        data        => [
            'de:cache_en:' => 'de/cache_en/example.po',
        ],
    });

my $loc = Locale::TextDomain::OO->new(
    language => 'de',
    category => 'cache_en',
    logger   => sub { () = print shift, "\n" },
    plugins  => [ qw( Expand::Gettext ) ],
);

# run translations
() = print
    $loc->__('static'),
    "\n",
    $loc->__('not in po file'),
    "\n";

# $Id: 18_autotranslation_cached.pl 637 2017-02-23 16:21:35Z steffenw $

__END__

Output:

Lexicon "de:cache_en:" loaded from file "LocaleData/de/cache_en/example.po".
Using lexicon "de:cache_en:". msgstr not found for msgctxt=undef, msgid="not in po file".
statisch
nicht im po File
