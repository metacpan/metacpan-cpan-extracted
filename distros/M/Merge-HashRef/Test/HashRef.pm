package Test::HashRef;

use strict;
use warnings;

use base 'Test::Class';
use Test::More;
use Merge::HashRef;

sub make_hashrefs : Test(setup) {
	my $self = shift;
	$self->{h1} = { one => 1, two => 2, three => 3 };
	$self->{h2} = { four => 4, five => 5 };
	$self->{h3} = { one => 'one', four => 'four' };
}

sub hash1 { shift->{h1} }
sub hash2 { shift->{h2} }
sub hash3 { shift->{h3} }

sub merge_one_way : Test(2) {
	my $self = shift;
	my $hash = Merge::HashRef::merge_hashref($self->hash3, $self->hash2, $self->hash1);
	is $hash->{four}, 4, "numeric value overwrites aplhabetic one";
	is $hash->{five}, 5, "numeric value overwrites aplhabetic one (second time)";
}

sub merge_other_way : Test(2) {
	my $self = shift;
	my $hash = Merge::HashRef::merge_hashref($self->hash1, $self->hash2, $self->hash3);
	is $hash->{four}, 'four', "aplhabetic value overwrites numeric one";
	is $hash->{five}, 5, "aplhabetic value overwrites numeric one (second time)";

}

1;
