#!perl -w

use strict;
use Test::More tests => 4;

#use Hash::Util::FieldHash::Compat qw(fieldhash fieldhashes);
use Hash::FieldHash qw(:all);

my $count = 0;
{
	package CountedObject;
	sub new{ $count++; return bless {}, shift }
	sub DESTROY{ $count-- }
}

fieldhash my %a;

{
	my $o = {};
	$a{$o} = CountedObject->new;

	delete $a{$o};

	is $count, 0, 'field is released';

	$o = CountedObject->new;
	$a{$o}++;
	delete $a{$o};
	undef $o;

	is $count, 0, 'key object is released';

	$o = CountedObject->new;
	$a{$o} = CountedObject->new;
}

is_deeply \%a, {};
is $count, 0, 'finished';
