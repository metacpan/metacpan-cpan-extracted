package Graph::Template::Container;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Graph::Template::Base);

    use Graph::Template::Base;
}

# Containers are objects that can contain arbitrary elements, such as
# PageDefs or Loops.

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{ELEMENTS} = [] unless UNIVERSAL::isa($self->{ELEMENTS}, 'ARRAY');

    return $self;
}

sub _do_page
{
    my $self = shift;
    my ($method, $context) = @_;

    for my $e (@{$self->{ELEMENTS}})
    {
        $e->enter_scope($context);
        $e->$method($context);
        $e->exit_scope($context, 1);
    }

    return 1;
}

sub begin_page { _do_page 'begin_page', @_ }
sub end_page   { _do_page 'end_page', @_   }

sub iterate_over_children
{
    my $self = shift;
    my ($context) = @_;

    my $continue = 1;

    for my $e (
        @{$self->{ELEMENTS}})
    {
        $e->enter_scope($context);

        my $rc = $e->render($context);
        $continue = $rc if $continue;

        $e->exit_scope($context);
    }

    return $continue;
}

sub render { $_[0]->iterate_over_children($_[1]) }
#{
#    my $self = shift;
#    my ($context) = @_;
#
#    return $self->iterate_over_children($context);
#}

sub max_of
{
    my $self = shift;
    my ($context, $attr) = @_;

    my $max = $context->get($self, $attr);

    ELEMENT:
    foreach my $e (@{$self->{ELEMENTS}})
    {
        $e->enter_scope($context);

        my $v = $e->isa('CONTAINER')
            ? $e->max_of($context, $attr)
            : $e->calculate($context, $attr);

        $max = $v if $max < $v;

        $e->exit_scope($context, 1);
    }

    return $max;
}

sub total_of
{
    my $self = shift;
    my ($context, $attr) = @_;

    my $total = 0;

    ELEMENT:
    foreach my $e (@{$self->{ELEMENTS}})
    {
        $e->enter_scope($context);

        $total += $e->isa('CONTAINER')
            ? $e->total_of($context, $attr)
            : $e->calculate($context, $attr);

        $e->exit_scope($context, 1);
    }

    return $total;
}

1;
__END__
