package JavaScript::Code::Expression;

use strict;
use vars qw[ $VERSION ];
use base qw[
  JavaScript::Code::Accessor
  JavaScript::Code::Value
];

__PACKAGE__->mk_ro_accessors(qw[ tree ]);

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Expression - A JavaScript Expression

=head1 DESCRIPTION

A Expression Class

=head1 METHODS

=head2 $self->command( )

=cut

sub command {
    my ( $self, $op, $left, $right ) = @_;

    my $class = 'JavaScript::Code::Expression::Op::' . $op;
    eval "require $class";
    die $@ if $@;

    my $tree;
    if ( $class->unary ) {

        $tree = $class->new(
              $left->isa('JavaScript::Code::Expression')
            ? $left->tree
            : JavaScript::Code::Expression::Op::Term->new( $left->clone )
        );

    }
    else {

        $tree = $class->new(
            $left->isa('JavaScript::Code::Expression') ? $left->tree
            : JavaScript::Code::Expression::Op::Term->new( $left->clone ),
            $right->isa('JavaScript::Code::Expression') ? $right->tree
            : JavaScript::Code::Expression::Op::Term->new( $right->clone )
        );
    }

    $self->{tree} = $tree;

    return $self;
}

=head2 $self->tree( )

Returns a tree of L<JavaScript::Code::Expression::Op>'s

=cut

=head2 $self->output( )

=cut

sub output {
    my ($self) = @_;

    my $tree = $self->tree;
    return '' unless defined $tree;
    return $tree->output;
}

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
