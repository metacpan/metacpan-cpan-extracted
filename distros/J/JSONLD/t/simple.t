use Test::Modern;
use Test::Exception;

use v5.14;
use warnings;
no warnings 'redefine';

use JSONLD;

{
	my $jld		= JSONLD->new();
	my $data	= {
		'@context' => { '@vocab' => 'http://example.org/', },
		'foo' => 'bar',
	};
	my $e		= $jld->expand($data);
	is_deeply($e, [{
		'http://example.org/foo' => [
			{ '@value' => 'bar' }
		]
	}])
}

done_testing();
