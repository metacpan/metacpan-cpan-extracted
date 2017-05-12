# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 20;

use_ok("Lucene::QueryParser");
Lucene::QueryParser->import; # Devel::Cover seems to screw this over.

use Data::Dumper;

sub test_query {
    my ($query, $expected, $message) = @_;
    my $parsed = parse_query($query);
    is_deeply($parsed, $expected, $message);
    $query =~ s/ (and|or)//g;
    $query =~ s/not /-/g;
    is(deparse_query($parsed), $query, " ... and back again");
}

test_query("foo",
[ { query => 'TERM', type => 'NORMAL', term => 'foo' } ],
    "Simple one-word query parses fine");

test_query("foo bar",
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'bar' },
 ],
    "Simple two-word query parses fine");
test_query("foo +bar",
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'bar', type => "REQUIRED" },
 ],
    "+ operator works");
test_query("foo -bar",
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'bar', type => "PROHIBITED" },
 ],
    "- operator works");

test_query("foo not bar",
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'bar', type => "PROHIBITED" },
 ],
    "not operator works");

is_deeply(parse_query('"foo bar" baz'),
[ { query => 'PHRASE', type => 'NORMAL', term => 'foo bar' },
  { query => 'TERM', type => 'NORMAL', term => 'baz',},
 ],
    "Quoted phrase matches work");

test_query("foo AND bar",
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'bar' , conj => "AND" },
 ],
    "conjunctions work");

test_query("foo AND baz:bar",
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'bar', field => 'baz' , conj => "AND" },
 ],
    "fields work");

test_query("foo AND baz^2.0",
[ { query => 'TERM', type => 'NORMAL', term => 'foo'},
  { query => 'TERM', type => 'NORMAL', term => 'baz', boost => "2.0", conj => "AND" },
 ],
    "boosting works");

# Grand finale!

test_query("red AND yellow AND -(coat:pink AND green)",
[ { query => 'TERM', type => 'NORMAL', term => 'red' },
  { query => 'TERM', type => 'NORMAL', term => 'yellow', conj => "AND" },
  { subquery => [
        { query => 'TERM', type => 'NORMAL', term => 'pink', field => 'coat' },
        { query => 'TERM', type => 'NORMAL', term => 'green', conj => "AND" } 
    ], query => 'SUBQUERY', type => 'PROHIBITED', conj => "AND" }
], "A very complex query (with subquery)");

