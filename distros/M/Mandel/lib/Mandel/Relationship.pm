package   Mandel::Relationship;
use Mojo::Base -base;
use Mojo::Loader 'load_class';

has accessor       => '';
has document_class => '';
has foreign_field  => sub { shift->document_class->model->name };
has related_class  => '';

# is this a bad memory leak? $model => $rel_obj => $_related_model
# i don't think so, since the number of objects are constant
has _related_model => sub {
  my $self = shift;
  my $e    = load_class($self->related_class);
  die $e if ref $e;
  $self->related_class->model;
};

1;

=encoding utf8

=head1 NAME

Mandel::Relationship - Base class for relationships

=head1 DESCRIPTION

L<Mandel::Relationship> is the base class for the following classes:

=over 4

=item * L<Mandel::Relationship::BelongsTo>

=item * L<Mandel::Relationship::HasMany>

=item * L<Mandel::Relationship::HasOne>

=back

=head1 ATTRIBUTES

=head2 accessor

Base name of accessor(s) created.

=head2 foreign_field

The name of the field in the foreign class which hold the "_id".

=head2 document_class

Holds the classname of the document class that holds all the accessors and
methods created.

=head2 related_class

Holds the related document class name.

=head1 SEE ALSO

L<Mojolicious>, L<Mango>, L<Mandel>

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
