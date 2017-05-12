use Test::More;
if (!eval { require Plucene::Search::Query }) { 
    plan skip_all => "Plucene not installed";
} else {
    plan tests => 22;
}

use_ok("Lucene::QueryParser");
Lucene::QueryParser->import; # Devel::Cover seems to screw this over.
sub pq { parse_query(shift)->to_plucene("text") };

my $query = pq( "hello" );
isa_ok($query, "Plucene::Search::TermQuery");
is($query->term->field, "text", "Field is correct");
is($query->term->text,  "hello", "Text is correct");

$query = pq( "foo:hello^3" );
isa_ok($query, "Plucene::Search::TermQuery");
is($query->term->field, "foo", "Field is correct");
is($query->term->text,  "hello", "Text is correct");
is($query->boost, 3, "Boost is set");

$query = pq( "-foo:hello" );
isa_ok($query, "Plucene::Search::BooleanQuery");
my @clauses = $query->clauses;
is(@clauses, 1, "Boolean query with one clause");
ok($clauses[0]->prohibited, "Clause is prohibited");
ok(!$clauses[0]->required, "Clause is not required");

$query = pq('"hello"');
isa_ok($query, "Plucene::Search::TermQuery");
is($query->term->field, "text", "Field is correct");
is($query->term->text,  "hello", "Text is correct");

$query = pq('nonsense:"hello world"');
isa_ok($query, "Plucene::Search::PhraseQuery");
my @terms = @{$query->terms};
is(@terms, 2, "With two terms");
is($terms[1]->field, "nonsense", "Correctly distributed");
is($terms[1]->text, "world", "Correctly partitioned");

$query = pq("foo AND bar");
isa_ok($query, "Plucene::Search::BooleanQuery");
@clauses = $query->clauses;
is(@clauses, 2, "Boolean query with two clause");
ok($clauses[0]->required, "Forced to be required");
