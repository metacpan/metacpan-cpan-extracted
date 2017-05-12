#!/usr/bin/perl -w

use strict;
use warnings;
use utf8;

use Test::More tests =>
+	1 # load
+	2 # query tests
+	1 # highlight_spans
;

use_ok 'KSx::Search::WildCardQuery'; # test 1


# ------------- Index Schema ----------- #

use KinoSearch::Schema;
use KinoSearch::Analysis::Tokenizer;
require KinoSearch::FieldType::FullTextType;

my $schema = new KinoSearch::Schema;
$schema->spec_field(
 name => 'content',
 type => new KinoSearch::FieldType::FullTextType
  analyzer => KinoSearch::Analysis::Tokenizer->new,
  highlightable => 1,
);

# ------ Set up the test index ------- #

use KinoSearch::Searcher;
use KinoSearch::Indexer;
use KinoSearch::Store::RAMFolder;

my $index = KinoSearch::Store::RAMFolder->new;

my $first_doc = "dot dote dogs"
	. ' ado' x 200; # make sure do* doesn’t match ‘ado’
my $invindexer = KinoSearch::Indexer->new(
 index => $index, schema => $schema
);
$invindexer->add_doc( { content => $_ } )
	for $first_doc,
	    "do doing",
	    'this is not matched by the query';
$invindexer->commit;

# ------ Perform the query tests ------- #

my $searcher = KinoSearch::Searcher->new( index => $index, );

my $q = new KSx::Search::WildCardQuery term => 'do*', field => 'content';
my $hits = eval{$searcher->hits( query => $q )};
is $hits->total_hits, 2, 'do* matches the right docs';
my $hit = $hits->next;
like $hit->{content}, qr/doing/, 'and they\'re in the right order';

# ------ and test highlight_spans ------- #

#warn join '-', $q->make_weight(searchable => $searcher)->highlight_spans;
is join(' ', sort
	map {
		my $start = $_->get_offset;
		substr($first_doc, $start, $_->get_length)
	} @{ $q->make_compiler(searchable => $searcher)->highlight_spans(
		searchable => $searcher,
		doc_vec    => $searcher->fetch_doc_vec(
		                  $hits->next->get_doc_id
		              ),
		field      => 'content'
	  ) }
   ), 'dogs dot dote', 'highlight_spans';
