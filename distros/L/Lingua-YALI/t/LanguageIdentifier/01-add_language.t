use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

use Lingua::YALI::LanguageIdentifier;


BEGIN { use_ok('Lingua::YALI::LanguageIdentifier') };
my $identifier = Lingua::YALI::LanguageIdentifier->new();

ok($identifier->add_language("ces") == 1, "single language was added");
ok($identifier->add_language("ces", "slk", "deu") == 2, "two new languages were added");
dies_ok { $identifier->add_language("_____NONEXISTING_____") } "adding nonexisting language";
