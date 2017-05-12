# test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
#use Test::UniqueTestNames ;

use Test::Block qw($Plan);

use File::Path::Collapse qw(:all) ;

{
my @tests = 
	(
	# uncollapsed, collapsed, separator, test name
	['/', '/', undef, 'root'],
	['../../../p', '../../../p', undef, 'double dot before path'],
	['/p/p.q/p', '/p/p.q/p', undef, 'path component with dot'],
	['/p/p..q/p', '/p/p..q/p', undef, 'path component with two dot'],
	['/p/p./p', '/p/p./p', undef, 'path component ending with dot'],
	['/p/p../p', '/p/p../p', undef, 'path component with two dot'],
	['p////', 'p', undef, 'empty path component'],
	['p////p///p', 'p/p/p', undef, 'empty path component'],
	['p//..//p///p', 'p/p', undef, 'empty path component with double dots'],
	['p/..///p///p', 'p/p', undef, 'empty path component with double dots, take 2'],
	['p/..///.//p///p/.', 'p/p', undef, 'empty path component with double dots and dots'],
	['p\..\\\.\\p\\\p\.', 'p\p', '\\', 'empty path component with double dots and dots, windows style'],
	['.../p', '.../p', undef, 'triple dot'],
	['p/.../p',  'p/.../p', undef, 'triple dots between path componenets'],
	['p/p/..', 'p', undef, 'double dots at the end '],
	['/p/..', '/', undef, 'from root, double dots at the end '],
	['p/..', '', undef, 'not from root, double dots at the end '],
	['..../path/../hi', '..../hi', undef, 'quadruple dots at the start '],
	['p/./../././/p//./.../p..../p/./.././p', 'p/.../p..../p', undef, 'crazy'],
	) ;
	
# windows tests
#~ push @tests, map { $_->[0] =~ s~/~\\~g ; $_->[1] =~ s~/~\\~g ; $_->[2] = '\\' ; $_ ;} @tests ;

push @tests, [undef, undef, undef, 'undef'] ;


#~ all of the above starting from root
#~ all of the above with space embedded

local $Plan = {'collapse' => scalar(@tests)} ;

for (@tests)
	{
	my ($uncollapsed_path, $expected_collapsed_path, $separator, $test_name) = @{$_} ;
	my ($collapsed_path, $uncollapsed_components, $collapsed_components) = CollapsePath($uncollapsed_path, $separator) ;
	
	$uncollapsed_path = 'undef' unless defined $uncollapsed_path ;
	
	is($collapsed_path, $expected_collapsed_path, $test_name . ", uncollapsed path: '$uncollapsed_path'") 
		or do
			{
			use Data::TreeDumper ;
			diag DumpTree $uncollapsed_components, 'uncollapsed_components:', QUOTE_VALUES => 1 ;
			diag DumpTree $collapsed_components, 'collapsed_components:', QUOTE_VALUES => 1 ;
			diag "\n" ;
			} ;
	}
}
