
package TestInitializer;

use strict;
use warnings;

sub new {
    my ($_class) = @_;
    my $class = ref($_class) || $_class;
    my $test = {};
    bless($test, $class);
    $test->_init();
    return $test;
}

sub _init {
    my ($self) = @_;
    $self->{protected} = "protected test",
    $self->{_private} = "private test"
}

sub setPrivate {
    my ($self, $value) = @_;
    $self->{_private} = $value;
}

sub getPrivate {
    my ($self) = @_;
    return $self->{_private};
}

sub setProtected {
    my ($self, $value) = @_;
    $self->{protected} = $value;
}

sub getProtected {
    my ($self) = @_;
    return $self->{protected};
}

1;

__DATA__