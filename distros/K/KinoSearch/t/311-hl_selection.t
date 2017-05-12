use strict;
use warnings;
use lib 'buildlib';
use Test::More tests => 1;
use KinoSearch::Test;

my $schema = KinoSearch::Plan::Schema->new;
$schema->spec_field(
    name => 'content',
    type => KinoSearch::Plan::FullTextType->new(
        analyzer      => KinoSearch::Analysis::Tokenizer->new,
        highlightable => 1,
    ),
);
my $folder  = KinoSearch::Store::RAMFolder->new;
my $indexer = KinoSearch::Index::Indexer->new(
    schema => $schema,
    index  => $folder,
    create => 1,
);
$indexer->add_doc(
    doc => {
        content => <<'EOF',
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla.
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla.
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla.
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla.
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla.
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla NNN bla.
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla.
bla bla bla MMM bla bla bla bla bla bla bla bla bla bla bla bla.
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla.
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla.
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla.
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla.
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla.
EOF
    },
);
$indexer->commit();

my $searcher    = KinoSearch::Search::IndexSearcher->new( index => $folder, );
my $query       = 'NNN MMM';
my $highlighter = KinoSearch::Highlight::Highlighter->new(
    searcher => $searcher,
    query    => $query,
    field    => 'content'
);
my $hits    = $searcher->hits( query => $query, );
my $hit     = $hits->next();
my $excerpt = $highlighter->create_excerpt($hit);
like( $excerpt, qr/(NNN|MMM)/, "Sentence boundary algo doesn't chop terms" );

