package JavaScript::Code::Condition;

use strict;
use vars qw[ $VERSION ];
use base qw[ JavaScript::Code::Element ];

__PACKAGE__->mk_ro_accessors(qw[ ifs ]);

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Condition - A JavaScript Condition

=head1 METHODS

=head2 new

=head2 $self->add_if( %args | \%args )

Adds a new if statement.

I<%args> must contain the following keys:

- expression: a L<JavaScript::Code::Expression::Boolean> object

- block: a L<JavaScript::Code::Block> object

=cut

sub add_if {
    my $self = shift;

    my $args = $_[0];
    $args = [ $self->args(@_) ]
      unless ref $args eq 'ARRAY';

    foreach my $c ( @{$args} ) {

        my $expr = $c->{expression};
        die "Expression must be a 'JavaScript::Code::Expression::Boolean'."
          unless ref $expr
          and $expr->isa('JavaScript::Code::Expression::Boolean');

        my $block = $c->{block};
        die "Block must be a 'JavaScript::Code::Block'."
          unless ref $block
          and $block->isa('JavaScript::Code::Block');

        my $cond = {
            expression => $expr,
            block      => $block->clone->parent($self),
        };

        $self->{ifs} = []
          unless defined $self->{ifs};

        push @{ $self->{ifs} }, $cond;
    }

    return $self;
}

=head2 $self->else( $block )

Sets the else statement.

I<$block> must be a L<JavaScript::Code::Block>

=cut

sub else {
    my $self = shift;
    if (@_) {
        my $args = $self->args(@_);

        my $block = $args->{block} || shift;
        die "Block must be a 'JavaScript::Code::Block'."
          unless ref $block
          and $block->isa('JavaScript::Code::Block');

        $self->{else} = $block->clone->parent($self);

        return $self;
    }
    else {
        return $self->{else};
    }
}

=head2 $self->output( )

=cut

sub output {
    my $self  = shift;
    my $scope = shift || 1;

    die "At least one if-statement is needed."
      unless defined $self->ifs;

    my $indenting = $self->get_indenting($scope);
    my $output    = '';

    my $max = @{ $self->ifs };
    for ( my $i = 0 ; $i < $max ; ++$i ) {
        $output .= $indenting;
        $output .= "else " if $i;

        my $c = $self->ifs->[$i];
        $output .= "if ( " . $c->{expression}->output($scope) . " )\n";
        $output .= $c->{block}->output($scope);
    }

    if ( defined $self->else ) {
        $output .= $indenting;
        $output .= "else\n";
        $output .= $self->else->output;
    }

    return $output;
}

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

1;
