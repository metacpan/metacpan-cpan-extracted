package JavaScript::Code::Expression::Boolean;

use strict;
use vars qw[ $VERSION @EXPORT_OK ];
use base qw[
  JavaScript::Code::Expression
  JavaScript::Code::Expression::Node::Boolean
  Exporter
];

@EXPORT_OK = qw[
  AND OR NOT
  LESS LESS_EQUAL GREATER GREATER_EQUAL EQUAL NOT_EQUAL
];

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Expression::Boolean - A JavaScript Boolean Expression

=head1 METHODS

=head2 $self->and( ... )

logical conjunction

=cut

sub and {
    my $e = __PACKAGE__->new;
    $e->command( 'And', @_ );
    return $e;
}

=head2 $self->or( ... )

logical disjunction

=cut

sub or {
    my $e = __PACKAGE__->new;
    $e->command( 'Or', @_ );
    return $e;
}

=head2 $self->not( ... )

logical negation

=cut

sub not {
    my $e = __PACKAGE__->new;
    $e->command( 'Not', @_ );
    return $e;
}

=head2 $self->less( ... )

=cut

sub less {
    my $e = __PACKAGE__->new;
    $e->command( 'Less', @_ );
    return $e;
}

=head2 $self->less_equal( ... )

=cut

sub less_equal {
    my $e = __PACKAGE__->new;
    $e->command( 'LessEqual', @_ );
    return $e;
}

=head2 $self->greater( ... )

=cut

sub greater {
    my $e = __PACKAGE__->new;
    $e->command( 'Greater', @_ );
    return $e;
}

=head2 $self->greater_equal( ... )

=cut

sub greater_equal {
    my $e = __PACKAGE__->new;
    $e->command( 'GreaterEqual', @_ );
    return $e;
}

=head2 $self->equal( ... )

=cut

sub equal {
    my $e = __PACKAGE__->new;
    $e->command( 'Equal', @_ );
    return $e;
}

=head2 $self->not_equal( ... )

=cut

sub not_equal {
    my $e = __PACKAGE__->new;
    $e->command( 'NotEqual', @_ );
    return $e;
}

=head2 AND

=head2 OR

=head2 NOT

=head2 LESS

=head2 LESS_EQUAL

=head2 GREATER

=head2 GREATER_EQUAL

=head2 EQUAL

=head2 NOT_EQUAL

sub AND           { &and }
sub OR            { &or }
sub NOT           { &not }
sub LESS          { &less }
sub LESS_EQUAL    { &less_equal }
sub GREATER       { &greater }
sub GREATER_EQUAL { &greater_equal }
sub EQUAL         { &equal }
sub NOT_EQUAL     { &not_equal }

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
