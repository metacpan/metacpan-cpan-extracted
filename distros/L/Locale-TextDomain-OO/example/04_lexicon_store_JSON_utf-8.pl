#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use utf8;
use Locale::TextDomain::OO::Lexicon::Hash;
use Locale::TextDomain::OO::Lexicon::StoreJSON;
use Locale::TextDomain::OO::Singleton::Lexicon;

our $VERSION = 0;

# switch of perlcritic because of po-file similar writing
## no critic (InterpolationOfLiterals EmptyQuotes NoisyQuotes)
Locale::TextDomain::OO::Lexicon::Hash
    ->new(
        logger => sub { () = print shift, "\n" },
    )
    ->lexicon_ref({
        'en-gb:cat:dom' => [
            {
                msgid  => "",
                msgstr => ""
                    . "Content-Type: text/plain; charset=UTF-8\n"
                    . "Plural-Forms: nplurals=1; plural=n != 1;\n",
            },
            {
                msgctxt      => "appointment",
                msgid        => "date for GBP",
                msgid_plural => "dates for GBP",
                msgstr       => [
                    "date for £",
                    "dates for £",
                ],
            },
        ],
    });
## use critic (InterpolationOfLiterals EmptyQuotes NoisyQuotes)

# To see how the filter is working see test "t/04_lexicon_store_JSON.t".
() = print
    Locale::TextDomain::OO::Lexicon::StoreJSON->new->copy->to_json,
    "\n\n",
    Locale::TextDomain::OO::Lexicon::StoreJSON->new->copy->to_javascript,
    "\n",
    Locale::TextDomain::OO::Lexicon::StoreJSON->new->copy->to_html;

#$Id: 04_lexicon_store_JSON_utf-8.pl 604 2015-08-09 16:47:36Z steffenw $

__END__

Output with all lexicons "en-gb:cat:dom" and the default "i-default::":

Lexicon "en-gb:cat:dom" loaded from hash.
{
    "en-gb:cat:dom" : {
        "" : {
            "plural"   : "n != 1",
            "charset"  : "UTF-8",
            "nplurals" : 1
        },
        "date for GBP{PLURAL_SEPARATOR}dates for GBP{MSG_KEY_SEPARATOR}appointment" : {
            "msgstr" : [
                "date for £",
                "dates for £"
            ]
        }
    },
    "i-default::" : {
        "" : {
            "plural"   :"n != 1",
            "nplurals" : 2
        }
    }
}

var localeTextDomainOOLexicon = { ... same like before ... };

<script type="text/javascript"><!--
var localeTextDomainOOLexicon = { ... same like before ... };
--></script>
