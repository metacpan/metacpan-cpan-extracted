package Language::MinCaml::TypeInferrer;
use strict;
use Carp;
use Language::MinCaml::Type;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub error {
    croak "typing error!";
}

sub deref_type {
    my($self, $type) = @_;
    my $kind = $type->kind;

    if ($kind eq 'Fun') {
        my @new_args = ();
        for my $arg (@{$type->children->[0]}) {
            push(@new_args, $self->deref_type($arg));
        }
        $type->children->[0] = \@new_args;
        $type->children->[1] = $self->deref_type($type->children->[1]);
    }
    elsif ($kind eq 'Tuple') {
        my @new_elems = ();
        for my $elem (@{$type->children->[0]}) {
            push(@new_elems, $self->deref_type($elem));
        }
        $type->children->[0] = \@new_elems;
    }
    elsif ($kind eq 'Array') {
        $type->children->[0] = $self->deref_type($type->children->[0]);
    }
    elsif ($kind eq 'Var') {
        if ($type->children->[0]) {
            $type->children->[0] = $self->deref_type($type->children->[0]);
            return $type->children->[0];
        }
        else {
            croak "This must not happen.";
        }
    }

    return $type;
}

sub deref_ident_type {
    my($self, $ident) = @_;
    return [$ident->[0], $self->deref_type($ident->[1])];
}

sub deref_node {
    my($self, $node) = @_;
    my $kind = $node->kind;

    if ($kind eq 'Not' || $kind eq 'Neg' || $kind eq 'FNeg') {
        $node->children->[0] = $self->deref_node($node->children->[0]);
    }
    elsif ($kind eq 'Add' || $kind eq 'Sub' || $kind eq 'Eq'
           || $kind eq 'LE' || $kind eq 'FAdd' || $kind eq 'FSub'
           || $kind eq 'FMul' || $kind eq 'FDiv' || $kind eq 'Array'
           || $kind eq 'Get') {
        $node->children->[0] = $self->deref_node($node->children->[0]);
        $node->children->[1] = $self->deref_node($node->children->[1]);
    }
    elsif ($kind eq 'If' || $kind eq 'Put') {
        $node->children->[0] = $self->deref_node($node->children->[0]);
        $node->children->[1] = $self->deref_node($node->children->[1]);
        $node->children->[2] = $self->deref_node($node->children->[2]);
    }
    elsif ($kind eq 'Let') {
        $node->children->[0] = $self->deref_ident_type($node->children->[0]);
        $node->children->[1] = $self->deref_node($node->children->[1]);
        $node->children->[2] = $self->deref_node($node->children->[2]);
    }
    elsif ($kind eq 'LetRec') {
        $node->children->[0]->{ident} = $self->deref_ident_type($node->children->[0]->{ident});
        my @new_let_args = ();
        for my $let_arg (@{$node->children->[0]->{args}}) {
            push(@new_let_args, $self->deref_ident_type($let_arg));
        }
        $node->children->[0]->{args} = \@new_let_args;
        $node->children->[0]->{body} = $self->deref_node($node->children->[0]->{body});
        $node->children->[1] = $self->deref_node($node->children->[1]);
    }
    elsif ($kind eq 'App') {
        $node->children->[0] = $self->deref_node($node->children->[0]);
        my @new_app_args = ();
        for my $app_arg (@{$node->children->[1]}) {
            push(@new_app_args, $self->deref_node($app_arg));
        }
        $node->children->[1] = \@new_app_args;
    }
    elsif ($kind eq 'Tuple') {
        my @new_elems = ();
        for my $elem (@{$node->children->[0]}) {
            push(@new_elems, $self->deref_node($elem));
        }
        $node->children->[0] = \@new_elems;
    }
    elsif ($kind eq 'LetTuple') {
        my @new_elem_idents = ();
        for my $elem_ident (@{$node->children->[0]}) {
            push(@new_elem_idents, $self->deref_ident_type($elem_ident));
        }
        $node->children->[0] = \@new_elem_idents;
        $node->children->[1] = $self->deref_node($node->children->[1]);
        $node->children->[2] = $self->deref_node($node->children->[2]);
    }

    return $node;
}

sub occur {
    my($self, $left_type, $right_type) = @_;

    if ($right_type->kind eq 'Fun') {
        for my $arg_type (@{$right_type->children->[0]}) {
            return 1 if $self->occur($left_type, $arg_type);
        }

        return $self->occur($left_type, $right_type->children->[1]);
    }
    elsif ($right_type->kind eq 'Tuple') {
        for my $elem_type (@{$right_type->children->[0]}) {
            return 1 if $self->occur($left_type, $elem_type);
        }

        return 0;
    }
    elsif ($right_type->kind eq 'Array') {
        return $self->occur($left_type, $right_type->children->[0]);
    }
    elsif ($right_type->kind eq 'Var' && $left_type == $right_type) {
        return 1;
    }
    elsif ($right_type->kind eq 'Var' && $right_type->children->[0]) {
        return $self->occur($left_type, $right_type->children->[0]);
    }
    else {
        return 0;
    }
}

sub unify {
    my($self, $left_type, $right_type) = @_;

    return if $left_type == $right_type;

    if (($left_type->kind eq 'Unit' && $right_type->kind eq 'Unit')
        || ($left_type->kind eq 'Bool' && $right_type->kind eq 'Bool')
        || ($left_type->kind eq 'Int' && $right_type->kind eq 'Int')
        || ($left_type->kind eq 'Float' && $right_type->kind eq 'Float')) {
    }
    elsif ($left_type->kind eq 'Fun' && $right_type->kind eq 'Fun') {
        $self->error unless @{$left_type->children->[0]} == @{$right_type->children->[0]};

        for my $index (0..$#{$left_type->children->[0]}) {
            $self->unify($left_type->children->[0]->[$index],
                         $right_type->children->[0]->[$index]);
        }

        $self->unify($left_type->children->[1], $right_type->children->[1]);
    }
    elsif ($left_type->kind eq 'Tuple' && $right_type->kind eq 'Tuple') {
        $self->error unless @{$left_type->children->[0]} == @{$right_type->children->[0]};

        for my $index (0..$#{$left_type->children->[0]}) {
            $self->unify($left_type->children->[0]->[$index],
                         $right_type->children->[0]->[$index]);
        }
    }
    elsif ($left_type->kind eq 'Array' && $right_type->kind eq 'Array') {
        $self->unify($left_type->children->[0], $right_type->children->[0]);
    }
    elsif ($left_type->kind eq 'Var' && $right_type->kind eq 'Var'
           && $left_type->children->[0] && $right_type->children->[0]
           && $left_type->children->[0]->kind eq $right_type->children->[0]->kind) {
    }
    elsif ($left_type->kind eq 'Var' && $left_type->children->[0]) {
        $self->unify($left_type->children->[0], $right_type);
    }
    elsif ($right_type->kind eq 'Var' && $right_type->children->[0]) {
        $self->unify($left_type, $right_type->children->[0]);
    }
    elsif ($left_type->kind eq 'Var' && !$self->occur($left_type, $right_type)) {
        $left_type->children->[0] = $right_type;
    }
    elsif ($right_type->kind eq 'Var' && !$self->occur($right_type, $left_type)) {
        $right_type->children->[0] = $left_type;
    }
    else {
        $self->error;
    }

    return;
}

sub infer_rec {
    my($self, $node, %env) = @_;
    my $kind = $node->kind;

    if ($kind eq 'Unit') {
        return Type_Unit();
    }
    elsif ($kind eq 'Bool') {
        return Type_Bool();
    }
    elsif ($kind eq 'Int') {
        return Type_Int();
    }
    elsif ($kind eq 'Float') {
        return Type_Float();
    }
    elsif ($kind eq 'Not') {
        $self->unify(Type_Bool, $self->infer_rec($node->children->[0], %env));

        return Type_Bool();
    }
    elsif ($kind eq 'Neg') {
        $self->unify(Type_Int, $self->infer_rec($node->children->[0], %env));

        return Type_Int();
    }
    elsif ($kind eq 'Add' || $kind eq 'Sub') {
        $self->unify(Type_Int, $self->infer_rec($node->children->[0], %env));
        $self->unify(Type_Int, $self->infer_rec($node->children->[1], %env));

        return Type_Int();
    }
    elsif ($kind eq 'FNeg') {
        $self->unify(Type_Float, $self->infer_rec($node->children->[0], %env));

        return Type_Float();
    }
    elsif ($kind eq 'FAdd' || $node->kind eq 'FSub'
           || $kind eq 'FMul' || $kind eq 'FDiv') {
        $self->unify(Type_Float, $self->infer_rec($node->children->[0], %env));
        $self->unify(Type_Float, $self->infer_rec($node->children->[1], %env));

        return Type_Float();
    }
    elsif ($kind eq 'Eq' || $kind eq 'LE') {
        $self->unify($self->infer_rec($node->children->[0], %env),
                     $self->infer_rec($node->children->[1], %env));

        return Type_Bool();
    }
    elsif ($kind eq 'If') {
        $self->unify($self->infer_rec($node->children->[0], %env),
                     Type_Bool());
        my $stat_type = $self->infer_rec($node->children->[1], %env);
        $self->unify($stat_type, $self->infer_rec($node->children->[2], %env));

        return $stat_type;
    }
    elsif ($kind eq 'Let') {
        $self->unify($node->children->[0]->[1],
                     $self->infer_rec($node->children->[1], %env));
        $env{$node->children->[0]->[0]} = $node->children->[0]->[1];

        return $self->infer_rec($node->children->[2], %env);
    }
    elsif ($kind eq 'Var') {
        my $ident_name = $node->children->[0];

        if (exists $env{$ident_name}) {
            return $env{$ident_name};
        }
        else {
            $self->error;
        }
    }
    elsif ($kind eq 'LetRec') {
        my $ident = $node->children->[0]->{ident};
        my $let_args = $node->children->[0]->{args};
        my $body = $node->children->[0]->{body};
        $env{$ident->[0]} = $ident->[1];
        my @arg_types = ();
        my %tmp_env = %env;

        for my $arg (@$let_args) {
            push(@arg_types, $arg->[1]);
            $tmp_env{$arg->[0]} = $arg->[1];
        }

        $self->unify($ident->[1],
                     Type_Fun(\@arg_types, $self->infer_rec($body, %tmp_env)));

        return $self->infer_rec($node->children->[1], %env);
    }
    elsif ($kind eq 'App') {
        my $app_ident_type = $self->infer_rec($node->children->[0], %env);
        my $app_args = $node->children->[1];
        my @arg_types = ();

        for my $arg (@$app_args) {
            push(@arg_types, $self->infer_rec($arg, %env));
        }

        my $tmp_type = Type_Var();
        $self->unify($app_ident_type, Type_Fun(\@arg_types, $tmp_type));

        return $tmp_type;
    }
    elsif ($kind eq 'Tuple') {
        my @elem_types = ();

        for my $elem (@{$node->children->[0]}) {
            push(@elem_types, $self->infer_rec($elem, %env));
        }

        return Type_Tuple(\@elem_types);
    }
    elsif ($kind eq 'LetTuple') {
        my @elem_types = ();
        my %tmp_env = %env;

        for my $elem_ident (@{$node->children->[0]}) {
            push(@elem_types, $elem_ident->[1]);
            $tmp_env{$elem_ident->[0]} = $elem_ident->[1];
        }
        $self->unify(Type_Tuple(\@elem_types),
                     $self->infer_rec($node->children->[1], %env));

        return $self->infer_rec($node->children->[2], %tmp_env);
    }
    elsif ($kind eq 'Array') {
        $self->unify($self->infer_rec($node->children->[0], %env), Type_Int());

        return Type_Array($self->infer_rec($node->children->[1], %env));
    }
    elsif ($kind eq 'Get') {
        my $tmp_type = Type_Var();

        $self->unify(Type_Array($tmp_type),
                     $self->infer_rec($node->children->[0], %env));
        $self->unify(Type_Int(),
                     $self->infer_rec($node->children->[1], %env));

        return $tmp_type;
    }
    elsif ($kind eq 'Put') {
        my $tmp_type = $self->infer_rec($node->children->[2], %env);

        $self->unify(Type_Array($tmp_type),
                     $self->infer_rec($node->children->[0], %env));
        $self->unify(Type_Int(),
                     $self->infer_rec($node->children->[1], %env));

        return Type_Unit();
    }
    else {
        croak "This must not happen.";
    }
}

sub infer {
    my($self, $root_node, %type_env) = @_;
    my $top_level_type = $self->infer_rec($root_node, %type_env);

    $self->unify($top_level_type, Type_Unit());
    $self->deref_node($root_node);

    return;
}

1;
