#!perl
use strict;
use lib qw(lib);
use Cwd;
use DBI;
use Path::Class;

my $dsn = "DBI:Pg:dbname=kasago_test";
my $dbh;
eval { $dbh = DBI->connect($dsn, "", "") };

if ($dbh) {
  eval 'use Test::More tests => 37;';
} else {
  eval
'use Test::More skip_all => "Need PostgreSQL database called kasago_test for testing, skipping"';
  exit;
}

use_ok('Kasago');
my $kasago = Kasago->new({ dbh => $dbh });
$kasago->init;
is_deeply([ $kasago->sources ], []);
my $source = "Acme-Colour";
my $dir = dir(cwd, "t", "Acme-Colour-1.00");
$kasago->import($source, $dir);
is_deeply([ $kasago->sources ], [$source]);
is_deeply(
  [ $kasago->files($source) ],
  [
    'Build.PL',    'CHANGES', 'MANIFEST',           'META.yml',
    'Makefile.PL', 'README',  'lib/Acme/Colour.pm', 'test.pl'
  ]
);
is(scalar($kasago->tokens($source, 'Build.PL')),           48);
is(scalar($kasago->tokens($source, 'CHANGES')),            100);
is(scalar($kasago->tokens($source, 'MANIFEST')),           19);
is(scalar($kasago->tokens($source, 'META.yml')),           25);
is(scalar($kasago->tokens($source, 'Makefile.PL')),        42);
is(scalar($kasago->tokens($source, 'README')),             392);
is(scalar($kasago->tokens($source, 'lib/Acme/Colour.pm')), 890);
is(scalar($kasago->tokens($source, 'test.pl')),            867);

my @tokens = $kasago->search('orange');
is(scalar(@tokens),    4);
is($tokens[0]->source, 'Acme-Colour');
is($tokens[0]->row,    113);
is($tokens[0]->col,    25);
is($tokens[0]->value,  'orange');
is($tokens[0]->file,   'test.pl');
is($tokens[0]->line,   '$c = Acme::Colour->new("orange");');
is($tokens[3]->source, 'Acme-Colour');
is($tokens[3]->row,    117);
is($tokens[3]->col,    23);
is($tokens[3]->value,  'orange');
is($tokens[3]->file,   'test.pl');
is($tokens[3]->line,   'is("$c", "dark red", "orange and brown is dark red");');

my @hits = $kasago->search_merged('orange');
is(scalar(@hits),                 3);
is($hits[0]->row,                 113);
is(scalar(@{ $hits[0]->tokens }), 1);
is($hits[1]->row,                 115);
is(scalar(@{ $hits[1]->tokens }), 2);
is($hits[2]->row,                 117);
is(scalar(@{ $hits[2]->tokens }), 1);

@tokens = $kasago->search_more('orange brown');

@tokens = $kasago->search('regenerated');
is(scalar(@tokens),    0);

$kasago->delete('Acme-Colour');
is_deeply([ $kasago->sources ], []);
@tokens = $kasago->search('orange');
is(scalar(@tokens), 0);

$dir = dir(cwd, "t", "Acme-Colour-1.01");
$kasago->import($source, $dir);
is_deeply([ $kasago->sources ], ['Acme-Colour']);
@tokens = $kasago->search('regenerated');
is(scalar(@tokens), 1);
