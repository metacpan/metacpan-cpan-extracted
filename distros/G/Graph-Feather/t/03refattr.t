use strict;
use warnings;
use Test::More tests => 3;
use Graph::Directed;
use List::UtilsBy qw/sort_by/;
use Graph::Feather;

my $f = Graph::Feather->new();

my $ref = [];

$f->set_edge_attribute('a', 'b', 't', $ref);

is $f->get_edge_attribute('a', 'b', 't'), $ref,
  'references in edge attributes stored';

my $d = Graph::Directed->new;

$f->feather_export_to($d);

is $d->get_edge_attribute('a', 'b', 't'), $ref,
  'references in edge attributes exported';

$f->delete_edge('a', 'b');

$f->feather_import_from($d);

is $d->get_edge_attribute('a', 'b', 't'), $ref,
  'references in edge attributes imported';
