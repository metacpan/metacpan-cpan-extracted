use strict;
use warnings;

package ElasticSearchX::Model::Generator;
BEGIN {
  $ElasticSearchX::Model::Generator::AUTHORITY = 'cpan:KENTNL';
}
{
  $ElasticSearchX::Model::Generator::VERSION = '0.1.8';
}

# ABSTRACT: Create a suite of ESX::Model classes from an existing mapping.

use Moo;



use Sub::Exporter -setup => {
  exports => [
    generate_model => sub {
      my $class = __PACKAGE__;
      my $call  = $class->can('new');
      return sub {
        unshift @_, $class;
        goto $call;
      };
    },
  ]
};
use MooseX::Has::Sugar qw( rw ro required );
use Sub::Quote qw( quote_sub );


has mapping_url => rw, required;
has base_dir    => rw, required;


has generator_base_class => rw, default => quote_sub(q{ 'ElasticSearchX::Model::Generator' });
has generated_base_class => rw, default => quote_sub(q{ 'MyModel' });


has document_generator_class  => is => lazy =>,;
has attribute_generator_class => is => lazy =>,;
has typename_translator_class => is => lazy =>,;


has document_generator  => is => lazy =>,;
has attribute_generator => is => lazy =>,;
has typename_translator => is => lazy =>,;


has _mapping_content => is => lazy =>,;
has _ua              => is => lazy =>,;
has _mapping_data    => is => lazy =>,;


sub _build__ua {
  require HTTP::Tiny;
  return HTTP::Tiny->new();
}


sub _build_document_generator_class {
  my $self = shift;
  return $self->generator_base_class . '::DocumentGenerator';
}


sub _build_document_generator {
  my $self = shift;
  require Module::Runtime;
  return Module::Runtime::use_module( $self->document_generator_class )->new( generator_base => $self, );
}


sub _build_attribute_generator_class {
  my $self = shift;
  return $self->generator_base_class . '::AttributeGenerator';
}


sub _build_attribute_generator {
  my $self = shift;
  require Module::Runtime;
  return Module::Runtime::use_module( $self->attribute_generator_class )->new( generator_base => $self );
}


sub _build_typename_translator_class {
  my $self = shift;
  return $self->generator_base_class . '::TypenameTranslator';
}


sub _build_typename_translator {
  my $self = shift;
  require Module::Runtime;
  return Module::Runtime::use_module( $self->typename_translator_class )->new( generator_base => $self );
}


sub _build__mapping_content {
  my $self     = shift;
  my $response = $self->_ua->get( $self->mapping_url );
  if ( not $response->{success} ) {
    require Carp;
    Carp::confess( sprintf qq[Failed to fetch mapping:\n\tstatus=%s\n\treason=%s\n], $response->{status}, $response->{reason} );
  }
  if ( exists $response->{headers}->{'content-length'}
    and length $response->{content} != $response->{headers}->{'content-length'} )
  {
    require Carp;
    Carp::confess(
      sprintf qq[Content length did not match expected length, _mapping failed to fetch completely.\n\tgot=%s\n\texpected%s\n],
      length $response->{content},
      $response->{headers}->{'Content-Length'}
    );
  }
  if ( not exists $response->{headers}->{'content-length'} ) {
    if ( not exists $response->{headers}->{'transfer-encoding'} or $response->{headers}->{'transfer-encoding'} ne 'chunked' ) {
      require Carp;
      Carp::carp(q[No content length and no transfer-encoding=chunked, data could be broken]);
    }
  }
  return $response->{content};
}


sub _build__mapping_data {
  my $self    = shift;
  my $content = $self->_mapping_content;
  require JSON;
  return JSON->new()->utf8(1)->decode($content);
}


## no critic ( RequireArgUnpacking ProhibitBuiltinHomonyms )
sub index_names {
  return keys %{ $_[0]->_mapping_data };
}


sub index {
  if ( $_[1] eq q{} ) {
    return $_[0]->_mapping_data;
  }
  return $_[0]->_mapping_data->{ $_[1] };
}


sub type_names {
  my ( $self, $index ) = @_;
  return keys %{ $self->index($index) };
}


sub type {
  my ( $self, $index, $type ) = @_;
  return $self->index($index)->{$type};
}


sub property_names {
  my ( $self, $index, $type ) = @_;
  return keys %{ $self->properties( $index, $type ) };
}


sub properties {
  my ( $self, $index, $type ) = @_;
  return $self->type( $index, $type )->{properties};
}


sub property {
  my ( $self, $index, $type, $property ) = @_;
  return $self->properties( $index, $type )->{$property};
}


sub documents {
  my ( $self, @indices ) = @_;
  if ( not @indices ) {
    @indices = $self->index_names;
  }
  my @documents;
  for my $index (@indices) {
    for my $typename ( $self->type_names($index) ) {
      push @documents,
        $self->document_generator->generate(
        index    => $index,
        typename => $typename,
        typedata => $self->type( $index, $typename ),
        );
    }
  }
  return @documents;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Generator - Create a suite of ESX::Model classes from an existing mapping.

=head1 VERSION

version 0.1.8

=head1 SYNOPSIS

  use ElasticSearchX::Model::Generator qw( generate_model );

  my $instance = generate_model(
    mapping_url => 'http://someserver:port/path/_mapping',
    generated_base_class => 'MyModel',
    base_dir => "../path/to/export/dir/"
  );

  for my $document ( $instance->documents ) {
    # Write the document to disk
    $document->write();
    # Alternatively, load the generated document into memory avoiding writing to disk
    $document->evaluate();
  }

=head1 DESCRIPTION

B<ALPHA Code>: This class at present only contains code sufficient for very simple package generation for use in creating a model from an existing mapping for the purposes of search.

=head1 EXPORTS

=head2 generate_model

this is just a sugar syntax for ESX:M:G->new() you can elect to import to make your code slightly shorter.

=head1 METHODS

=head2 index_names

  @names = $esmg->index_names

returns the names of all indexes specified in the C<_mapping>

=head2 index

  $data = $esmg->index('') # If indexes are not in the data set
  $data = $esmg->index('cpan_v1') # if indexes are in the data set

Returns the data set nested under the specified index.

=head2 type_names

  @names = $esmg->type_names( $index )
  @names = $esmg->type_names('')  # return all types defined in an index-free dataset.
  @names = $esmg->type_names('cpan_v1') # return all types in the cpan_v1 index.

=head2 type

  $data = $esmg->type( $index, $type )
  $data = $esmg->type( '', 'File' )    # get type 'File' from an index-free dataset
  $data = $esmg->type( 'cpan_v1', 'File' )    # get type 'File' from the cpan_v1 index

=head2 property_names

  @names = $esmg->property_names( $index, $type )

=head2 properties

  $properties = $esmg->properties( $index, $type )

=head2 property

  $property = $esmg->property( $index, $type, $propertyname )

=head2 documents

  @documents = $esmg->documents(); # all documents for all indexes
  @documents = $esmg->documents('cpan_v1'); # all documents for cpan_v1
  @documents = $esmg->documents(''); # all documents for an index-free dataset.

=head1 ATTRIBUTES

=head2 mapping_url

  rw, required

=head2 base_dir

  rw, required

=head2 generator_base_class

  rw, default: ElasticSearchX::Model::Generator

=head2 generated_base_class

  rw, default: MyModel

=head2 document_generator_class

  lazy

=head2 attribute_generator_class

  lazy

=head2 typename_translator_class

  lazy

=head2 document_generator

  lazy

=head2 attribute_generator

  lazy

=head2 typename_translator

  lazy

=head1 PRIVATE ATTRIBUTES

=head2 _mapping_content

  lazy

=head2 _ua

  lazy

=head2 _mapping_data

  lazy

=head1 PRIVATE METHODS

=head2 _build__ua

returns an C<HTTP::Tiny> instance.

=head2 _build_document_generator_class

  generator_base_class + '::DocumentGenerator'

=head2 _build_document_generator

returns an instance of C<$document_generator_class>

=head2 _build_attribute_generator_class

  generator_base_class + '::AttributeGenerator'

=head2 _build_attribute_generator

returns an instance of C<$attribute_generator_class>

=head2 _build_typename_translator_class

  generator_base_class + '::TypenameTranslator'

=head2 _build_typename_translator

returns an instance of C<$typename_translator_class>

=head2 _build__mapping_content

returns the content of the URL at C<mapping_url>

=head2 _build__mapping_data

returns the decoded data from C<JSON> stored in C<_mapping_content>

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
