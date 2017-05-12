# test

use strict ;
use warnings ;

use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
use Test::Block qw($Plan);

use List::Tuples qw(:all); 

use Carp::Diagnostics (qw(UseLongMessage));
UseLongMessage(0) ;

{
local $Plan = {'ref_mesh' => 8} ;

throws_ok
	{
	ref_mesh(1, 1, 1) ;
	} qr/element '0' is not an array reference/, 'bad argument' ;
	
throws_ok
	{
	ref_mesh(undef, []) ;
	} qr/element '0' is not an array reference/, 'bad argument' ;

lives_ok
	{
	my @list = ref_mesh() ;
	
	is(scalar(@list), 0, 'empty input gives empty output') ;
	} 'no arguments' ;

lives_ok
	{
	my @list = ref_mesh() ;
	
	is(scalar(@list), 0, 'empty input gives empty output') ;
	} 'no arguments' ;

my @mixed_list =
	ref_mesh
		(
		['mum1', 'mum2', 'mum3'],
		['dad1', 'dad2', ], 
		[['child1_1', 'child1_2'], [], ['child3_1']]
		) ;

my $reference = 
	[
           'mum1',
           'dad1',
           [
             'child1_1',
             'child1_2'
           ],
           'mum2',
           'dad2',
           [],
           'mum3',
           undef,
           [
             'child3_1'
           ]
         ];


use Data::Dumper ;
is_deeply( \@mixed_list, $reference, 'mixing arrays'	) or diag Dumper(\@mixed_list);

my @first_list_empty =	ref_mesh([], ['2', ],  [3]) ;
my $reference_first_list_empty = [undef, '2', 3] ;

is_deeply( \@first_list_empty, $reference_first_list_empty, 'first_list_empty'	) or diag Dumper(\@first_list_empty);
}

{
local $Plan = {'tuples' => 14} ;

throws_ok
	{
	tuples() ;
	} qr/Error: List::Tuples::tuples expects an array reference as size/, 'no arguments' ;

throws_ok
	{
	tuples(1, 1, 1) ;
	} qr/Error: List::Tuples::tuples expects an array reference as size/, 'bad size argument' ;

throws_ok
	{
	tuples(1, undef, 1) ;
	} qr/Error: List::Tuples::tuples expects an array reference as size/, 'bad size argument' ;

throws_ok
	{
	my @list = tuples[] ;
	} qr/Error: List::Tuples::tuples expects a tuple size/, 'no size argument' ;

throws_ok
	{
	tuples(1, [0]) ;
	} qr/Error: List::Tuples::tuples expects tuple size to be positive/, 'bad size argument' ;

throws_ok
	{
	tuples(0, [2]) ;
	} qr/Error: List::Tuples::tuples expects tuple limit to be positive/, 'bad limit' ;

lives_ok
	{
	my @list = tuples[5] ;
	
	is(scalar(@list), 0, 'empty input gives empty output') or diag Dumper(\@list);
	} 'no list' ;

lives_ok	
	{
	my @list = tuples(undef, [2]) ;
	
	is(scalar(@list), 0, 'empty input gives empty output') ;
	} 'no list' ;

lives_ok
	{
	my @list = tuples(1, [2]) ;
	
	is(scalar(@list), 0, 'empty input gives empty output') ;
	} 'no list' ;
	
my @triples = tuples[3] => (1 .. 5) ;
my @reference_triples = ([1, 2, 3], [4, 5]) ; 
is_deeply( \@triples, \@reference_triples, 'triples'	) or diag Dumper(\@triples);

my @limited_triples = tuples 1 => [3] => (1 .. 5) ;
my @reference_limited_triples = ([1, 2, 3]) ;
is_deeply( \@limited_triples, \@reference_limited_triples, 'limited_triples'	) or diag Dumper(\@limited_triples);
}

{
local $Plan = {'hash tuples' => 13} ;

throws_ok
	{
	hash_tuples() ;
	} qr/Error: List::Tuples::hash_tuples expects an array reference to define the keys/, 'no arguments' ;

throws_ok
	{
	hash_tuples(1, 1, 1) ;
	} qr/Error: List::Tuples::hash_tuples expects an array reference to define the keys/m, 'bad key list' ;

throws_ok
	{
	hash_tuples(1, undef, 1) ;
	} qr/Error: List::Tuples::hash_tuples expects an array reference to define the keys/m, 'bad key list' ;

throws_ok
	{
	hash_tuples(1, []) ;
	} qr/Error: List::Tuples::hash_tuples expects at least one key in the key list/, 'bad key list' ;

throws_ok
	{
	hash_tuples(0, ['key']) ;
	} qr/Error: List::Tuples::hash_tuples expects tuple limit to be positive/, 'bad limit' ;

lives_ok
	{
	my @list = hash_tuples['key'] ;
	
	is(scalar(@list), 0, 'empty input gives empty output') or diag Dumper(\@list);
	} 'no list' ;

lives_ok	
	{
	my @list = hash_tuples(undef, ['key']) ;
	
	is(scalar(@list), 0, 'empty input gives empty output') ;
	} 'no list' ;

lives_ok
	{
	my @list = hash_tuples(1, ['key']) ;
	
	is(scalar(@list), 0, 'empty input gives empty output') ;
	} 'no list' ;
	
my @triples = hash_tuples ['key', 'key2'] => (1 .. 5) ;
my @reference_triples = 
	(
          {
             'key2' => 2,
             'key' => 1
           },
           {
             'key2' => 4,
             'key' => 3
           },
           {
             'key2' => undef,
             'key' => 5
           }
	) ;

is_deeply( \@triples, \@reference_triples, 'triples'	) or diag Dumper(\@triples);

my @limited_triples = hash_tuples 1 => ['key', 'key2'] => (1 .. 5) ;
my @reference_limited_triples =
	(
          {
             'key2' => 2,
             'key' => 1
           },
        ) ;
	
is_deeply( \@limited_triples, \@reference_limited_triples, 'limited_triples'	) or diag Dumper(\@limited_triples);
}
