
package TestDerivedInitializer;

use strict;
use warnings;

use TestInitializer;

@TestDerivedInitializer::ISA = qw(TestInitializer);

sub new {
    my ($_class) = @_;
    my $class = ref($_class) || $_class;
    my $test_derived = {
        _derived_private => "derived private test"
        };
    bless($test_derived, $class);
    $test_derived->_init();
    return $test_derived;
}

sub _init {
    my ($self) = @_;
    $self->{derived_protected} = "derived protected";
    $self->SUPER::_init();
}


1;

__DATA__