#!/usr/bin/perl

#
# This script was initialy used to fill the db
# used by the test with test data.
#

use strict;
use warnings;

use DBI;

my $db = '../t/lexicon.db';

die "SQLite database $db not found: $!" unless -f $db;

my $dbh = DBI->connect("dbi:SQLite:dbname=$db", "", "", { AutoCommit => 1, PrintError => 0, });

my @lexicon = (
               { id => 1, lex => '*',   lang => 'de', lex_key => 'Hello World!',    lex_value => 'Hallo Welt!', },
               { id => 2, lex => '*',   lang => 'en', lex_key => 'Hello World!',    lex_value => 'Hello World!', },
               { id => 3, lex => '*',   lang => 'de', lex_key => 'This is a [_1].', lex_value => 'Dies ist ein [_1].', },
               { id => 4, lex => '*',   lang => 'en', lex_key => 'This is a [_1].', lex_value => 'This is a [_1].', },
               { id => 5, lex => 'foo', lang => 'de', lex_key => 'Lex Foo',         lex_value => 'Lexikon "foo", de', },
               { id => 6, lex => 'foo', lang => 'en', lex_key => 'Lex Foo',         lex_value => 'Lexicon "foo", en', },
              );

$dbh->do("DELETE FROM `lexicon`;");

foreach (@lexicon) {
    $dbh->do(  "INSERT INTO `lexicon` (`id`, `lang`, `lex`, `lex_key`, `lex_value`) VALUES ('"
             . $_->{id} . "', '"
             . $_->{lang} . "', '"
             . $_->{lex} . "', '"
             . $_->{lex_key} . "', '"
             . $_->{lex_value}
             . "');");

    if ($dbh->err()) { die "$DBI::errstr\n"; }
}

$dbh->disconnect();
