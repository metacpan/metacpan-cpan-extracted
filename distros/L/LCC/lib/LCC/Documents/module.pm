package LCC::Documents::module;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@LCC::Documents::module::ISA = qw(LCC::Documents);
$LCC::Documents::module::VERSION = '0.01';

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

#  IN: 1 class of object
#      2 instantiated LCC object
#      3 instantated object to work with
#      4 method => value pairs to be executed
# OUT: 1 instantiated LCC::Documents::xxx object

sub _new {

# Obtain the class
# Obtain the LCC object
# Obtain the source (a blessed object)

  my $class = shift;
  my $LCC = shift;
  my $source = shift;

# Add error if the source is not an object

  $LCC->_add_error( "$source is not an object" ) unless ref($source);

# Create the object in the right way
# Save the source specification
# Return the object

  my $self = $class->SUPER::_new( $LCC,@_ );
  $self->{'source'} = $source;
  return $self;
} #_new

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 name of method to execute for "next_document"
# OUT: 1 current/old name of method

sub method {

# Obtain the method
# Remove the code ref of the method if we're changing
# Set/return the method name

  my $self = shift;
  delete( $self->{'_method'} ) if @_;
  $self->_variable( 'method',@_ );
} #method

#------------------------------------------------------------------------

#  IN: 1 instantiated object
# OUT: 1 id of the next document
#      2 mtime of the next document
#      3 (optional) length of the next document
#      4 (optional) md5 of the next document
#      5 (optional) mimetype of the next document
#      6 (optional) subtype of the next document

sub next_document {

# Obtain the object
# If we don't have a code ref already
#  Find out the method name to be used
#  Create a code ref to the method needed
# Execute the method and return the result

  my $self = shift;
  unless (exists( $self->{'_method'} )) {
    my $method = $self->{'method'} || 'next_document';
    $self->{'_method'} = \&{$self->{'source'}->$method};
  }
  return $self->{'_method'}->();
} #next_document

#------------------------------------------------------------------------

# The following subroutines deal with standard Perl features

#------------------------------------------------------------------------

__END__

=head1 NAME

LCC::Documents::module - Document information accessible by a Perl module

=head1 SYNOPSIS

 use MyModule;
 $object = MyModule->new;

 use LCC;
 $lcc = LCC->new( | {method => value} );

 $lcc->Documents( $object, | {method => value} ); # figures out it's a module
 $lcc->Documents( 'module',$object, | {method => value} ); # force module

=head1 DESCRIPTION

The Documents object of the Perl support for LCC that should be used when
document information can only be accessed by method of a Perl module.  Do not
create directly, but through the Documents method of the LCC object.

The method is supposed to return the following elements:

 1 id of a document
 2 mtime of that document
 3 (optional) length of that document
 4 (optional) md5 of that document
 5 (optional) mimetype of that document
 6 (optional) subtype of that document

The method should return an empty list when there are no more documents.

By default, the method is called "next_document".  If the method should have
another name, then method L<method> should be called first.

=head1 METHODS

These are the methods specific for this module.  Also see the methods
available in the LCC::Documents module.

=head2 method

 $lcc->Documents( $object, {method => 'next'} );
 
Specify and/or return the name of the method that should be called on the
object to obtain the information about the next document.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://lococa.sourceforge.net, the LCC.pm and the other LCC::xxx modules.

=cut
