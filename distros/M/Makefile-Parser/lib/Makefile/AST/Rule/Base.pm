package Makefile::AST::Rule::Base;

use strict;
use warnings;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_ro_accessors(qw{
    normal_prereqs order_prereqs commands colon
    target
});

sub add_command ($$) {
    my ($self, $cmd) = @_;
    push @{ $self->{commands} }, $cmd;
}

sub has_command ($) {
    my ($self) = @_;
    return scalar @{ $self->commands };
}

1;
