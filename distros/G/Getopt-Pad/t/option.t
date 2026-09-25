use v5.26;
use experimental 'signatures';
use Test2::V0;

use Getopt::Pad::Spec::Option;

sub option($key, %raw) {
	return Getopt::Pad::Spec::Option->new(key => $key, raw => \%raw);
}

subtest 'precedence across value sources' => sub {
	my $logLevel = option('log-level', type => 's', default => 'info');
	is $logLevel->readerValue(commandLine => { 'log-level' => 'debug' }, config => { 'log-level' => 'warn' }), 'debug', 'command line beats config';
	is $logLevel->readerValue(commandLine => {}, config => { 'log-level' => 'warn' }), 'warn', 'config beats the spec default';
	is $logLevel->readerValue(commandLine => {}, config => {}), 'info', 'spec default when no source sets the option';
};

subtest 'required and absent options' => sub {
	my $owner = option('owner', type => 's', required => 1);
	like dies { $owner->readerValue(commandLine => {}, config => {}) }, qr/missing required option '--owner'/, 'required with no source';
	is $owner->readerValue(config => { owner => 'dave' }), 'dave', 'a config value satisfies required';
	is option('repo', type => 's')->readerValue(commandLine => {}), undef, 'absent optional option is undef';
};

subtest 'errors name their value source' => sub {
	my $width = option('width', type => 'i');
	like dies { $width->readerValue(commandLine => { width => 'x' }) }, qr/^option '--width': 'x' is not an integer/, 'command line wording';
	like dies { $width->readerValue(config => { width => 'x' }) }, qr/^config value for 'width': 'x' is not an integer/, 'config wording';
};

subtest 'multiple options' => sub {
	my $tag = option('tag', type => 's', multiple => 1, default => ['a']);
	is $tag->readerValue(config => { tag => 'solo' }), ['solo'], 'a lone config value becomes a list';

	push $tag->readerValue()->@*, 'b';
	is $tag->readerValue(), ['a'], 'each parse gets its own copy of the default';
	is option('tag', type => 's', multiple => 1)->readerValue(), [], 'absent without a default is an empty list';
};

subtest 'csv options' => sub {
	my $tag = option('tag', type => 's', multiple => 1, csv => 1);
	is $tag->readerValue(config => { tag => 'a, b' }), ['a', 'b'], 'a lone config value is split';
	is $tag->readerValue(config => { tag => ['a,b', 'c'] }), ['a,b', 'c'], 'a config list is taken as given';
	like dies { $tag->readerValue(config => { tag => undef }) }, qr/^config value for 'tag': no value given/, 'a null config value is still reported as missing';
};

subtest 'objectlist options' => sub {
	my $server = option('server', type => 'i', objectlist => 1, default => [{ port => '80' }]);
	is $server->readerValue(config => { server => [{ port => '81' }, { port => '82' }] }), [{ port => 81 }, { port => 82 }], 'a config list of mappings passes through, values coerced';
	is $server->readerValue(commandLine => { server => { '0.port' => '8080' } }), [{ port => 8080 }], 'command line pairs are collected';

	$server->readerValue()->[0]{port} = 9;
	is $server->readerValue(), [{ port => 80 }], 'each parse gets its own copy of the default, entries included';

	like dies { $server->readerValue(config => { server => { port => 1 } }) }, qr/^config value for 'server': expected a list of mappings/, 'mapping for an objectlist option';
	like dies { $server->readerValue(config => { server => ['x'] }) }, qr/^config value for 'server': entry 0: expected a mapping of keys to values/, 'scalar entry';
};

subtest 'hash options' => sub {
	my $define = option('define', type => 'i', hash => 1, default => { a => '1' });
	is $define->readerValue(commandLine => { define => { b => '2' } }), { b => 2 }, 'the given mapping replaces the default, values coerced';
	is $define->readerValue(config => { define => { c => '3' } }), { c => 3 }, 'a config mapping passes through';

	$define->readerValue()->{x} = 9;
	is $define->readerValue(), { a => 1 }, 'each parse gets its own copy of the default';
	is option('define', type => 's', hash => 1)->readerValue(), {}, 'absent without a default is an empty mapping';

	like dies { $define->readerValue(config => { define => 'a=1' }) }, qr/^config value for 'define': expected a mapping of keys to values/, 'scalar for a hash option';
	like dies { $define->readerValue(config => { define => { a => undef } }) }, qr/^config value for 'define': key 'a': no value given/, 'null value names its key';
	like dies { $define->readerValue(config => { define => { '' => 1 } }) }, qr/^config value for 'define': empty key/, 'empty key';
};

subtest 'config values need the right shape' => sub {
	my $owner = option('owner', type => 's');
	like dies { $owner->readerValue(config => { owner => ['a', 'b'] }) }, qr/^config value for 'owner': expected a single value, not a list or mapping/, 'list for a single-value option';
	like dies { $owner->readerValue(config => { owner => { nested => 1 } }) }, qr/expected a single value, not a list or mapping/, 'mapping for a single-value option';
	like dies { $owner->readerValue(config => { owner => undef }) }, qr/^config value for 'owner': no value given/, 'null value';
	like dies { option('tag', type => 's', multiple => 1)->readerValue(config => { tag => ['a', { b => 1 }] }) }, qr/expected a single value/, 'mapping inside a list';
};

like dies { option('x')->readerValue(cli => {}) }, qr/unknown value source\(s\): cli/, 'an unknown value source croaks';

done_testing;
