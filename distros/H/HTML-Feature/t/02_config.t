use strict;
use warnings;
use HTML::Feature;
use Data::Dumper;
use Test::More tests => 1;

my %config = (
    'abc'   => { 'def' => 'ghi' },
    'hello' => 'world'
);

my $feature = HTML::Feature->new(%config);

is_deeply( $feature->config, \%config, 'config OK' );
