use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use Lingua::YALI::LanguageIdentifier;


BEGIN { use_ok('Lingua::YALI::LanguageIdentifier') };
my $identifier = Lingua::YALI::LanguageIdentifier->new();

ok($identifier->add_language("ces", "slk", "deu") == 3, "three new languages were added");
ok($identifier->remove_language("ces") == 1, "removing added language");
ok($identifier->remove_language("ces") == 0, "removing already removed language");
ok($identifier->remove_language("spa") == 0, "removing language, that was not added");
ok($identifier->remove_language("ces", "slk", "deu") == 2, "removing all remaining languages");
dies_ok { $identifier->remove_language("_____NONEXISTING_____") } "removing nonexisting language";