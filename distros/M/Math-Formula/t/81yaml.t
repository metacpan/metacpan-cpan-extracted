#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula          ();
use Math::Formula::Context ();
use Test::More;

my $dir;

BEGIN {
	eval "require YAML::XS";
	$@ and plan skip_all => 'no YAML package installed';

	$dir = 'save.yaml';
	-d $dir or mkdir $dir
		or plan skip_all => "cannot create workdirectory $dir";
}

use_ok 'Math::Formula::Config::YAML';

### First try empty context

my $context = Math::Formula::Context->new(name => 'test');
ok defined $context, 'created context';

$context->add( {
	some_truth => MF::BOOLEAN->new('true'),
	fakes      => MF::BOOLEAN->new('false'),
	no_quotes  => MF::STRING->new(undef, 'abc'),
	longer     => \'abc def yes no',
	int        => MF::INTEGER->new(undef, 42),
	float      => MF::FLOAT->new(undef, 3.14),
	string     => MF::STRING->new(undef, 'true'),
	expr1      => "1 + 2 * 3",
	expr2      => [ '"abc".size + 3k', returns => 'MF::INTEGER' ],
});

my $config = Math::Formula::Config::YAML->new(directory => $dir);

$config->save($context);

my $expect_fn = File::Spec->catfile($dir, 'test.yml');
ok -r $expect_fn, "written yaml to $expect_fn";
cmp_ok -s $expect_fn, '>', 100, '... non empty';

### LOAD

ok 1, 'Attempt loading of test';
my $reread = $config->load('test');
ok defined $reread, '... loaded new context';
isa_ok $reread, 'Math::Formula::Context', '... ';

$config->save($reread, filename => 'test2.yml');
ok 1, 'saved again in test2.yml';

done_testing;
