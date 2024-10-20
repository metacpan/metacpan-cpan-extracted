#!perl
use strict;
use warnings FATAL => 'all';

use Test::More;
use Lingua::Thesaurus;

plan tests => 2;

my $db_file    = 'TEST.sqlite';
my $thesaurus = Lingua::Thesaurus->new(SQLite => $db_file);

# NOTE: without a tokenizer, accents in SQLite FTS4 are not
# case-insensitive. So 'activit�' does not match 'ACTIVIT�' :-((

my @terms   = $thesaurus->search_terms('activit� NOT absence');
my $n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'activit� NOT absence':"
              . join(", ", @terms));

@terms   = $thesaurus->search_terms('ACTIVIT� NOT absence');
$n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'activit� NOT absence':"
              . join(", ", @terms));
