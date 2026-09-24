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
