package   Mandel::Model::Field;

=head1 NAME

Mandel::Model::Field - Field meta object

=head1 DESCRIPTION

This class defines meta data for a L<field|Mandel::Model/field> object.

=cut

use Mojo::Base -base;

=head1 ATTRIBUTES

=head2 builder

Returns a code-ref or method name for building the default value for this
field or undef unless a builder was not defined.

=head2 name

Returns the name.

=head2 type_constraint

Returns the type specified as "isa" in the constructor.

=cut

sub builder         { shift->{builder} }
sub name            { shift->{name} }
sub type_constraint { shift->{isa} }

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
