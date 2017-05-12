
package TestDerived;

use strict;
use warnings;

use TestBase;

@TestDerived::ISA = qw(TestBase);

sub new {
    my ($_class) = @_;
    my $class = ref($_class) || $_class;
    my $test_derived = $class->SUPER::new();
    $test_derived->{_derived_private} = "derived private test";
    return $test_derived;
}

# NOTE: this method will fail
sub getPrivateFromBase {
    my ($self) = @_;
    return $self->{_private};
}

sub setPrivateForDerived {
    my ($self, $value) = @_;
    $self->{_derived_private} = $value;
}

sub getPrivateForDerived {
    my ($self) = @_;
    return $self->{_derived_private};
}

sub setDerivedProtected {
    my ($self, $value) = @_;
    $self->{protected} = $value;
}

sub getDerivedProtected {
    my ($self) = @_;
    return $self->{protected};
}

1;

__DATA__