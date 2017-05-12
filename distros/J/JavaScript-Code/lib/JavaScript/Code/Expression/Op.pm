package JavaScript::Code::Expression::Op;

use strict;
use vars qw[ $VERSION ];
use JavaScript::Code::Expression::Op::Term;

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Expression::Node - Represents a Node in JavaScript Expression

=head1 METHODS

=head2 new

=cut

sub new {
    my $obj   = shift;
    my $class = ref $obj || $obj;

    die("'$class' is a binary operator and must take exactly 2 operands.")
      unless @_ == 2;

    return bless [@_], $class;
}

=head2 children

=cut

sub children { return @{ shift() } }

=head2 unary

=cut

sub unary { return 0; }

=head2 output

=cut

sub output {
    my ( $self, $precedence ) = @_;
    $precedence = 0 if not defined $precedence;
    my $output = join $self->op,
      map { $_->output( $self->precedence ) } $self->children;

    $output = "($output)" if $precedence > $self->precedence;

    return $output;
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
