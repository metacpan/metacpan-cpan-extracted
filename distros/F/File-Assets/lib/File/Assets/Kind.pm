package File::Assets::Kind;

use strict;
use warnings;

use Object::Tiny qw/kind type head tail/;
use Carp;

sub new {
    my $self = bless {}, shift;
    confess "Uhh, whut?" unless $self->{kind} = my $kind = shift;
    my @kind = split m/-/, $kind, 2;
    my $type = shift;
    unless ($type) {
        $type = $kind[0];
        $type = File::Assets::Util->parse_type($type);
    }
    $self->{type} = $type;
    $kind[1] = "" unless defined $kind[1];
    $self->{tail} = my $tail = $kind[1];
    $self->{head} = ($type->extensions)[0];
    
    return $self;
}

sub extension {
    my $self = shift;
    return ($self->type->extensions)[0];
}

sub is_better_than_or_equal {
    my $self = shift;
    my $other = shift;

    return 1 if $self->kind eq $other->kind;

    return $self->is_better_than($other);
}

sub is_better_than {
    my $self = shift;
    my $other = shift;
    
    return 0 unless File::Assets::Util->same_type($self->type, $other->type);
    my $self_tail = $self->tail;
    my $other_tail = $other->tail;
    if (length $self_tail && length $other_tail) {
        return 0 unless 0 == index($self->tail, $other->tail) || 0 == index($other->tail, $self->tail);
    }
    return length $self->tail > length $other->tail;
}

1;
