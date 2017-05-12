package Froody::Walker::Driver;

use base 'Class::Accessor::Chained::Fast';

use strict;
use warnings;

__PACKAGE__->mk_accessors(qw/walker spec/);

=head2 SUBCLASS METHODS

When writing a walker subclass, override these methods to define your
behaviour.

=over

=item init_source( source )

Should return a new, black source data structure that will be used as the source 
for the given xpath. 

=item init_target( xpath, parent )

Should return a new, blank target data structure that will be used to store data 
for the given xpath. The parent DS is passed in, in case it will depend on it in 
some way (for instance, XML::LibXML documents should be created from the same 
XML::LibXML::Document object).

=item validate_source( source, xpath )

Should return true is the source data structure, assumed to represent the source 
at the given xpath location, validates against the local spec.

=item read_text( source, xpath )

This method should return the text content of the node in 'source', which is in 
the original document at the given xpath location.

=item read_attribute( source, xpath, name )

This method should return the value of the named attribute from source, which is 
in the original source document at the given location.

=item child_sources( source, xpath, child name )

This method should return a list of new source data source elements
under source with the given child element name.

=item write_text( target, xpath, value )

This should insert a text value into 'target', which is in the
target document with the given path.

It must return the new target object (you can modify or replace it,
but you must return the result).

=item write_attribute( target, xpath, name, value )

This should set the attribute on the given target to the given value.

It must return the new target object (you can modify or replace it,
but you must return the result).

=item add_child_to_target( target, xpath, child name, child )

Should add the new child object, 'child', to 'target' with the
element name 'child name'.

It must return the new target object (you can modify or replace it,
but you must return the result).

=item spec_for_xpath( xpath )

Returns the specification for a given xpath.

=cut

sub spec_for_xpath {
  my ($self, $xpath) = @_;
  my $global_spec = $self->walker->spec;
  my $spec = $global_spec->{$xpath} if $global_spec && $xpath;
  return $spec;

}

=back

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>, L<Froody::Walker>

=cut

1;

__END__
__CODE__

# these are template implementations of the methods required

sub init_source {
  my ($self, $source) = @_;
  
  return $source;
}

sub init_target {
  my ($self, $xpath, $parent) = @_;
  return undef;
}


sub validate_source {
  my ($self, $source, $path) = @_;
  return 1;
}

sub read_text {
  my ($self, $source, $xpath_key) = @_;
  return undef;
}

sub read_attribute {
  my ($self, $source, $path, $attr) = @_;
  return undef;
}

sub child_sources {
  my ($self, $source, $xpath, $element) = @_;
  return ();
}

sub write_text {
  my ($self, $target, $xpath_key, $value) = @_;
  return $target;
}

sub write_attribute {
  my ($self, $target, $path, $attr, $value) = @_;
  return $target;
}

sub add_child_to_target {
  my ($self, $target, $xpath, $element, $child) = @_;
  return $target;
}

