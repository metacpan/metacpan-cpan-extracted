
package TestFieldIdentifier;

use strict;
use warnings;

sub new {
    my ($_class) = @_;
    my $class = ref($_class) || $_class;
    my $test = {
        public => "public test",
        _protected => "protected test",
        __PRIVATE__ => "private test"
        };
    bless($test, $class);
    return $test;
}

sub setPrivate {
    my ($self, $value) = @_;
    $self->{"__PRIVATE__"} = $value;
}

sub getPrivate {
    my ($self) = @_;
    return $self->{"__PRIVATE__"};
}

sub setProtected {
    my ($self, $value) = @_;
    $self->{"_protected"} = $value;
}

sub getProtected {
    my ($self) = @_;
    return $self->{"_protected"};
}

1;

__DATA__