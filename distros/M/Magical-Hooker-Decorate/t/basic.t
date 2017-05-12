#!/usr/bin/perl

use strict;
use warnings;

use Devel::Peek;

use Test::More tests => 13;

use ok 'Magical::Hooker::Decorate';

my $d = Magical::Hooker::Decorate->new;

my %hash;

$d->set(\%hash, "Foo");

pass("did not die");

is( $d->get(\%hash), "Foo", "get" );
is( $d->get(\%hash), "Foo", "get" );
is( $d->get(\%hash), "Foo", "get" );

is( $d->clear(\%hash), "Foo", "clear" );

is( $d->get(\%hash), undef, "get" );

is( $d->clear(\%hash), undef, "clear" );


{
	our $destroyed;

	sub Foo::DESTROY { $destroyed++ };

	{
		local $destroyed = 0;

		my $var = "blah";
		$d->set(\$var, bless {}, "Foo");

		is( $destroyed, 0, "not yet destroyed" );

		is( ref($d->get(\$var)), "Foo", "object stored" );

		$d->clear(\$var);

		is( $destroyed, 1, "destroyed on clear" );

	}

	{
		local $destroyed = 0;

		{
			my @array = ( 1 .. 3 );
			$d->set(\@array, bless {}, "Foo" );

			is( $destroyed, 0, "not yet destroyed" );
		}

		is( $destroyed, 1, "destroyed" );
	}
}

