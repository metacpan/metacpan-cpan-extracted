#!/usr/bin/perl -w

# Half of this test script was stolen from KinoSearch’s Highlighter tests
# (as of revision 3122) (with the appropriate modifications).

use strict;
use warnings;
use utf8;

use Test::More tests =>
+	1 # load
+	9 # stolen from KinoSearch::Highlighter
+	9 # KSx:H:S-specific features
;

use_ok 'KSx::Highlight::Summarizer'; # test 1


# Set up the schema
require KinoSearch::Schema;
require KinoSearch::Analysis::Tokenizer;
require KinoSearch::FieldType::FullTextType;
my $schema = new KinoSearch::Schema;
{
 my $analyser = KinoSearch::Analysis::Tokenizer->new;
 $schema->spec_field(
  name => 'content', type =>
   new KinoSearch::FieldType::FullTextType
    analyzer => $analyser,
    highlightable => 1,
 );
 $schema->spec_field(
  name => 'alt', type =>
   new KinoSearch::FieldType::FullTextType
    analyzer => $analyser,
    boost => 0.1,
    highlightable => 1,
 );
}


# ------ KinoSearch::Highlight::Highlighter’s tests (9 of them) ------- #

use KinoSearch::Searcher;
use KinoSearch::Highlight::Highlighter;
use KinoSearch::Indexer;
use KinoSearch::Store::RAMFolder;

my $phi         = "\x{03a6}";
my $encoded_phi = "&(?:#934|Phi);";

my $string = '1 2 3 4 5 ' x 20;    # 200 characters
$string .= "$phi a b c d x y z h i j k ";
$string .= '6 7 8 9 0 ' x 20;
my $with_quotes = '"I see," said the blind man.';
my $indexer   = KinoSearch::Indexer->new(
    index => my $folder = KinoSearch::Store::RAMFolder->new,
    schema => $schema,
);

$indexer->add_doc( { content => $_ } ) for ( $string, $with_quotes );
$indexer->add_doc(
    {   content => "x but not why or 2ee",
        alt     => $string . " and extra stuff so it scores lower",
    }
);
$indexer->add_doc( { content => 'haecceity: you don’t know what that'
	. ' word means, do you? ' . '3 ' x 1000
	. 'Look, here it is again: haecceity'
} );
$indexer->add_doc( { content => "blah blah blah " . 'rhubarb ' x 40
	. "\014 page 2 \014 "
	. "σελίδα 3 \014 " . '42 ' x 1000 . "Seite 4"
} );
$indexer->add_doc({ content => 'abacus ' . 'acrobat ' x 40 . "\f" .
                                  'acrobat ' x 40 . 'abacus' });
$indexer->add_doc({ content => 'bear ' x 40 . 'beaver ' . 'bear ' x 40 .
                                  'beaver ' . 'bear ' x 40 });
$indexer->add_doc({ content => 'cat cat cat carrot cat cat cat' });
$indexer->commit;

my $searcher = KinoSearch::Searcher->new( index => $folder );

my $q = qq|"x y z" AND $phi|;
my $hits = $searcher->hits( query => $q );
my $hit = $hits->next;
my $hl = KSx::Highlight::Summarizer->new(
    searchable => $searcher,
    query      => $q,
    field      => 'content',
);
my $excerpt = $hl->create_excerpt( $hit );
like( $excerpt,
    qr/$encoded_phi.*?z/i, "excerpt contains all relevant terms" );
like(
    $excerpt,
    qr#<strong>x y z</strong>#,
    "highlighter tagged the phrase"
);
like(
    $excerpt,
    qr#<strong>$encoded_phi</strong>#i,
    "highlighter tagged the single term"
);

like( $hl->create_excerpt( $hits->next() ),
    qr/x/,
    "excerpt field with partial hit doesn't cause highlighter freakout" );

$hits = $searcher->hits( query => $q = 'x "x y z" AND b' );
$hl = KSx::Highlight::Summarizer->new(
    searchable => $searcher,
    query      => $q,
    field      => 'content',
);
like( $hl->create_excerpt( $hits->next() ),
    qr/x y z/,
    "query with same word in both phrase and term doesn't cause freakout" );

$hits = $searcher->hits( query => $q = 'blind' );
like(
    KSx::Highlight::Summarizer->new(
        searchable => $searcher,
        query      => $q,
        field      => 'content',
    )->create_excerpt( $hits->next() ),
    qr/quot/, "HTML entity encoded properly" );

$hits = $searcher->hits( query => $q = 'why' );
unlike(
    KSx::Highlight::Summarizer->new(
        searchable => $searcher,
        query      => $q,
        field      => 'content',
    )->create_excerpt( $hits->next() ),
    qr/\.\.\./, "no ellipsis for short excerpt" );

my $term_query = KinoSearch::Search::TermQuery->new(
    field => 'content', term => 'x'
);
$hits = $searcher->hits( query => $term_query );
$hit = $hits->next();
like(
    KSx::Highlight::Summarizer->new(
        searchable => $searcher,
        query      => $term_query,
        field      => 'content',
    )->create_excerpt( $hit ),
    qr/strong/, "specify field highlights correct field..." );
unlike(
    KSx::Highlight::Summarizer->new(
        searchable => $searcher,
        query      => $term_query,
        field      => 'alt',
    )->create_excerpt( $hit ),
    qr/strong/, "... but not another field"
);


# ---- KSx::Highlight::Summarizer-specific tests (9 of them) ---- #

# 1 test for p(re|ost)_tag and encoder in the constructor

$q = qq|"x y z" AND $phi|;
$hits = $searcher->hits( query => $q );
$hit = $hits->next;
$hl = KSx::Highlight::Summarizer->new(
    searchable  => $searcher,
    query       => $q,
    field       => 'content',
    pre_tag => ' Oh look! -->',
    post_tag => '<-- ',
    encoder   => sub { for(my $x = shift) {
		s/(\S)/ord $1/ge; return $_
	}},
);
$excerpt = $hl->create_excerpt( $hit );
like(
    $excerpt,
    qr# Oh look! -->934<-- #i,
    "encoder and p(re|ost)_tag in the constructor"
);


# 5 tests for page-break handling

$hits = $searcher->hits(query => 'page');
$hl = new KSx::Highlight::Summarizer
	searchable => $searcher,
	query      => 'page',
	field      => 'content',
;
like($hl->create_excerpt($hit = $hits->next), qr/&#12;|\cL/,
	'FFs are left alone without a page_h');
$hl = new KSx::Highlight::Summarizer
	searchable => $searcher,
	query      => 'page',
	field      => 'content',
	page_handler => sub {
		my ($hitdoc, $page_no) = @_;
		"This is from page $page_no:" . ' ' x ($page_no == 1);
	}
;
like($hl->create_excerpt($hit),
	qr/This is from page 2: <strong>page<\/strong> 2/,
	'page breaks within a few characters from the highlit word');
	# yes, I know highlit isn’t a real word
$hl = new KSx::Highlight::Summarizer
	searchable => $searcher,
	query      => 'Seite', # this is the only difference between this
	field      => 'content',  # highlighter and the previous one
	page_handler => sub {
		my ($hitdoc, $page_no) = @_;
		"This is from page $page_no: ";
	}
;
like($hl->create_excerpt($hit), qr/This is from page 4:\s+\.\.\. .*Seite/,
	'Page marker followed by ellipsis');


$hl = new KSx::Highlight::Summarizer
	searchable => $searcher,
	query      => 'abacus', # this is the only difference between this
	field      => 'content',  # highlighter and the previous one
	summary_length => 500,
	page_handler => sub {
		my ($hitdoc, $page_no) = @_;
		"This is from page $page_no: ";
	}
;
{
	my $warnings;
	local $SIG{__WARN__} = sub { print STDERR shift; ++$warnings};
	$excerpt = $hl->create_excerpt(
		$searcher->hits(query => 'abacus')->next
	);
	is $warnings, undef,
	    'highlighted word at beginning or end of doc doesn\'t warn';
	    # bug in 0.03
}
like $excerpt, qr/page 2:  \.\.\. acrobat/,
'ellipses around a page break; no sentence bounds in sight after pg break';
# bug in 0.03: used to match /page 2: t acrobat/


# 2 test for summaries (1 of which is also for custom ellipsis marks)

$hl = new KSx::Highlight::Summarizer
	searchable => $searcher,
	query      => 'blah Seite',
	field      => 'content', 
	summary_length => 400,
	ellipsis => ' yoda yoda yoda ',
;
like ($hl->create_excerpt($hit), qr/blah.*? yoda yoda yoda .*?Seite/,
	'summaries and custom ellipsis marks');

# bug in 0.03: This would cause an infinite loop
$hl = new KSx::Highlight::Summarizer
	searchable => $searcher,
	query      => 'beaver',
	field      => 'content', 
	summary_length => 500,
	excerpt_length => 200,
;
unlike (
	$hl->create_excerpt(
		$searcher->hits(query => 'beaver')->next
	),
	qr/\w \.\.\. \w/,
	'merging of almost adjacent excerpts'
);

# 1 test for a bug in 0.03: this used to trim more than necessary when the
#                           excerpt began with a space

$hl = new KSx::Highlight::Summarizer
	searchable => $searcher,
	query      => 'carrot',
	field      => 'content', 
	excerpt_length => 15,
;
is (
	$hl->create_excerpt(
		$searcher->hits(query => 'carrot')->next
	),
	' ... cat <strong>carrot</strong> cat ... ',
	'trimming of the start of an excerpt'
);

