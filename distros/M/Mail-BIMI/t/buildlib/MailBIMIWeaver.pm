package MailBIMIWeaver;
use Moo;
use Class::Load ':all';
use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Nested;
use Try::Tiny;

use feature qw{ postderef signatures };;
no warnings qw{ experimental::postderef experimental::signatures };

with 'Pod::Weaver::Role::Section';

sub weave_section {
  my($self, $document, $input) = @_;

  my @section_parts;

  # Find the class name we are building for
  my $ppi = $input->{ppi_document};
  return unless ref $ppi eq 'PPI::Document';
  my $node = $ppi->find_first('PPI::Statement::Package');
  my $class_name = $node->namespace if $node;
  return unless $class_name;

  # Load the class and get its meta data
  my $meta;
  try {
    local @INC=('blib',@INC);
    load_class( $class_name );
    $meta = Class::MOP::Class->initialize( $class_name );
  };
  return unless $meta;

  return unless ref $meta;
  return if $meta->isa('Moose::Meta::Role');

  my @attributes = sort $meta->get_attribute_list;
  if( @attributes ) {
    foreach my $attribute (@attributes) {
      next if $attribute =~ /^_/;
      my $moose_attribute = $meta->get_attribute($attribute);
      my $documentation = $moose_attribute->{documentation} // '';
      my $attribute_type = 'attributes';
      $attribute_type = 'options' if $attribute =~ /^OPT_/;
      if ( $documentation =~ s/^inputs: // ) {
        $attribute_type = 'inputs';
      }
      my @attribute_parts;
      my @definition;
      push @definition, 'is='.$moose_attribute->{is} if ( $attribute_type eq 'attributes' || $attribute_type eq 'inputs');
      push @definition, 'required'  if $moose_attribute->{required};
      push @definition, 'cacheable' if $moose_attribute->{is_cacheable};
      push @definition, 'cache_key' if $moose_attribute->{is_cache_key};
      push @attribute_parts, Pod::Elemental::Element::Pod5::Ordinary->new({ content => join(' ',@definition) }) if @definition;
      if ($documentation) {
        push @attribute_parts, Pod::Elemental::Element::Pod5::Ordinary->new({ content => $documentation });
      }
      push @section_parts, {
        attribute_type => $attribute_type,
        element => Pod::Elemental::Element::Nested->new({
          command => 'head2',
          content => $attribute,
          children => \@attribute_parts,
        }),
      };
    }
  }

  @section_parts = sort { $a->{element}->{content} cmp $b->{element}->{content} } @section_parts;

  my $header = {
    options => 'Options may be passed in to the constructor of Mail::BIMI using the OPT_ prefix, or may be set as an Environment variable using the MAIL_BIMI_ prefix in place of OPT_',
    attributes => 'These values are derived from lookups and verifications made based upon the input values, it is however possible to override these with other values should you wish to, for example, validate a record before it is published in DNS, or validate an Indicator which is only available locally',
    inputs => 'These values are used as inputs for lookups and verifications, they are typically set by the caller based on values found in the message being processed',
  };

  foreach my $type ( qw{ inputs attributes options } ) {
    my @relevant_elements = map{ $_->{element} } grep { $_->{attribute_type} eq $type} @section_parts;
    next unless @relevant_elements;
    unshift @relevant_elements, Pod::Elemental::Element::Pod5::Ordinary->new({ content => $header->{$type} }) if $header->{$type};
    push @{$document->children},  Pod::Elemental::Element::Nested->new({
      command => 'head1',
      content => uc $type,
      children => \@relevant_elements,
    });
  }
}

__PACKAGE__->meta->make_immutable;
__END__
