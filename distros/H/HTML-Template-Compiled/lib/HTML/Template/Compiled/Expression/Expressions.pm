package HTML::Template::Compiled::Expression::Expressions;
use strict;
use warnings;

our $VERSION = '1.003'; # VERSION

package HTML::Template::Compiled::Expression::Defined;
use base qw(HTML::Template::Compiled::Expression);

sub init {
    my ($self, $op) = @_;
    $self->set_operands([$op]);
}
sub to_string {
    my ($self) = @_;
    my ($op) = $self->get_operands;
    return "defined ( " . (ref $op ? $op->to_string : $op) . " )";
}

package HTML::Template::Compiled::Expression::Literal;
use base qw(HTML::Template::Compiled::Expression);

sub init {
    my ($self, $op) = @_;
    $self->set_operands([$op]);
}

sub to_string {
    my ($self) = @_;
    my ($op) = $self->get_operands;
    return "$op";
}

package HTML::Template::Compiled::Expression::Ternary;
use base qw(HTML::Template::Compiled::Expression);

sub init {
    my ($self, @ops) = @_;
    $self->set_operands([@ops]);
}
sub to_string {
    my ($self,$level) = @_;
    my $indent = $self->level2indent($level);
    my ($bool, $true, $false) = $self->get_operands;
    return $indent . $bool->to_string($level) . ' ? ' .
        (ref $true ? $true->to_string($level) : $true)
        . ' : ' . (ref $false ? $false->to_string($level) : $false);
}

1;

