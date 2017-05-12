use strict;
use Test;

BEGIN {
	plan tests => 36,
}

use ELFF::Parser;

print "# make sure that tokenize handles undef arguments correctly\n";
eval { ELFF::Parser::tokenize(undef) };
defined($@) ? ok(1) : ok(0);

print "# test too many arguments\n";
eval "ELFF::Parser::tokenize('foo', 'bar')";
defined($@) ? ok(1) : ok(0);

print "# make sure that tokenize handles non-string scalars correctly\n";
print "# .. hash reference\n";
eval { ELFF::Parser::tokenize({ 'this is not' => 'a string' }) };
defined($@) ? ok(1) : ok(0);

print "# .. array reference\n";
eval { ELFF::Parser::tokenize([ "this isn't", 'either' ]) };
defined($@) ? ok(1) : ok(0);

print "# .. sub reference\n";
eval { ELFF::Parser::tokenize(sub { 1; }) };
defined($@) ? ok(1) : ok(0);

print "# test simple fields\n";
my $results = ELFF::Parser::tokenize('foo bar');
@$results == 2 ? ok(1) : ok(0);
$results->[0] eq 'foo' ? ok(1) : ok(0);
$results->[1] eq 'bar' ? ok(1) : ok(0);

print "# test quoted field at start\n";
$results = ELFF::Parser::tokenize(qq{"foo bar" fnord});
@$results == 2 ? ok(1) : ok(0);
$results->[0] eq 'foo bar' ? ok(1) : ok(0);
$results->[1] eq 'fnord' ? ok(1) : ok(0);

print "# test quoted field at end\n";
$results = ELFF::Parser::tokenize(qq{foo "bar baz"});
@$results == 2 ? ok(1) : ok(0);
$results->[0] eq 'foo' ? ok(1) : ok(0);
$results->[1] eq 'bar baz' ? ok(1) : ok(0);

print "# test quoted field in the middle\n";
$results = ELFF::Parser::tokenize(qq{foo "bar baz" fnord});
@$results == 3 ? ok(1) : ok(0);
$results->[0] eq 'foo' ? ok(1) : ok(0);
$results->[1] eq 'bar baz' ? ok(1) : ok(0);
$results->[2] eq 'fnord' ? ok(1) : ok(0);

print "# test quoted fields at start and end\n";
$results = ELFF::Parser::tokenize(qq{"foo bar" baz "fnord buz"});
@$results == 3 ? ok(1) : ok(0);
$results->[0] eq 'foo bar' ? ok(1) : ok(0);
$results->[1] eq 'baz' ? ok(1) : ok(0);
$results->[2] eq 'fnord buz' ? ok(1) : ok(0);

print "# test all quoted fields\n";
$results = ELFF::Parser::tokenize(qq{"foo bar" "baz fnord" "buz 42"});
@$results == 3 ? ok(1) : ok(0);
$results->[0] eq 'foo bar' ? ok(1) : ok(0);
$results->[1] eq 'baz fnord' ? ok(1) : ok(0);
$results->[2] eq 'buz 42' ? ok(1) : ok(0);

print "# test empty quotes\n";
$results = ELFF::Parser::tokenize(qq{"" "" ""});
@$results == 3 ? ok(1) : ok(0);
foreach my $i (0 .. 2) {
	$results->[$i] eq '' ? ok(1) : ok(0);
}

print "# test malformed line, missing quote, no good fields\n";
eval { ELFF::Parser::tokenize(qq{"fnord baz}) };
defined($@) ? ok(1) : ok(0);

print "# test malformed line, missing quote, one good field\n";
eval { ELFF::Parser::tokenize(qq{foo "bar baz}) };
defined($@) ? ok(1) : ok(0);

print "# test line with trailing white space\n";
$results = ELFF::Parser::tokenize(qq{foo bar fnord   });
@$results == 3 ? ok(1) : ok(0);
$results->[0] eq 'foo' ? ok(1) : ok(0);
$results->[1] eq 'bar' ? ok(1) : ok(0);
$results->[2] eq 'fnord' ? ok(1) : ok(0);
