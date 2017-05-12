#!/usr/bin/perl

use Test::More tests => 4;

use Integrator::Module::Build;
my $build = Integrator::Module::Build->current;

# object returns something
ok ( defined $build,						'object can be instanciated' );


SKIP: {
	skip 'not in development mode', 3;


$build->notes('simple' => 'stuff');
is ( $build->notes('simple'), 'stuff',			'hash value is added');

$build->notes('simple' => 'changed_for_this');
is ( $build->notes('simple'), 'changed_for_this',		'hash value is modified');

# complex values
my $href = {
		'bonsoir'	=> 'a toi',
		'table'		=> [1..10],
		'another_hash'	=> {
					'color' => 'blue',
					'shape' => 'round',
					'coord' => [2.234, 4.33]
				   }
	   };
$build->notes('complex' => $href);

my %hash = %{$href};		#taking a copy
is_deeply ( $build->notes('complex'), \%hash,		'complex data structure is properly saved');

}
