use v5.10;
use warnings;
use Test::More;
use Form::Tiny::Path;
use Form::Tiny::Utils qw(try);

my @data = (
	[1, 'simplepath', ['simplepath']],
	[1, 'simple.path', ['simple', 'path']],
	[1, 'simple\\.path', ['simple.path']],
	[1, 'array.*.path', ['array', '*', 'path'], {1 => 'ARRAY'}],
	[1, 'array.\\*.path', ['array', '*', 'path'], {1 => 'HASH'}],
	[1, 'array.\\\\*.path', ['array', '\\*', 'path'], {1 => 'HASH'}],
	[1, 'array*.path', ['array*', 'path']],
	[1, '\\\\\\\\', ['\\\\']],
	[1, '\\*.thats.legal', ['*', 'thats', 'legal'], {0 => 'HASH'}],
	[0, ''],
	[0, 'error.'],
	[0, '.error'],
	[0, '*.thats.illegal'],
	[0, '*'],
	[0, '*.*'],
);

for my $aref (@data) {
	my ($result, $name, $expected, $meta) = @$aref;

	my $error = try sub {
		my $path = Form::Tiny::Path->from_name($name);
		is_deeply $path->path, $expected, 'path ok';
		for my $key (keys %{$meta // {}}) {
			is $path->meta->[$key], $meta->{$key}, 'path meta value ok';
		}
		note $path->dump;

		is $path->join, $name, 'back to string conversion ok';
	};

	is !!$error, !$result, 'exception ok';
	if ($error) {
		note $error;
	}
}

done_testing();
