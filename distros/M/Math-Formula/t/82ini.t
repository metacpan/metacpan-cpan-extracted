#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula          ();
use Math::Formula::Context ();
use Test::More;

my $dir;

BEGIN {
	eval "require Config::INI::Writer";
	$@ and plan skip_all => 'Config::INI::Writer package not installed';

	eval "require Config::INI::Reader";
	$@ and plan skip_all => 'Config::INI::Reader package not installed';

	$dir = 'save.ini';
	-d $dir or mkdir $dir
		or plan skip_all => "cannot create workdirectory $dir";
}

use_ok 'Math::Formula::Config::INI';

### SAVE a context with a lot of stuff in it

my $context = Math::Formula::Context->new(name => 'test');
ok defined $context, 'created context';

$context->add( {
	some_truth => MF::BOOLEAN->new('true'),
	fakes      => MF::BOOLEAN->new('false'),
	string     => MF::STRING->new(undef, 'abc'),
	expr1      => "1 + 2 * 3",
	expr2      => [ '"abc".size + 3k', returns => 'MF::INTEGER' ],
	dinertime  => MF::TIME->new('18:05:07'),
});

my $config = Math::Formula::Config::INI->new(directory => $dir);

$config->save($context);
my $expect_fn = File::Spec->catfile($dir, 'test.ini');
ok -r $expect_fn, "written ini to $expect_fn";
cmp_ok -s $expect_fn, '>', 100, '... non empty';

### LOAD

ok 1, 'Attempt loading of test';
my $reread = $config->load('test');
ok defined $reread, '... loaded new context';
isa_ok $reread, 'Math::Formula::Context', '... ';

$config->save($reread, filename => 'test2.ini');
ok 1, 'saved again in test2.ini';

done_testing;
