# -*- mode: Perl; -*-
package ClassTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

sub test_bless : Test(2) {
    my $dummy = ClassTest::Dummy->new();
    my $another_dummy = $dummy->new();

    isa_ok($dummy, 'Eve::Class');
    isnt($another_dummy, $dummy);
}

sub test_init : Test(2) {
    for my $v (1..2) {
        my $dummy = ClassTest::Dummy->new(v => 1);
        is($dummy->get_v(), 1);
    }
}

1;

package ClassTest::Dummy;

use parent qw(Eve::Class);

sub init {
    my ($self, %args) = @_;

    $self->{'v'} = $args{'v'};
}

sub get_v {
    my $self = shift;

    return $self->{'v'};
}

1;
