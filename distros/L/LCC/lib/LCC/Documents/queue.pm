package LCC::Documents::queue;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@LCC::Documents::queue::ISA = qw(LCC::Documents);
$LCC::Documents::queue::VERSION = '0.03';

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

#  IN: 1 class of object
#      2 instantiated LCC object
#      3 threads::shared::queue object
#      4 method => value pairs to be executed
# OUT: 1 instantiated LCC::Documents::xxx object

sub _new {

# Obtain the class
# Obtain the LCC object
# Obtain the source (a ref to a database handle, table name list)

  my $class = shift;
  my $LCC = shift;
  my $source = shift;

# Add error if the source is not a queue object

  $LCC->_add_error( "$source is not a queue object" )
   unless ref($source) eq 'threads::shared::queue';

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
# OUT: 1 id of the next document
#      2 mtime of the next document
#      3 (optional) length of the next document
#      4 (optional) md5 of the next document
#      5 (optional) mimetype of the next document
#      6 (optional) subtype of the next document

sub next_document { @{shift->{'source'}->dequeue} } #next_document

#------------------------------------------------------------------------

# The following subroutines deal with standard Perl features

#------------------------------------------------------------------------

__END__

=head1 NAME

LCC::Documents::queue - Documents accessible by a queue

=head1 SYNOPSIS

 use threads;
 use threads::shared;
 use threads::shared::queue;

 my $queue = threads::shared::queue->new( sub {} );

 use LCC;
 $lcc = LCC->new( $queue, | {method => value} );
 $lcc->Documents( 'queue', $queue, | {method => value} );

=head1 DESCRIPTION

The Documents object of the Perl support for LCC that should be used when
update information for documents can be obtained by a Perl 5.8.X and higher
queue (threads::shared::queue).  Do not create directly, but through the
Documents method of the LCC object.

The queue is supposed to contain references to a list with the following
elements:

 1 id of the next document
 2 mtime of the next document
 3 (optional) length of the next document
 4 (optional) md5 of the next document
 5 (optional) mimetype of the next document
 6 (optional) subtype of the next document

The queue should be terminated by an undefined value.

=head1 METHODS

There are no specific methods in this module.  Also see the methods available
in the LCC::Documents module.

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
