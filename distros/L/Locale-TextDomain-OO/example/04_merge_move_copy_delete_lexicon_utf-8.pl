#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use utf8;
use Data::Dumper ();
use Locale::TextDomain::OO::Lexicon::Hash;
use Locale::TextDomain::OO::Singleton::Lexicon;

our $VERSION = 0;

# switch of perlcritic because of po-file similar writing
## no critic (InterpolationOfLiterals EmptyQuotes NoisyQuotes)
my $hash_lexicon = Locale::TextDomain::OO::Lexicon::Hash
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
my $lexicon = Locale::TextDomain::OO::Singleton::Lexicon->instance;
$lexicon->logger( $hash_lexicon->logger );
$lexicon->copy_lexicon('i-default::' => 'i-default:cat:dom');
$lexicon->merge_lexicon('i-default::', 'en-gb:cat:dom' => 'en:cat:dom');
$lexicon->delete_lexicon('i-default::');
$lexicon->move_lexicon('i-default:cat:dom', 'i-default::dom');
() = print {*STDOUT} Data::Dumper ## no critic (LongChainsOfMethodCalls)
    ->new([ $lexicon->data ])
    ->Deepcopy(1)
    ->Indent(1)
    ->Quotekeys(0)
    ->Sortkeys(1)
    ->Terse(1)
    ->Useqq(1)
    ->Dump;

## use critic (InterpolationOfLiterals EmptyQuotes NoisyQuotes)

#$Id: 04_merge_move_copy_delete_lexicon_utf-8.pl 698 2017-09-28 05:21:05Z steffenw $

__END__

Output:

Lexicon "en-gb:cat:dom" loaded from hash.
Lexicon "i-default::" copied to "i-default:cat:dom".
Lexicon "i-default::", "en-gb:cat:dom" merged to "en:cat:dom".
Lexicon "i-default::" deleted.
Lexicon "i-default:cat:dom" moved to "i-default::dom".
{
  "en-gb:cat:dom" => {
    "" => {
      charset => "UTF-8",
      nplurals => 1,
      plural => "n != 1",
      plural_code => sub { "DUMMY" }
    },
    "date for GBP\0dates for GBP\4appointment" => {
      msgstr => [
        "date for \x{a3}",
        "dates for \x{a3}"
      ]
    }
  },
  "en:cat:dom" => {
    "" => {
      charset => "UTF-8",
      nplurals => 1,
      plural => "n != 1",
      plural_code => sub { "DUMMY" }
    },
    "date for GBP\0dates for GBP\4appointment" => {
      msgstr => [
        "date for \x{a3}",
        "dates for \x{a3}"
      ]
    }
  },
  "i-default::dom" => {
    "" => {
      nplurals => 2,
      plural => "n != 1",
      plural_code => sub { "DUMMY" }
    }
  }
}
