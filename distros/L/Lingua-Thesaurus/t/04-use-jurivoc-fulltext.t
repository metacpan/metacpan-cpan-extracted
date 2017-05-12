#!perl
use strict;
use warnings FATAL => 'all';

use Test::More;
use Lingua::Thesaurus;

plan tests => 2;

my $db_file    = 'TEST.sqlite';
my $thesaurus = Lingua::Thesaurus->new(SQLite => $db_file);

# NOTE: without a tokenizer, accents in SQLite FTS4 are not
# case-insensitive. So 'activité' does not match 'ACTIVITÉ' :-((

my @terms   = $thesaurus->search_terms('activité NOT absence');
my $n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'activité NOT absence':"
              . join(", ", @terms));

@terms   = $thesaurus->search_terms('ACTIVITÉ NOT absence');
$n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'activité NOT absence':"
              . join(", ", @terms));
