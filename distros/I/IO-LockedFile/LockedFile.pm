package IO::LockedFile;

use strict;
use vars qw($VERSION @ISA);

$VERSION = 0.23;

use IO::File;
@ISA = ("IO::File"); # subclass of IO::File

use strict;
use Carp;

# Set default options
my %Options;
_set_option( __PACKAGE__, ( block     => 1,
                            lock      => 1,
                            scheme    => 'Flock',
                            _locked   => 0,
                            _writable => 0 ) );

###########################
# new
###########################
# the constructor
sub new {
    my $proto = shift;          # get the class name
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(); # the object is also file handle

    # Grab our options (if they're there);
    my $options = {};
    $options = shift if ref($_[0]) eq 'HASH';

    if ( exists $options->{ scheme } ) {
        # User-specified scheme (may have to load it)
        $class = join( '::', __PACKAGE__, $options->{ scheme } );
        eval "require $class";
        croak "Unable to load $class: $@" if $@;
    }
    elsif ( $class eq __PACKAGE__ ) {
        # User didn't specify anything (or subclass), so do it for her
        $class .= '::' . get_scheme( $class );
    }

    bless ($self, $class);

    # Store our options
    $self->_set_option( %{ $options } );

    # if receives any parameters, call our open with those parameters
    if (@_) {
	$self->open(@_) or return undef;
    }

    return $self;
} # of new

############################
# open
############################
sub open {
    my $self = shift;

    my $writable = 0;
    if ( scalar(@_) == 1 ) {
        # Perl mode. Look at first character

        # Quick sanity check. We can't lock a pipe
        if (( substr( $_[0],  0, 1 ) eq '|' ) || 
           ( substr( $_[0], -1, 1 ) eq '|' ) ) {
            croak "Cannot lock a pipe"
        }

        # OK, now look at first character
        $writable = substr( $_[0], 0, 1 ) eq '>';
    }
    elsif ( $_[1] =~ /^\d+$/ ) {
        # Numeric mode
        require Fcntl;
        $writable = ( ( $_[1] & O_APPEND ) ||
                      ( $_[1] & O_CREAT  ) ||
                      ( $_[1] & O_TRUNC  ) );
    }
    else {
        # POSIX mode (we know there were enough parameters since our
        # SUPER succeeded).
        $writable = ( $_[1] ne 'r' );
    }

    $self->_set_writable( $writable );
    # call open of the super class (IO::File) with the rest of the parameters
    $self->SUPER::open(@_) or return undef;

    if ( $self->should_lock() ) {
        $self->lock() or return undef;
    }

    return 1;
} # of open

########################
# lock
########################
sub lock {
    my $self = shift;

    $self->_set_locked( 1 );
    return 1;
} # of lock

########################
# unlock
########################
sub unlock {
    my $self = shift;
    $self->_set_locked( 0 );
    return 1;
} # of unlock

########################
# close
########################
sub close {
    my $self = shift;
    # if the file was opened - unlock it
    $self->unlock() if ($self->opened() and $self->have_lock());
    $self->SUPER::close();
} # of close

#######################
# have_lock
#######################
sub have_lock {
    my $self = shift;
    return $self->_get_option( '_locked' );
} # of have_lock

#######################
# _set_locked
#######################
sub _set_locked {
    my ( $self, $value ) = @_;
    return $self->_set_option( '_locked', $value );
} # of _set_locked

#######################
# is_writable
#######################
sub is_writable {
    my $self = shift;
    return $self->_get_option( '_writable' );
} # of is_writable

#######################
# _set_writable
#######################
sub _set_writable {
    my ( $self, $value ) = @_;
    return $self->_set_option( '_writable', $value );
} # of _set_writable

#######################
# should_block
#######################
sub should_block {
    my $self = shift;
    return $self->_get_option( 'block' );
} # of should_block

#######################
# should_lock
#######################
sub should_lock {
    my $self = shift;
    return $self->_get_option( 'lock' );
} # of should_lock

#######################
# print
#######################
sub print {
    my ( $self, @args ) = @_;

    my $was_locked = $self->have_lock();

    if ( ! $was_locked ) {
	return 0 unless $self->lock();
    }
    my $rc = $self->SUPER::print( @args );
    $self->unlock unless $was_locked;

    return $rc;
} # of print

#######################
# truncate
#######################
sub truncate {
    my ( $self, @args ) = @_;

    my $was_locked = $self->have_lock();

    if ( ! $was_locked ) {
	return 0 unless $self->lock();
    }
    my $rc = $self->SUPER::truncate( @args );
    $self->unlock() unless $was_locked;

    return $rc;
} # of truncate

#######################
# get_scheme
#######################
sub get_scheme {
    my $self = shift;

    return _get_option( $self, 'scheme' );
} # of get_scheme
 
#######################
# DESTROY
#######################
sub DESTROY {
    my $self = shift;
    # if the file was opened, close (and unlock) it
    $self->close;
} # of DESTROY

######################
# _get_option
######################
sub _get_option {
    my( $self, $key ) = @_;

    # Is the option set here?
    if ( exists $Options{ $self } && exists $Options{ $self }->{ $key } ) {
        return $Options{ $self }->{ $key }
    }
    # If we're an object, check out class
    elsif ( ref( $self ) ) {
        return _get_option( ref( $self ), $key );
    }
    # If we're a class other than this one, check defaults
    elsif ( $self ne __PACKAGE__ ) {
        return _get_option( __PACKAGE__, $key );
    }
    # It's nowhere. Probably a typo
    else {
        croak "Bad option fetch: $key\n";
    }
} # of _get_option

######################
# _set_option
######################
sub _set_option {
    my( $self, %hash ) = @_;

    while ( my( $key, $value ) = each %hash ) {
        $Options{ $self }->{ $key } = $value;
    }
} # of _set_option

######################
# import
######################
sub import {
    my $pkg = shift;
    my( %config );
    if ( @_ == 1 ) {
	$config{ scheme } = shift;
    }
    else {
	%config = @_;
    }

    my $scheme = $config{ scheme } || $pkg->get_scheme;

    my $class = __PACKAGE__ . "::$scheme";
    eval "require $class";
    croak "Unable to load $class: $@" if $@;

    $class->_set_option( %config );
} # of import

1;
__END__

###########################################################################

=head1 NAME

IO::LockedFile Class - supply object methods for locking files 

=head1 SYNOPSIS

  use IO::LockedFile;

  # create new locked file object. $file will hold a file handle.
  # if the file is already locked, the method will not return until the
  # file is unlocked 
  my $file = new IO::LockedFile(">locked1.txt");

  # when we close the file - it become unlocked.
  $file->close();

  # suppose we did not have the line above, we can also delete the
  # object, and the file is automatically unlocked and closed.
  $file = undef;

=head1 DESCRIPTION

In its simplistic use, the B<IO::LockedFile> class gives us the same 
interface of the B<IO::File> class with the unique difference that the 
files we deal with are locked using the B<Flock> mechanism (using the 
C<flock> function).

If during the running of the process, it crashed - the file will 
be automatically unlocked. Actually - if the B<IO::LockedFile> object goes
out of scope, the file is automatically closed and unlocked.

So, if you are just interested in having locked files with C<flock>, you 
can skip most of the documentation below.

If, on the other hand, you are interested in locking files with other
schemes then B<Flock>, or you want to control the behavior of the locking
(having non blocking lock for example), read on.

Actually the class B<IO::LockedFile> is kind of abstract class.

Why abstract? Because methods of this class call the methods C<lock>
and C<unlock>. But those methods are not really implemented in this class. 
They suppose to be implemented in the derived classes of B<IO::LockedFile>.

Why "kind" of abstract? Because the constructor of this class will return an
object!

How abstract class can create objects? This is done by having the constructor
returning object that is actually an object of one of the derived classes of
B<IO::LockedFile>.

So by default the constructor of B<IO::LockedFile> will return an object of
B<IO::LockedFile::Flock>. For example, the following:

   use IO::LockedFile;
   $lock = new IO::LockedFile(">bla");
   print ref($lock);

Will give:

   IO::LockedFile::Flock

So what are the conclusions here?

First of all - do not be surprised to get object of derived class from the
constructor of B<IO::LockedFile>.

Secondly - by changing the default behavior of the constructor of
B<IO::LockedFile>, we can get object of other class which means that we
have a locked file that is locked with other scheme.

The default behavior of the constructor is determined by the global options.

We can access this global options, or the options per object using the method
C<set_option> and C<get_option>.

We can set the global options in the use line:

  use IO::LockedFile 'Flock'; # set the default scheme to be Flock

  use IO::LockedFile ( scheme => Flock );

We can also set the options of a new object by passing the options to the
constructor, as we will see below. We can change the options of an existing
object by using the C<set_option> method.

Which options are available?

=over 4

=item I<scheme>

The I<scheme> let us define which derived class we use for the object 
we create.
See below which derived classes are available. The default scheme is 'Flock'.

=item I<block>

The I<block> option can be 1 or 0 (true or false). If it is 1, a call to the
C<open> method or to the constructor will be blocked if the file we try to open
is already locked. This means that those methods will not return till the
file is unlocked. If the value of the I<block> option is 0, the C<open> and the
constructor will return immediately in any case. If the file is locked,
those methods will return undef. The default value of the I<block> option is
1.

=item I<lock>

The I<lock> option can be 1 or 0 (true or false). It defines if the file we
open when we create the object will be opened locked. Sometimes, we want
to have a file that can be locked, yet we do not want to open it locked from
the beginning. For example if we want to print into a log file, usually we
want to lock that file only when we print into it. Yet, it might be that
when we open the file in the beginning we do not print into it immediately.
In that case we will prefer to open the file as unlocked, and later we will
lock it when needed. The default value of the I<lock> option is 1.

=back

There might be extra options that are used by one of the derived classes. So
according to the scheme you choose to use, please look in the manual page of
the class that implement that scheme.

Finally, some information that is connected to a certain scheme will be found
in the classes that are derived from this class. For example, compatibility
issues will be discussed in each derived classes. 

The classes that currently implement the interface that B<IO::LockedFile>
defines are:

=over 4

=item *

B<IO::LockedFile::Flock>

=back



=head1 CONSTRUCTOR

=over 4

=item new ( FILENAME [,MODE [,PERMS]] )

Creates an object that belong to one of the derived classes of 
C<IO::LockedFile>. If it receives any parameters, they are passed 
to the method C<open>. if the C<open> fails, the object is destroyed. 
Otherwise, it is returned to the caller. The object will be 
the file handle of that opened file.

=item new ( OPTIONS, FILENAME [,MODE [,PERMS]] )

This version of the constructor is the same as above, with the difference
that we send as the first parameter a reference to a hash - OPTIONS. This
hash let us change for this object only, the options from the default 
options. So for example if we want to change the I<lock> option from its 
default we can do it as follow:
  $file = new IO::LockedFile( { lock => 0 }, 
                              ">locked_later.txt" );

=back

=head1 METHODS

=over 4

=item open ( FILENAME [,MODE [,PERMS]] )

The method let us open the file FILENAME. By default, the file will be 
opened as a locked file, and if the file that is opened is already locked, 
the method will not return until the file is unlocked. Of course this default
behavior can be controlled by setting other options. The object will be 
the file handle of that opened file. The parameters that should be provided 
to this method are the same as the parameters that the method C<open> of  
B<IO::File> accepts. (like ">file.txt" for example). 
Note that the open method checks if the file is opened for reading or for 
writing, and only then calls the lock method of the derived class that is 
being used. This way, for example, when using the B<Flock> scheme, the lock 
will be a shared lock for a file that is being read, and exclusive lock for 
a file that is opened to be write.

=item close ( )

The file will be closed and unlocked. The method returns the same as the 
close method of B<IO::File>.

=item lock ( )

Practically this method does nothing, and returns 1 (true). This method
will be overridden by the derived class that implements the scheme we use. 
When it is overridden, the method suppose to lock the file according to the 
scheme we use. If the file is already locked, and the I<block> option is 1 
(true), the method will not return until the file is unlocked, and 
locked again by the method. If the I<block> option is 0 (false), the 
method will return 0 immediately. Besides, the lock method is aware if 
the file was opened for reading or for writing. Thus, for example, when 
using the B<Flock> scheme, the method will create a shared lock for a file
that is being read, and exclusive lock for a file that is opened to be write.

=item unlock ( )

Practically this method does nothing, and returns 1 (true). This method
will be overridden by the derived class that implements the scheme we use. 
When it is overridden, the method suppose to unlock the file according to the 
scheme we use, and return 1 (true) on success and 0 (false) on failure.

=item have_lock ( )

Will return 1 (true) if the file is already locked by this object. Will return 
0 (false) otherwise. Note that this will not tell us anything about 
the situation of the file itself - thus we should not use this method 
in order to check if the file is locked by someone else. 

=item print ( )

This method is exactly like the C<print> method of B<IO::Handle>, with the 
difference that when using this method, if the file is unlocked, 
then before printing to it, it will be locked and afterward it will 
be unlocked.

=item truncate ( )

This method is exactly like the C<truncate> method of B<IO::Handle>, with the 
difference that when using this method, if the file is unlocked, 
then before truncating it, it will be locked and afterward it will be 
unlocked.

=item is_writable ( )

This method will return 1 (true) if the file was opened to write. 
Will return 0 (false) otherwise.

=item should_block ( )

This method will return 1 (true) if the block option set to 1.  
Will return 0 (false) otherwise.

=item should_lock ( )

This method will return 1 (true) if the lock option set to 1.  
Will return 0 (false) otherwise.

=item get_scheme ( )

This method will return the name of the scheme that is currently used.

=back

=head1 AUTHORS

Rani Pinchuk, rani@cpan.org

Rob Napier, rnapier@employees.org

=head1 COPYRIGHT

Copyright (c) 2001-2002 Ockham Technology N.V. & Rani Pinchuk. 
All rights reserved.  
This package is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=head1 SEE ALSO

L<IO::File(3)>,
L<IO::LockedFile::Flock(3)>

=cut
