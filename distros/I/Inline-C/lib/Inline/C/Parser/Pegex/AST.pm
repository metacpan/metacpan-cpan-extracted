use strict; use warnings;
package Inline::C::Parser::Pegex::AST;
use Pegex::Base;

extends 'Pegex::Tree';

has data => {};

sub initial {
    my ($self) = @_;
    my $data = {
        functions => [],
        function => {},
        done => {},
    };
    $self->data($data);
}

sub final {
    my ($self, $got) = @_;
    return $self->{data};
}

sub got_function_definition {
    my ($self, $ast) = @_;
    my ($rtype, $name, $args) = @$ast;
    my ($rname, $rstars) = @$rtype;
    my $data = $self->data;
    my $def = $data->{function}{$name} = {};
    push @{$data->{functions}}, $name;
    $def->{return_type} = $rname . ($rstars ? " $rstars" : '');
    $def->{arg_names} = [];
    $def->{arg_types} = [];
    for my $arg (@$args) {
        my ($type, $stars, $name) = @$arg;
        push @{$def->{arg_names}}, $name;
        push @{$def->{arg_types}}, $type . ($stars ? " $stars" : '');
    }
    $data->{done}{$name} = 1;
    return;
}


sub got_arg {
    my ($self, $ast) = @_;
    pop @$ast;
    return $ast;
}

1;
