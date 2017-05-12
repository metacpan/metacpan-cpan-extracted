use strict;
use warnings;

package ElasticSearchX::Model::Generator::TypenameTranslator;
BEGIN {
  $ElasticSearchX::Model::Generator::TypenameTranslator::AUTHORITY = 'cpan:KENTNL';
}
{
  $ElasticSearchX::Model::Generator::TypenameTranslator::VERSION = '0.1.8';
}

# ABSTRACT: Transform upstream type/document names to downstream Package/Class/File names.

use Moo;
use Path::Tiny ();
use Data::Dump qw( pp );
use MooseX::Has::Sugar qw( rw required weak_ref );


has
  'generator_base' => rw,
  required, weak_ref, handles => [qw( attribute_generator document_generator generated_base_class base_dir )];


sub _words {
  my ( $self, $input ) = @_;
  return split /\W+/, $input;
}


sub translate_to_path {
  my ( $self, %args ) = @_;
  my $package = $self->translate_to_package(%args);

  my (@words) = split /::/, $package;
  if ( not @words ) {
    require Carp;
    Carp::confess("Error translating typename to deploy path: $package ");
  }
  my $basename = pop @words;
  if ( not length $basename ) {
    require Carp;
    Carp::confess("\$basename Path part was 0 characters long:  $package");
  }
  $basename .= '.pm';
  return Path::Tiny::path( $self->base_dir )->child( map { ucfirst $_ } @words )->child( ucfirst $basename );
}


sub translate_to_package {
  my ( $self, %args ) = @_;
  return sprintf q{%s::%s}, $self->generated_base_class, join q{}, map { ucfirst $_ } $self->_words( $args{typename} );
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Generator::TypenameTranslator - Transform upstream type/document names to downstream Package/Class/File names.

=head1 VERSION

version 0.1.8

=head1 METHODS

=head2 translate_to_path

  my $path = $instance->translate_to_path( 'file' );
  # ->  /my/base/dir/File.pm

=head2 translate_to_package

  my $package = $instance->translate_to_package('file');
  # -> MyBaseClass::File

=head1 ATTRIBUTES

=head2 generator_base

  rw, required, weak_ref

=head1 PRIVATE METHODS

=head2 _words

  @words = $instance->_words( $string );

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
