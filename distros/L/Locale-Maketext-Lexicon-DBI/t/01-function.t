#!perl -T

use strict;
use warnings;

use Test::More tests => 17;

#
#
#

package Hello::I18N;

use strict;
use warnings;

use Test::More;

use_ok('DBI');
use_ok(base => 'Locale::Maketext');

SKIP: {
    my $dbh;
    eval { $dbh = DBI->connect("dbi:SQLite:dbname=t/lexicon.db", "", "", { AutoCommit => 1, PrintError => 0, }); };

    skip "SQLite not installed", 8 if $@;

    require_ok('Locale::Maketext::Lexicon');
    eval {
        Locale::Maketext::Lexicon->import(
                                          {
                                            de => [DBI => [lang => 'de', lex => '*', dbh => $dbh]],
                                            en => [DBI => [lang => 'en', lex => '*', dbh => $dbh]],
                                          }
                                         );
    };
    fail("Lexicon import, namespace '*'") if $@;

    ok(my $lh_en = Hello::I18N->get_handle('en-us'), 'Auto - get_handle en-us');
    ok(my $lh_de = Hello::I18N->get_handle('de-de'), 'Auto - get_handle de-de');

    is($lh_en->maketext('Hello World!'), 'Hello World!', 'DBI - simple case for en');
    is($lh_de->maketext('Hello World!'), 'Hallo Welt!',  'DBI - simple case for de');

    is($lh_en->maketext('This is a [_1].', 'test'), 'This is a test.',    'DBI - interpolation for en');
    is($lh_de->maketext('This is a [_1].', 'test'), 'Dies ist ein test.', 'DBI - interpolation for de');

    $lh_de->fail_with(sub { return $_[1]; });

    is($lh_de->maketext('Lex Foo'), 'Lex Foo', 'DBI - namespace testing w/ fail_with');
}

#
#
#

package Hello::I18N::Again;

use strict;
use warnings;

use Test::More;

use_ok('DBI');
use_ok(base => 'Locale::Maketext');

SKIP: {
    my $dbh;
    eval { $dbh = DBI->connect("dbi:SQLite:dbname=t/lexicon.db", "", "", { AutoCommit => 1, PrintError => 0, }); };

    skip "SQLite not installed", 5 if $@;

    require_ok('Locale::Maketext::Lexicon');
    eval {
        Locale::Maketext::Lexicon->import(
                                          {
                                            de => [DBI => [lang => 'de', lex => 'foo', dbh => $dbh]],
                                            en => [DBI => [lang => 'en', lex => 'foo', dbh => $dbh]],
                                          }
                                         );
    };
    fail("Lexicon import, namespace '*'") if $@;

    ok(my $lh_en = Hello::I18N::Again->get_handle('en-us'), 'Auto - get_handle en-us');
    ok(my $lh_de = Hello::I18N::Again->get_handle('de-de'), 'Auto - get_handle de-de');

    is($lh_de->maketext('Lex Foo'), 'Lexikon "foo", de', 'DBI - namespace testing w/o fail_with');
    is($lh_en->maketext('Lex Foo'), 'Lexicon "foo", en', 'DBI - namespace testing w/o fail_with');
}
