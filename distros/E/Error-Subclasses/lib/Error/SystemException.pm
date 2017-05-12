#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2006,2009 -- leonerd@leonerd.org.uk

package Error::SystemException;

use strict;
use warnings;

use base qw( Error );

our $VERSION = '0.05';

=head1 NAME

C<Error::SystemException> - an L<Error> subclass to represent OS-thrown
errors.

=head1 DESCRIPTION

This exception is used to indicate errors returned by the operating system, or
underlying libraries. As well as a string error message, it also contains the
string form of C<$!> at the time the exception was thrown.

=cut

=head1 FUNCTIONS

=cut

=head2 $e = Error::SystemException->new( $message )

This function constructs a new exception object and returns it. Normally this
function should not be necessary from most code, as it would be constructed
during the C<< Error->throw() >> method.

 throw Error::SystemException( "Something went wrong" );

The value of C<$message> is passed as the C<-text> key to the superclass
constructor, and the numerical value of C<$!> at the time the exception object
is built is passed as the C<-value> key. The string value of C<$!> is also
stored in the object.

=cut

sub new
{
    my $class = shift;
    my $perror = "$!";
    my $errno = $!+0;

    my ( $message ) = @_;

    local $Error::Depth = $Error::Depth + 1;

    my $self = $class->SUPER::new( -text => $message, -value => $errno );

    $self->{perror} = $perror;

    $self;
}

=head2 $str = $self->perror

This function returns the stored string value of Perl's C<$!> variable at the
time the exception object was created.

=cut

sub perror
{
    my $self = shift;
    return $self->{perror};
}

sub stringify
{
    my $self = shift;
    return $self->SUPER::stringify() . " - " . $self->perror;
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 EXAMPLES

Typically, this exception class would be used following the failure of a
system call.

 mkdir( $dir ) or throw Error::SystemException( "Cannot mkdir( '$dir' )" );

If caught, this exception would print a message perhaps looking like

 Cannot mkdir( '/root/testdir' ) - Permission denied

Because it is a subclass of C<Error>, the usual try/catch mechanisms also
apply to it.

 try {
     mkdir( $dir ) 
         or throw Error::SystemException( "mkdir($dir)" );

     try {
         chmod( $mode, $dir )
             or throw Error::SystemException( "chmod($dir)" );
         chown( $uid, $gid, $dir )
             or throw Error::SystemException( "chown($dir)" );
     }
     catch Error with {
         my $e = shift;
         rmdir( $dir );
         $e->throw;
     };
 }
 catch Error with {
     my $e = shift;
     # handle $e here...
 };

=head1 SEE ALSO

=over 4

=item *

L<Error> - Base module for exception-based error handling

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
