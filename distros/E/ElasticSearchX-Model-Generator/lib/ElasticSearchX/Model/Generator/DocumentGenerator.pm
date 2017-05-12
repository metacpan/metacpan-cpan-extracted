use strict;
use warnings;

package ElasticSearchX::Model::Generator::DocumentGenerator;
BEGIN {
  $ElasticSearchX::Model::Generator::DocumentGenerator::AUTHORITY = 'cpan:KENTNL';
}
{
  $ElasticSearchX::Model::Generator::DocumentGenerator::VERSION = '0.1.8';
}

# ABSTRACT: Moose Class generation back end for Documents/Types.

use 5.10.0;
use Moo;
use Data::Dump qw( pp );
use MooseX::Has::Sugar qw( rw required weak_ref );


has 'generator_base' => rw, required, weak_ref, handles => [qw( attribute_generator typename_translator )];


sub generate {
  my ( $self, %args ) = @_;

  my $class = $self->typename_translator->translate_to_package( typename => $args{typename} );
  my $path = $self->typename_translator->translate_to_path( typename => $args{typename} );
  my @attributes;
  for my $property_name ( sort { $a cmp $b } $self->generator_base->property_names( $args{index}, $args{typename} ) ) {
    my $property = $self->generator_base->property( $args{index}, $args{typename}, $property_name );
    push @attributes,
      $self->attribute_generator->generate(
      index        => $args{index},
      typename     => $args{typename},
      propertyname => $property_name,
      propertydata => $property,
      );
  }

  require ElasticSearchX::Model::Generator::Generated::Document;
  return ElasticSearchX::Model::Generator::Generated::Document->new(
    package => $class,
    path    => $path,
    content => $self->_fill_template(
      class      => $class,
      typename   => $args{typename},
      attributes => ( join qq{\n}, map { $_->content } @attributes )
    ),
  );
}


sub _template_string {
  return state $document_template = <<'EOF';
use strict;
use warnings FATAL => 'all';

package %s;

# ABSTRACT: Generated model for %s

use Moose;
use ElasticSearchX::Model::Document v0.1.5;

%s

no Moose;
__PACKAGE__->meta->make_immutable;

1;

EOF

}


sub _fill_template {
  my ( $self, %args ) = @_;
  return sprintf
    $self->_template_string,
    $args{class},
    $args{typename},
    $args{attributes};
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Generator::DocumentGenerator - Moose Class generation back end for Documents/Types.

=head1 VERSION

version 0.1.8

=head1 METHODS

=head2 generate

  $generated_document = $documentgenerator->generate(
    index        => ... Name of current index ...
    typename     => ... Name of the type we're generating ...
  );
  $generated_document->isa(ElasticSearchX::Model::Generator::Generated::Document);

=head1 ATTRIBUTES

=head2 generator_base

  rw, required, weak_ref

=head1 PRIVATE METHODS

=head2 _template_string

=head2 _fill_template

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
