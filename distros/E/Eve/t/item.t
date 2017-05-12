# -*- mode: Perl; -*-
package ItemTest;

use parent qw(Eve::ItemTestBase);

use strict;
use warnings;

use Test::More;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'item'} = Eve::ItemTest::Dummy->new(
        %{$self->get_argument_list()});
}

sub test_init : Test(0) {
    my $self = shift;

    $self->SUPER::test_init();
}

sub test_constants : Test(0) {
    my $self = shift;

    $self->SUPER::test_constants();
}

1;

package Eve::ItemTest::Dummy;

use parent qw(Eve::Item);

1;
