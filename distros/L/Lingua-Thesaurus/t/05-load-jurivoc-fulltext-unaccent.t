#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use Lingua::Thesaurus;

my $db_file    = 'TEST.sqlite';
my @data_files = ("$FindBin::Bin/data/excerpt_jurivoc_fre.dmp");

unlink $db_file;
my $thesaurus = Lingua::Thesaurus->new(SQLite => {
  dbname => $db_file,
  params => {use_fulltext => 1,
             use_unaccent => 1},
 });

$thesaurus->load(Jurivoc => @data_files);

plan tests => 1;

ok (1, "$db_file loaded with fulltext index and 'unaccent' tokenizer");

