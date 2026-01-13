use v5.40;
use Test2::V1 -ipP;
use Gears::Config;

################################################################################
# This tests whether the basic config works
################################################################################

subtest 'should add perl vars' => sub {
	my $c = Gears::Config->new;
	$c->add(var => {a => 1});
	is $c->config, {a => 1}, 'config ok';
};

subtest 'should add file contents' => sub {
	my $c = Gears::Config->new;
	$c->add(file => 't/config/good2.pl');
	is $c->config, {c => 42, bools => [true, false]}, 'config ok';
};

subtest 'should add file contents with perl config vars' => sub {
	my $c = Gears::Config->new(
		readers => [
			Gears::Config::Reader::PerlScript->new(
				declared_vars => {
					test => 'test var',
				}
			)
		],
	);

	$c->add(file => 't/config/good1.pl');
	is $c->config, {a => 1, b => 'test var', c => {c => 42, bools => [true, false]}}, 'config ok';
};

subtest 'should not load bad perl script configs' => sub {
	my $c = Gears::Config->new;
	my $ex = dies { $c->add(file => 't/config/bad.pl') };
	like $ex, qr{\[Config\] error in t/config/bad\.pl:}, 'string ok';
	like $ex, qr{line 4}, 'line ok';
};

subtest 'should replace different refs' => sub {
	my $c = Gears::Config->new;
	$c->add(var => {a => [], b => 'test'});
	$c->add(var => {'=a' => 'test', '=b' => []});
	is $c->config, {a => 'test', b => []}, 'config ok';
};

subtest 'should merge hashes' => sub {
	my $c = Gears::Config->new;
	$c->add(var => {a => {b => 1, c => 42}, d => {e => 4}});
	$c->add(var => {a => {c => 2}, '+d' => {f => 5}});
	is $c->config, {a => {b => 1, c => 2}, d => {e => 4, f => 5}}, 'config ok';
};

subtest 'should replace hashes' => sub {
	my $c = Gears::Config->new;
	$c->add(var => {a => {b => 1, c => 2}});
	$c->add(var => {'=a' => {d => 3}});
	is $c->config, {a => {d => 3}}, 'config ok';
};

subtest 'should merge arrays' => sub {
	my $c = Gears::Config->new;
	$c->add(var => {a => [1, 2]});
	$c->add(var => {a => [2, 3]});
	is $c->config, {a => [1, 2, 3]}, 'config ok';
};

subtest 'should replace arrays' => sub {
	my $c = Gears::Config->new;
	$c->add(var => {a => [1, 2]});
	$c->add(var => {'=a' => [2, 3]});
	is $c->config, {a => [2, 3]}, 'config ok';
};

subtest 'should add array elements' => sub {
	my $c = Gears::Config->new;
	$c->add(var => {a => [1, 2]});
	$c->add(var => {'+a' => [2, 3]});
	is $c->config, {a => [1, 2, 2, 3]}, 'config ok';
};

subtest 'should remove array elements' => sub {
	my $c = Gears::Config->new;
	$c->add(var => {a => [1, 2, 3]});
	$c->add(var => {'-a' => [2, 4]});
	is $c->config, {a => [1, 3]}, 'config ok';
};

subtest 'should add and remove array elements at the same time' => sub {
	my $c = Gears::Config->new;
	$c->add(var => {a => [1, 2, 3]});
	$c->add(var => {'-a' => [1, 2], '+a' => [2, 4]});
	is $c->config, {a => [3, 2, 4]}, 'config ok';
};

subtest 'should get config values by path' => sub {
	my $c = Gears::Config->new;
	$c->add(var => {a => {b => {c => 42}}, d => 'test', e => undef});

	is $c->get('a.b.c'), 42, 'nested value ok';
	is $c->get('d'), 'test', 'top level value ok';
	is $c->get('a.b'), {c => 42}, 'partial path ok';
	is $c->get('missing'), undef, 'missing key returns undef';
	is $c->get('missing', 'default'), 'default', 'missing key returns default';
	is $c->get('a.missing', 'default'), 'default', 'missing nested key returns default';
	is $c->get('e', 'default'), undef, 'default value not used for existing keys';

	my $ex = dies { $c->get('d.nested') };
	like $ex, qr{invalid config path d\.nested at part nested - not a hash}, 'error on non-hash path';
};

subtest 'should error on array refs in path' => sub {
	my $c = Gears::Config->new;
	$c->add(var => {a => [1, 2, 3]});

	my $ex = dies { $c->get('a.0') };
	like $ex, qr{invalid config path a\.0 at part 0 - not a hash}, 'error on array ref path';
};

done_testing;

