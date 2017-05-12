package Logic::Basic;

use 5.006001;
use strict;
no warnings;

use Perl6::Attributes;


package Logic::Basic::Sequence;

use Carp;

sub new {
    my ($class, @gens) = @_;

    bless {
        gens      => \@gens,
    } => ref $class || $class;
}

sub generators {
    my ($self) = @_;
    @.gens;
}

sub create {
    my ($self) = @_;

    $self;
}

sub enter {
    my ($self, $stack, $state) = @_;

    $stack->descend(@.gens);
    1;
}

sub backtrack { }

sub cleanup { }


package Logic::Basic::Alternation;

sub new {
    my ($class, @gens) = @_;
    
    bless {
        gens => \@gens,
    } => ref $class || $class;
}

sub generators {
    my ($self) = @_;
    @.gens;
}

sub create {
    my ($parent) = @_;

    my $self = bless {
        current => undef,
        index => 0,
        alternation => $parent,
    } => ref $parent;
}

sub enter {
    my ($self, $stack, $state) = @_;

    if ($.index < @{$.alternation{gens}}-1) {
        $stack->descend($.alternation{gens}[$.index]);
    }
    elsif ($.index == @{$.alternation{gens}}-1) {
        $stack->tail_descend($.alternation{gens}[$.index]);
    }
}

sub backtrack {
    my ($self) = @_;

    $.index++;
    goto &{$self->can('enter')};
}

sub cleanup { }


package Logic::Basic::Identity;

sub new {
    my ($class) = @_;
    $class;
}

sub create {
    my ($class) = @_;
    bless { } => ref $class || $class;
}

sub enter {
    my ($self, $stack, $state) = @_;
    1;
}

sub backtrack { }
sub cleanup { }


package Logic::Basic::Fail;

sub new {
    my ($class) = @_;
    $class;
}

sub create {
    my ($class) = @_;
    bless { } => ref $class || $class;
}

sub enter { }
sub backtrack { }
sub cleanup { }


package Logic::Basic::Assertion;

sub new {
    my ($class, $code) = @_;
    bless { 
        code => $code,
    } => ref $class || $class;
}

sub create {
    my ($self) = @_;
    $self;
}

sub enter {
    my ($self, $stack, $state) = @_;
    &.code($stack, $state);
}

sub backtrack { }
sub cleanup { }


package Logic::Basic::Rule;

sub new {
    my ($class, $code) = @_;
    bless {
        code => $code,
    } => ref $class || $class;
}

sub create {
    my ($self) = @_;
    $self;
}

sub enter {
    my ($self, $stack, $state) = @_;
    my $obj = &.code();
    if ($obj) {
        $stack->tail_descend($obj);
    }
}

sub backtrack { }
sub cleanup { }


package Logic::Basic::Bound;

sub new {
    my ($class, $var) = @_;
    bless {
        var => $var,
    } => ref $class || $class;
}

sub create { 
    my ($self) = @_;
    $self;
}

sub enter {
    my ($self, $stack, $state) = @_;
    $.var->bound($state);
}

sub backtrack { }
sub cleanup { }


package Logic::Basic::Block;

sub new {
    my ($class) = @_;
    $class;
}

sub create {
    my ($self) = @_;
    $self;
}

sub enter {
    1;
}

sub backtrack {
    1;
}

sub cleanup { }

1;
