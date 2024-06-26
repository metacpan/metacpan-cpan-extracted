use Kelp::Base -strict;
use Test::More;
use Kelp;
use YAML::PP qw(Dump Load);
use Kelp::Request;

my $app = Kelp->new(mode => 'test');

can_ok $app, 'yaml';

can_ok $app->yaml, qw(encode decode engine);
isa_ok $app->yaml->engine, 'YAML::PP';

my @documents = (
	{
		key1 => 'val1',
		key2 => 'val2',
	},
	{
		key3 => ['val3', 'val4'],
		key4 => undef,
	},
);

my @res;
my @yaml_res;

for my $doc (@documents) {
	push @res, $app->yaml->encode($doc);
	push @yaml_res, Dump($doc);
}

subtest 'testing documents together' => sub {
	is_deeply [$app->yaml->decode(join '', @yaml_res)], \@documents, 'decode ok';
	is $app->yaml->encode(@documents), join('', @yaml_res), 'decode ok';
};

subtest 'testing documents separately' => sub {
	while (@res) {
		my $doc = shift @documents;

		is_deeply $app->yaml->decode(shift @yaml_res), $doc, 'decode ok';
		is_deeply Load(shift @res), $doc, 'decode against yaml ok';
	}

	is scalar @yaml_res, 0, 'fully decoded ok';
};

ok !Kelp::Request->can('is_yaml'), 'no yaml extensions ok';

done_testing;

