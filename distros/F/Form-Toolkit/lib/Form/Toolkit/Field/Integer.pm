package Form::Toolkit::Field::Integer;
{
  $Form::Toolkit::Field::Integer::VERSION = '0.008';
}
use Moose;

extends qw/Form::Toolkit::Field/;

=head1 NAME

Form::Toolkit::Field::String - A Pure and single string field.

=cut

has '+value' => ( isa => 'Int' );

__PACKAGE__->meta->short_class('Integer');

__PACKAGE__->meta->make_immutable();
1;
