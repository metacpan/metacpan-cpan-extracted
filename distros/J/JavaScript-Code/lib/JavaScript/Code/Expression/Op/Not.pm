package JavaScript::Code::Expression::Op::Not;

use strict;
use vars qw[ $VERSION ];
use base qw[ JavaScript::Code::Expression::Op ];

$VERSION = '0.02';

=head1 NAME

JavaScript::Code::Expression::Op::not

=head1 METHODS

=head2 new

=cut

sub new {
    my $obj   = shift;
    my $class = ref $obj || $obj;

    die("'$class' is a unary operator and must take exactly 1 operand.")
      unless @_ == 1;

    return bless [@_], $class;
}

=head2 $self->unary

=cut

sub unary      { return 1; }

=head2 $self->precedence( )

=cut

sub precedence { return 300; }

=head2 $self->output( )

=cut

sub output {
    my ( $self, $precedence ) = @_;
    $precedence = 0 if not defined $precedence;

    my $output = ($self->children())[0]->output( $self->precedence );
    $output = "!$output";
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

