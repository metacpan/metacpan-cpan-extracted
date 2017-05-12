
package TestDerivedFieldIdentifier;

use strict;
use warnings;

use TestFieldIdentifier;

@TestDerivedFieldIdentifier::ISA = qw(TestFieldIdentifier);

sub new {
    my ($_class) = @_;
    my $class = ref($_class) || $_class;
    my $test_derived = $class->SUPER::new();
    $test_derived->{"__DERIVED_PRIVATE__"} = "derived private test";
    return $test_derived;
}

# NOTE: this method will fail
sub getPrivateFromBase {
    my ($self) = @_;
    return $self->{"__PRIVATE__"};
}

sub setPrivateForDerived {
    my ($self, $value) = @_;
    $self->{"__DERIVED_PRIVATE__"} = $value;
}

sub getPrivateForDerived {
    my ($self) = @_;
    return $self->{"__DERIVED_PRIVATE__"};
}

sub setDerivedProtected {
    my ($self, $value) = @_;
    $self->{"_protected"} = $value;
}

sub getDerivedProtected {
    my ($self) = @_;
    return $self->{"_protected"};
}

1;

__DATA__