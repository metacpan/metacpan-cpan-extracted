
package TestBase;

use strict;
use warnings;

sub new {
    my ($_class) = @_;
    my $class = ref($_class) || $_class;
    my $test = {
        protected => "protected test",
        _private => "private test"
        };
    bless($test, $class);
    return $test;
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