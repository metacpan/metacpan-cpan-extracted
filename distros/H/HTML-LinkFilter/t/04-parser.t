use Test::More tests => 1;
use HTML::LinkFilter;

my $filter = HTML::LinkFilter->new;

isa_ok( $filter->{p}, "HTML::Parser" );

