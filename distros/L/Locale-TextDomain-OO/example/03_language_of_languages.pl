#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use Locale::TextDomain::OO;
use Locale::TextDomain::OO::Lexicon::Hash;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    languages => [ qw( de-DE de en-US en ) ],
    plugins   => [ qw( Language::LanguageOfLanguages ) ],
    logger    => sub { () = print shift, "\n" },
);
# No of this languages found in default lexicon during new,
# so fallback to language i-default.
() = print $loc->language, "\n";

# switch of perlcritic because of po-file similar writing
## no critic (InterpolationOfLiterals EmptyQuotes)
Locale::TextDomain::OO::Lexicon::Hash
    ->new(
        logger => sub { () = print shift, "\n" },
    )
    ->lexicon_ref({
        'de::' => [
            {
                msgid  => "",
                msgstr => ""
                    . "Project-Id-Version: \n"
                    . "POT-Creation-Date: \n"
                    . "PO-Revision-Date: \n"
                    . "Last-Translator: \n"
                    . "Language-Team: \n"
                    . "MIME-Version: 1.0\n"
                    . "Content-Type: text/plain; charset=ISO-8859-1\n"
                    . "Content-Transfer-Encoding: 8bit\n"
                    . "Plural-Forms: nplurals=2; plural=n != 1;\n",
            },
        ],
    });
## use critic (InterpolationOfLiterals EmptyQuotes NoisyQuotes)

# Will find lexicon "de::".
$loc->languages( [ qw( de-DE de en-US en ) ] );
() = print $loc->language, "\n";

#$Id: 03_language_of_languages.pl 461 2014-01-09 07:57:37Z steffenw $

__END__

Output:

i-default
Lexicon "de::" loaded from hash.
de
