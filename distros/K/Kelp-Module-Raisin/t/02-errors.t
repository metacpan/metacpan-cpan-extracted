use strict;
use warnings;

use Test::More;
use Test::Exception;
use lib 't/lib';
use KelpApp;

my $num = 1;

sub mk_anon_class
{
	my $name = 'Kelp::SandBox::App' . $num++;
	local $@;

	eval qq[
		{
			package $name;
			use parent -norequire, 'KelpApp';
		}
	];

	die $@ if $@;
	return $name;
}

throws_ok sub {
	mk_anon_class->new(mode => 'no_class');
	},
	qr/requires .class. configuration/,
	'no class ok';

throws_ok sub {
	mk_anon_class->new(mode => 'wrong_class');
	},
	qr/Can't locate RaisinAppThatDoesNotExist/,
	'wrong class ok';

throws_ok sub {
	mk_anon_class->new(mode => 'cannot_app');
	},
	qr/Can't locate object method .app./,
	'cannot app ok';

throws_ok sub {
	mk_anon_class->new(mode => 'not_raisin');
	},
	qr/not isa Raisin/,
	'not raisin ok';

done_testing;
