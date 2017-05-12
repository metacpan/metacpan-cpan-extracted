package GOBO::ClassExpression::BooleanExpression;
use Moose;
use strict;
extends 'GOBO::ClassExpression';

has 'arguments' => (is=>'rw', isa=>'ArrayRef[GOBO::Node]',default=>sub{[]});


sub operator { undef }
sub operator_symbol { undef }


sub id {
    my $self = shift;
    return join($self->operator_symbol, 
                map { 
                    if ($_->isa('GOBO::ClassExpression::BooleanExpression')) {
                        "($_)"
                    }
                    else {
                        $_
                    }
                    } @{$self->arguments});
}

sub add_argument {
    my $self = shift;
    my $c = shift;
    push(@{$self->arguments},$c);
}

# @Override
sub normalize {
    my $self = shift;

    foreach (@{$self->arguments}) {
        if ($_->can('normalize')) {
            $_->normalize;
        }
    }

    #  A and (B and C) ==> A and B and C
    #  A or (B or C) ==> A or B or C
    
    my @new_args = ();
    foreach (@{$self->arguments}) {
        if ($_->isa('GOBO::ClassExpression::BooleanExpression')) {
            if ($_->operator eq $self->operator) {
                push(@new_args, @{$_->arguments});
                next;
            }
        }
        push(@new_args, $_);
    }
    $self->arguments(\@new_args);
    return;
}

use overload ('""' => 'as_string');
sub as_string {
    my $self = shift;
    return join($self->operator, 
                map { 
                    if (!defined($_)) {
                        '';
                    }
                    elsif ($_->isa('GOBO::ClassExpression::BooleanExpression')) {
                        "($_)"
                    }
                    else {
                        $_
                    }
                    } @{$self->arguments});
}

=head1 NAME

GOBO::ClassExpression::BooleanExpression

=head1 SYNOPSIS

=head1 DESCRIPTION

An GOBO::ClassExpression in which the members are constructed via a
boolean operation. These are AND, OR, NOT - or in set terms, GOBO::ClassExpression::Intersection, GOBO::ClassExpression::Union
or GOBO::ClassExpression::Complement)

=cut

1; 
