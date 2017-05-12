#!perl -w

use strict;
use Test::More tests => 4;

#use Hash::Util::FieldHash::Compat qw(fieldhash fieldhashes);
use Hash::FieldHash qw(:all);

{
	package T;
	use overload '""' => sub{ die 'stringify' };

	sub new{ bless {}, @_ }
}

fieldhash my %hash;

ok !exists $hash{T->new};
is_deeply \%hash, {};

{
	my $t = T->new;
	$hash{$t} = 42;
	is_deeply [values %hash], [42];
}

is_deeply \%hash, {};
