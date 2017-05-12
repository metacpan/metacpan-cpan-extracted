# $Header: $
#
# This file is fodder for various Devel::Refactor tests
###############################################################################

package MyClass;
use strict;
use warnings;

sub new {
    my ($class,@args) = @_;
    my $self = {};
    $class = ref $class ? ref $class : $class;
    bless $self, $class;
    $self->oldSub(@args);
}

sub oldSub {
    my $self = shift;
    $self->{values} = join ',', @_;
}