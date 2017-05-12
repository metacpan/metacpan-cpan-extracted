package JavaScript::Code::Function::Result::Element;

use strict;
use vars qw[ $VERSION ];
use base qw[
  JavaScript::Code::Element
];

__PACKAGE__->mk_accessors(qw[ value ]);

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Function::Result::Element - A JavaScript Function Result Element

=head1 METHODS

=head2 $self->output( )

=cut

sub output {
    my $self = shift;
    my $scope = shift || 1;
    my $indenting = $self->get_indenting($scope);

    return $indenting . $self->value . ";\n";
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
