#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula          ();
use Math::Formula::Context ();
use Test::More;

my $dir;

BEGIN {
	eval "require JSON";
	$@ and plan skip_all => 'no JSON package installed';

	$dir = 'save.json';
	-d $dir or mkdir $dir
		or plan skip_all => "cannot create workdirectory $dir";
}

use_ok 'Math::Formula::Config::JSON';

### First try empty context

my $context = Math::Formula::Context->new(name => 'test');
ok defined $context, 'created context';

$context->add( {
	some_truth => MF::BOOLEAN->new('true'),
	fakes      => MF::BOOLEAN->new('false'),
	no_quotes  => MF::STRING->new(undef, 'abc'),
	expr1      => "1 + 2 * 3",
	expr2      => [ '"abc".size + 3k', returns => 'MF::INTEGER' ],
	
});

my $config = Math::Formula::Config::JSON->new(directory => $dir);

$config->save($context);
my $expect_fn = File::Spec->catfile($dir, 'test.json');
ok -r $expect_fn, "written json to $expect_fn";
cmp_ok -s $expect_fn, '>', 100, '... non empty';

done_testing;
