package Language::MinCaml::Evaluator;
use strict;
use Carp;
use Language::MinCaml::Node;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub error {
    croak "evaluation error!";
}

sub compare {
    my($self, $left, $right) = @_;

    if (ref($left) eq 'ARRAY') {
        if (@$left == @$right) {
            for my $index (0..$#{$left}) {
                my $result = $self->compare($left->[$index], $right->[$index]);
                return $result if $result != 0;
            }
            return 0;
        }
        else {
            return @$left <=> @$right;
        }
    }
    elsif (defined $left) {
        return $left <=> $right;
    }
    else {
        return 0;
    }
}

sub evaluate {
    my($self, $node, %env) = @_;
    my $kind = $node->kind;

    if ($kind eq 'Unit') {
        return;
    }
    elsif ($kind eq 'Bool') {
        return $node->children->[0] eq 'true' ? 1 : 0;
    }
    elsif ($kind eq 'Int' || $kind eq 'Float') {
        return $node->children->[0] + 0;
    }
    elsif ($kind eq 'Not') {
        return $self->evaluate($node->children->[0], %env) ? 0 : 1;
    }
    elsif ($kind eq 'Neg' || $kind eq 'FNeg') {
        return -1 * $self->evaluate($node->children->[0], %env);
    }
    elsif ($kind eq 'Add' || $kind eq 'FAdd') {
        return $self->evaluate($node->children->[0], %env) + $self->evaluate($node->children->[1], %env);
    }
    elsif ($kind eq 'Sub' || $kind eq 'FSub') {
        return $self->evaluate($node->children->[0], %env) - $self->evaluate($node->children->[1], %env);
    }
    elsif ($kind eq 'FMul') {
        return $self->evaluate($node->children->[0], %env) * $self->evaluate($node->children->[1], %env);
    }
    elsif ($kind eq 'FDiv') {
        return $self->evaluate($node->children->[0], %env) / $self->evaluate($node->children->[1], %env);
    }
    elsif ($kind eq 'Eq') {
        my $left = $self->evaluate($node->children->[0], %env);
        my $right = $self->evaluate($node->children->[1], %env);

        if ($self->compare($left, $right) == 0) {
            return 1;
        }
        else {
            return 0;
        }
    }
    elsif ($kind eq 'LE') {
        my $left = $self->evaluate($node->children->[0], %env);
        my $right = $self->evaluate($node->children->[1], %env);

        if ($self->compare($left, $right) <= 0) {
            return 1;
        }
        else {
            return 0;
        }
    }
    elsif ($kind eq 'If') {
        if ($self->evaluate($node->children->[0], %env)) {
            return $self->evaluate($node->children->[1], %env);
        }
        else {
            return $self->evaluate($node->children->[2], %env);
        }
    }
    elsif ($kind eq 'Let') {
        $env{$node->children->[0]->[0]} = $self->evaluate($node->children->[1], %env);

        return $self->evaluate($node->children->[2], %env);
    }
    elsif ($kind eq 'Var') {
        return $env{$node->children->[0]};
    }
    elsif ($kind eq 'LetRec') {
        my $body = $node->children->[0]->{body};
        my @arg_names = ();

        for my $arg (@{$node->children->[0]->{args}}) {
            push(@arg_names, $arg->[0]);
        }

        $env{$node->children->[0]->{ident}->[0]} = sub {
            my(@arg_values) = @_;
            for my $index (0..$#arg_values) {
                $env{$arg_names[$index]} = $arg_values[$index];
           }
            return $self->evaluate($body, %env);
        };

        return $self->evaluate($node->children->[1], %env);
    }
    elsif ($kind eq 'App') {
        my $func = $self->evaluate($node->children->[0], %env);
        my $args = $node->children->[1];
        my @evaluated_args = ();

        for my $arg (@$args) {
            push(@evaluated_args, $self->evaluate($arg, %env));
        }

        return $func->(@evaluated_args);
    }
    elsif ($kind eq 'Tuple') {
        my $elems = $node->children->[0];
        my @evaluated_elems = ();

        for my $elem (@$elems) {
            push(@evaluated_elems, $self->evaluate($elem, %env));
        }

        return \@evaluated_elems;
    }
    elsif ($kind eq 'LetTuple') {
        my $elem_idents = $node->children->[0];
        my $elem_values = $self->evaluate($node->children->[1], %env);

        for my $index (0..$#{$elem_idents}) {
            $env{$elem_idents->[$index]} = $elem_values->[$index];
        }

        return $self->evaluate($node->children->[2], %env);
    }
    elsif ($kind eq 'Array') {
        my $number = $self->evaluate($node->children->[0], %env);
        my $value = $self->evaluate($node->children->[1], %env);
        my @array = ();

        for (1..$number) {
            push(@array, $value);
        }

        return \@array;
    }
    elsif ($kind eq 'Get') {
        my $array = $self->evaluate($node->children->[0], %env);
        my $index = $self->evaluate($node->children->[1], %env);

        return $array->[$index];
    }
    elsif ($kind eq 'Put') {
        my $array = $self->evaluate($node->children->[0], %env);
        my $index = $self->evaluate($node->children->[1], %env);
        my $value = $self->evaluate($node->children->[2], %env);

        $array->[$index] = $value;

        return;
    }
    else {
        croak "This must not happen.";
    }
}

1;
