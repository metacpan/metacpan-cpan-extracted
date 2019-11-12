package LCC::Backend;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@LCC::Backend::ISA = qw(LCC);
$LCC::Backend::VERSION = '0.02';

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

#  IN: 1 class of object
#      2 instantiated LCC object
#      3 source specification
#      4 method => value pairs to be executed
# OUT: 1 instantiated LCC::Backend::xxx object

sub _new {

# Obtain the class
# Obtain the LCC object
# Obtain the source (a ref to a database handle, table name list)
# Create the object in the right way

  my $class = shift;
  my $lcc = shift;
  my $source = shift;
  my $self = $class->SUPER::_new( $lcc,@_ );

# Save the source specification
# Return the object

  $self->{'source'} = $source;
  return $self;
} #_new

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 (optional) new value of auto_update flag
# OUT: 1 current/old value of auto_update flag

sub auto_update { shift->_variable( 'auto_update',@_ ) } #auto_update

#------------------------------------------------------------------------

#  IN: 1 instantiated object

sub complete { shift->{'old'} = {} } #complete

#------------------------------------------------------------------------

# The following subroutines deal with standard Perl features

#------------------------------------------------------------------------

#  IN: 1 instantiated object

sub DESTROY { shift->update if $_[0]->auto_update } #DESTROY

#------------------------------------------------------------------------

# The following subroutines are for internal use only

#------------------------------------------------------------------------

# OUT: 1..N names of additional fields that should be saved

sub _additional_fields { qw(fullset) } #_additional_fields

#------------------------------------------------------------------------

#  IN: 1 instantiated object

sub _check_uns_complete {

# Obtain the object
# Make it a complete fetch if so required last time by the UNS

  my $self = shift;
  $self->complete if $self->{'fullset'} || '';
} #_check_uns_complete

#------------------------------------------------------------------------

__END__

=head1 NAME

LCC::Backend - base class for storing local status

=head1 SYNOPSIS

 use LCC;
 $lcc = LCC->new( | {method => value} );

 $lcc->Backend( $source, | {method => value} );         # automatic type check
 $lcc->Backend( 'type', $source, | {method => value} ); # force 'type'

=head1 DESCRIPTION

The Backend object of the Perl support for LCC.  Do not create
directly, but through the Backend method of the LCC object.

=head1 METHODS

These methods are available to the LCC::Backend object.

=head2 auto_update

 $backend->auto_update( 1 );
 $auto_update = $backend->auto_update;

Sets (and/or returns) the flag that indicates whether the backend should
automatically update the status when the object goes out of scope.

By default, an update will only be done when the L<update> method is called
specifically.

=head2 complete

 $backend->complete;

Indicate that the information about the complete set of documents should be
sent to the UNS, ignoring any previously saved status.

Can also be called directly on the LCC object.

=head2 partial

 $backend->partial;
 $backend->partial( 1 );

Indicate that only the information of documents that are deemed to be changed,
should be sent to the UNS.  If however the UNS has indicated that a full set
of information should be sent (as a response during the previous update), then
the update will occur as if L<complete> has been called.

The optional flag indicates to ignore the flag set by the UNS, so that a
partial update will be done even if the UNS has indicated that a full update
should be done.

Can also be called directly on the LCC object.

=head2 update

 $backend->update;

Update the status of the check to the backend.

Can also be called directly on the LCC object.

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
