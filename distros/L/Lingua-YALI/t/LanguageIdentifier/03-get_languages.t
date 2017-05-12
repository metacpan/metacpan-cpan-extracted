use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;

use Lingua::YALI::LanguageIdentifier;


BEGIN { use_ok('Lingua::YALI::LanguageIdentifier') };
my $identifier = Lingua::YALI::LanguageIdentifier->new();

my $l1 = $identifier->get_languages();
ok(scalar @$l1 == 0, "nothing was added ");

ok($identifier->add_language("ces", "slk", "deu") == 3, "three new languages were added");

my $l2 = $identifier->get_languages();
is( (scalar grep { /ces/ } @$l2), 1, "ces was added");
is( (scalar grep { /slk/ } @$l2), 1, "slk was added");
is( (scalar grep { /deu/ } @$l2), 1, "des was added");
is( (scalar grep { /spa/ } @$l2), 0, "spa wasn't added");

ok($identifier->remove_language("ces") == 1, "removing added language");

my $l3 = $identifier->get_languages();
is( (scalar grep { /ces/ } @$l3), 0, "ces was removed");
is( (scalar grep { /slk/ } @$l3), 1, "slk was added");
is( (scalar grep { /deu/ } @$l3), 1, "des was added");
is( (scalar grep { /spa/ } @$l3), 0, "spa wasn't added");

ok($identifier->remove_language("spa") == 0, "removing language that was not added");

my $l4 = $identifier->get_languages();
is( (scalar grep { /ces/ } @$l4), 0, "ces was removed");
is( (scalar grep { /slk/ } @$l4), 1, "slk was added");
is( (scalar grep { /deu/ } @$l4), 1, "des was added");
is( (scalar grep { /spa/ } @$l4), 0, "spa wasn't added");

ok($identifier->add_language("ces", "slk", "deu") == 1, "one new languages were added");

my $l5 = $identifier->get_languages();
is( (scalar grep { /ces/ } @$l5), 1, "ces was added");
is( (scalar grep { /slk/ } @$l5), 1, "slk was added");
is( (scalar grep { /deu/ } @$l5), 1, "des was added");
is( (scalar grep { /spa/ } @$l5), 0, "spa wasn't added");
