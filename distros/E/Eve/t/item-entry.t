# -*- mode: Perl; -*-
package ItemEntryTest;

use parent qw(Eve::ItemEntryTestBase);

use strict;
use warnings;

use Test::More;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'item'} = Eve::ItemEntryTest::Dummy->new(
        %{$self->get_argument_list()});
}

sub test_init : Test(4) {
    my $self = shift;

    $self->SUPER::test_init();
}

sub test_constants : Test {
    my $self = shift;

    $self->SUPER::test_constants();
}

1;

package Eve::ItemEntryTest::Dummy;

use parent qw(Eve::Item::Entry);

1;
