use v5.10;
use strict;
use warnings;

use lib 't/lib';

use Test::More;

our @plugins;
BEGIN {
	@plugins = ('MyPlugin');
}

{
	package Test;
	use Form::Tiny plugins => \@plugins;
}

is_deeply \@plugins, ['MyPlugin'], 'plugin array unchanged';

done_testing;

