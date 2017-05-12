#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;
use Lingua::PT::Actants;
use Path::Tiny;
use utf8;

my $input = path('examples/input-1.conll')->slurp_utf8;
my $o = Lingua::PT::Actants->new( conll=>$input );
ok( ref($o) eq 'Lingua::PT::Actants', 'actants object' );

my @cores = $o->acts_cores;
ok( scalar(@cores) == 1, 'one verb' );
ok( $cores[0]->{verb}->{form} eq 'tem', 'verb is _tem_' );
ok( $cores[0]->{cores}->[0]->{form} eq 'Maria', 'first actant core is _Maria_' );
ok( $cores[0]->{cores}->[1]->{form} eq 'razão', 'second actant core is _razão_' );

