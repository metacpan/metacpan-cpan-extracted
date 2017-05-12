#!perl
use strict;
use warnings FATAL => 'all';

use Test::More;
use Lingua::Thesaurus;

plan tests => 4;

my $db_file    = 'TEST.sqlite';
my $thesaurus = Lingua::Thesaurus->new(SQLite => $db_file);

# fulltext search with wrong accent
my @terms   = $thesaurus->search_terms('activite NOT absence');
my $n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'activite'");

# also wrong accent (on purpose)
@terms   = $thesaurus->search_terms('econôm*');
$n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'econôm'");

# parenthesis handling
@terms   = $thesaurus->search_terms('ACCORD(EXAMEN');
$n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'ACCORD(EXAMEN'");

@terms   = $thesaurus->search_terms("ACCORD(EXAMEN DES DEMANDES D'ASILE)");
$n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'ACCORD(EXAMEN DES DEMANDES D'ASILE)'");

# NOTE : at present, the END section of DBI causes a core dump when using
# a tokenizer in a SQLite fulltext table from a different process than
# the one that created the database. I'm not sure about the cause ... probably
# something to do with memory management in DBD::SQLite C code for destroying
# tokenizers.
# For the moment, use the dirty hack below to bypass the END section.

use POSIX;
POSIX::_exit(0);
