package Logic::Data;

use 5.006001;

use strict;
no warnings;

use Exporter;
use base 'Exporter';

use Perl6::Attributes;
use Scalar::Util qw<blessed>;
use Carp;

use Logic::Basic;
use Logic::Variable;

our @EXPORT = qw<>;
our @EXPORT_OK = qw<resolve>;

sub resolve {
    my ($data, $state, %options) = @_;
    if (blessed($data) && $data->isa('Logic::Variable')) {
        if ($data->bound($state)) {
            @_ = ($data->binding($state), $state, %options);  goto &resolve;
        }
        else {
            if ($options{vars} eq 'string') {
                $data->id;
            }
            elsif ($options{vars}) {
                $data;
            }
            else {
                croak "Variadic state, unable to resolve";
            }
        }
    }
    elsif (ref $data eq 'ARRAY') {
        [ map { resolve($_, $state, %options) } @$data ];
    }
    elsif (blessed($data) && $data->can('resolve')) {
        @_ = ($data, $state, %options);  goto &{$data->can('resolve')};
    }
    else {
        $data;
    }
}


package Logic::Data::Unify;

use Scalar::Util qw<blessed>;
use Carp;

sub new {
    my ($class, $a, $b) = @_;
    bless {
        a => $a,
        b => $b,
    } => ref $class || $class;
}

sub create {
    my ($self) = @_;
    $self;
}

sub enter {
    my ($self, $stack, $state) = @_;

    # get information into nice testable forms
    #   lvar: $.a is a variable
    #   left: otherwise, what data is $.a
    
    # XXX: refactor this double programming!
    my ($lvar, $rvar, $left, $right);
    if (blessed($.a) && $.a->isa('Logic::Variable')) {
        if ($.a->bound($state)) {
            $left = $.a->binding($state);
            if (blessed($left) && $left->isa('Logic::Variable')) {
                return $stack->tail_descend(Logic::Data::Unify->new($left, $.b));
            }
        }
        else {
            $lvar = 1;  $left = $.a;
        }
    }
    else {
        $left = $.a;
    }

    if (blessed($.b) && $.b->isa('Logic::Variable')) {
        if ($.b->bound($state)) {
            $right = $.b->binding($state);
            if (blessed($right) && $right->isa('Logic::Variable')) {
                return $stack->tail_descend(Logic::Data::Unify->new($.a, $right));
            }
        }
        else {
            $rvar = 1;  $right = $.b;
        }
    }
    else {
        $right = $.b;
    }
    
    $state->save;
    
    if ($lvar && $rvar) {   # variable-variable
        my $intermediate = Logic::Variable->new;
        $left->bind($state, $intermediate);
        $right->bind($state, $intermediate);
        1;
    }
    elsif ($lvar) {         # variable-data
        $left->bind($state, $right);
        1;
    }
    elsif ($rvar) {         # data-variable
        $right->bind($state, $left);
        1;
    }
    else {                  # data-data
        @_ = ($self, $stack, $state, $left, $right);
        goto &{$self->can('unify_data_data')};
    }
}

sub unify_data_data {
    my ($self, $stack, $state, $left, $right) = @_;
    
    unless (ref $left || ref $right) {
        $left eq $right ? 1 : undef;
    }
    elsif (ref $left eq 'ARRAY' && ref $right eq 'ARRAY') {
        if (!@$left && !@$right) {
            1;
        }
        elsif (@$left && @$right) {
            my $head = Logic::Data::Unify->new($left->[0], $right->[0]);
            my $tail = Logic::Data::Unify->new([ @$left[1..$#$left] ], [ @$right[1..$#$right] ]);
            $stack->descend($head, $tail);
        }
        else {
            undef;  # a null list is not equal to a non-null list
        }
    }
    else {
        if (blessed($left) && $left->can('unify')) {
            @_ = ($left, $right, $stack, $state);  goto &{$left->can('unify')};
        }
        elsif (blessed($right) && $right->can('unify')) {
            @_ = ($right, $left, $stack, $state);  goto &{$right->can('unify')};
        }
        else {
            $left == $right;  # referentially equal (or overloadedly equal)
        }
    }
}

sub backtrack { }

sub cleanup {
    my ($self, $stack, $state) = @_;
    $state->restore;
}


package Logic::Data::Cons;

use Scalar::Util qw<blessed>;

sub new {
    my ($class, $head, $tail) = @_;
    bless {
        head => $head,
        tail => $tail,
    } => ref $class || $class;
}

sub head {
    my ($self) = @_;
    $.head;
}

sub tail {
    my ($self) = @_;
    $.tail;
}

sub resolve {
    my ($self, $state, %options) = @_;
    my $head = Logic::Data::resolve($.head, $state, %options);
    my $tail = Logic::Data::resolve($.tail, $state, %options);
    if (ref $tail eq 'ARRAY') {
        [ $head, @$tail ];
    }
    else {
        $self->new($head, $tail);
    }
}

sub unify {
    my ($self, $other, $stack, $state) = @_;
    if (blessed($other) && $other->isa('Logic::Data::Cons')) {
        $stack->descend(
            Logic::Data::Unify->new($self->head, $other->head),
            Logic::Data::Unify->new($self->tail, $other->tail),
        );
    }
    elsif (ref $other eq 'ARRAY') {
        if (@$other) {
            $stack->descend(
                Logic::Data::Unify->new($self->head, $other->[0]),
                Logic::Data::Unify->new($self->tail, [ @$other[1..$#$other] ]),
            );
        }
    }
}


package Logic::Data::Assign;

sub new {
    my ($class, $code, @vars) = @_;
    bless {
        vars => \@vars,
        code => $code,
    } => ref $class || $class;
}

sub create {
    my ($self) = @_;
    $self;
}

sub enter {
    my ($self, $stack, $state) = @_;
    my (@vals) = &.code();
    splice @vals, scalar @.vars;
    $stack->descend(
        map { Logic::Data::Unify->new($.vars[$_], $vals[$_]) } 0..@.vars-1
    )
}

sub backtrack { }
sub cleanup { }


package Logic::Data::For;

sub new {
    my ($class, $var, @values) = @_;
    bless {
        var => $var,
        values => \@values,
    } => ref $class || $class;
}

sub create {
    my ($self) = @_;
    $self;
}

sub enter {
    my ($self, $stack, $state) = @_;
    $stack->tail_descend(
        Logic::Basic::Alternation->new(
            map { Logic::Data::Unify->new($.var, $_) } @.values
        ),
    );
}

sub backtrack { }
sub cleanup { }


package Logic::Data::Disjunction;

sub new {
    my ($class, @values) = @_;
    bless {
        values => \@values,
    } => ref $class || $class;
}

sub unify {
    my ($self, $other, $stack, $state) = @_;
    $stack->tail_descend(
        Logic::Data::For->new($other, @.values),
    );
}

1;
