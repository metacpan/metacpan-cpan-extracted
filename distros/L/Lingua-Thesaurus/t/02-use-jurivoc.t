#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;
use Lingua::Thesaurus;

plan tests => 14;

my $db_file    = 'TEST.sqlite';
my $thesaurus = Lingua::Thesaurus->new(SQLite => $db_file);

my @terms   = $thesaurus->search_terms('accord*');
my $n_terms = @terms;
ok ($n_terms, "found $n_terms terms 'accord*'");

my $term = $thesaurus->fetch_term('ACCÈS À UN TRIBUNAL');
my $SN   = $term->SN;
is ($SN, "seulement au sens de l'art. 29a Cst. et de l'art. 6 CEDH; au sens de l'art. 5 par. 4 CEDH, utiliser CONTRÔLE DE LA DÉTENTION & AUTORITÉ JUDICIAIRE(TRIBUNAL)", "continuation line OK");

is ($term->origin, 'TF', "origin TF");

my @UF = $term->UF;
is(scalar(@UF), 5, "5 UF terms for 'ACCÈS À UN TRIBUNAL'");

my $first_UF = $term->UF;
is($first_UF, "accès", "scalar UF 'ACCÈS À UN TRIBUNAL' is 'accès'");

ok(defined $first_UF->origin, "origin is defined");

$term = $thesaurus->fetch_term('action tardive');
is ($term->origin, 'GE', "action tardive origin GE");

# same term in both thesauri
@terms = $thesaurus->search_terms('RETARD');
my @origins = sort map {$_->origin} @terms;
is_deeply(\@origins, [qw/GE TF/], "'RETARD' in both thesauri");


# API with specific origin
@terms = $thesaurus->search_terms('RETARD', 'TF');
@origins = sort map {$_->origin} @terms;
is_deeply(\@origins, [qw/TF/], "'RETARD' from one specific origin");

$term = $thesaurus->fetch_term('RETARD', 'TF');
is ($term->origin, 'TF', "RETARD, origin TF");

$term = $thesaurus->fetch_term('RETARD', 'GE');
is ($term->origin, 'GE', "RETARD, origin GE");


# special relations
$term = $thesaurus->fetch_term("ACCORD(EXAMEN DES DEMANDES D'ASILE)");
my @SA = $term->SA;
is_deeply(\@SA, ["ACCORD BILATÉRAL EN MATIÈRE DE POLICE",
                 "ACCORD BILATÉRAL EN MATIÈRE D'ENTRAIDE JUDICIAIRE"], "SA");
$SN = $term->SN;
like($SN, qr/examen d'une demande d'asile/, 'SN');


# Test loading the same file a 2nd time (2nd creation of the Term class)
undef $thesaurus;
$thesaurus = Lingua::Thesaurus->new(SQLite => $db_file);
@terms   = $thesaurus->search_terms('accord*');
$n_terms = @terms;
ok ($n_terms, "found again $n_terms terms 'accord*'");



