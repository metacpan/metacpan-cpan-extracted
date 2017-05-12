# $Id: Signature.pm,v 1.9 2003/08/12 19:53:03 jeremy Exp $
package File::Signature;
use strict;

use vars qw( $VERSION );
$VERSION = sprintf "%d.%03d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/;

use Digest::MD5;

my @FIELDS    = qw( digest ino mode uid gid size mtime pathname );
my @ERRFIELDS = qw( failure pathname errormsg );

my %CONFIG = ( 
    allow_relative_paths => 0,
    stringify_separator  => "\0",
    use_digest_format    => 'hex',
);

sub configure { 
    _throw_exception( "argument required" ) unless @_;
    _throw_exception( "odd argument list (not a hash?)" ) unless 0 == @_ % 2;
    my %options = @_;

    my $i = 0;
    for my $opt ( keys %options ) {
        $CONFIG{ $opt } = $options{ $opt }, $i++ if exists $CONFIG{ $opt };
    } 
    return $i unless wantarray;
    return %CONFIG; 
}



##
# Note:
#     Stringified error objects start with the stringify_separator. That 
#     allows us to support binary digests. Prefixing both is the alternative.
#
use overload '""' => sub { 
    if ( $_[0]->error ) {
        return join $CONFIG{ stringify_separator }, "", "ERROR", $_[0]->error; 
    } else {
        return join $CONFIG{ stringify_separator }, @{ $_[0] }{ @FIELDS };
    }
}; 



sub new_from_string {
    my $class  = shift; 
    my $string = shift; 
    _throw_exception( "argument required" ) unless defined $string;
    _throw_exception( "argument was null" ) unless length  $string;
    my $self = { };

    # For convenience.
    my $sep_regex = qr/\Q$CONFIG{ stringify_separator }\E/;

    if ($string =~ s/^${ sep_regex }ERROR$sep_regex//) {
        my @fields = split /$sep_regex/, $string, scalar( @ERRFIELDS ); 
        _throw_exception( "bad errobj string" ) unless @fields == @ERRFIELDS;
        @{ $self }{ @ERRFIELDS } = @fields;
    } else { 
        my @fields = split /$sep_regex/, $string, scalar( @FIELDS );
        _throw_exception( "bad object string" ) unless @fields == @FIELDS;
        @{ $self }{ @FIELDS } = @fields;
    }
    bless $self, $class;
}


sub new { 
    my $class     = shift; 
    my $pathname  = shift; 

    _throw_exception( "pathname required" ) unless defined $pathname;
    _throw_exception( "pathname was null" ) unless length  $pathname;

    unless ( $CONFIG{ allow_relative_paths } or 0 == index( $pathname, '/' ) ) {
        require File::Spec; 
        $pathname = File::Spec->rel2abs( $pathname );
    }

    my @stat = stat $pathname; 
    return __PACKAGE__->_bad_sig( "stat failure", $pathname, $! ) unless @stat;

    open my $fh, "<", $pathname 
        or return __PACKAGE__->_bad_sig( "open failure", $pathname, $! );
    my $digest = do {
        local $_ = $CONFIG{ use_digest_format };
           /hex/ and Digest::MD5->new->addfile($fh)->hexdigest
        or /b64/ and Digest::MD5->new->addfile($fh)->b64digest 
        or /bin/ and Digest::MD5->new->addfile($fh)->digest
        or           Digest::MD5->new->addfile($fh)->digest;
    };
    close $fh;

    my $self = { }; 
    @{ $self }{ @FIELDS } = ( $digest, @stat[1,2,4,5,7,9], $pathname );

    return bless $self, $class;
}


# This is a private constructor for bad signatures.
sub _bad_sig { 
    my $class    = shift; 
    my ( $failure, $pathname, $error ) = @_; 
    my $self = { 
        failure   => $failure,
        pathname  => $pathname,
        errormsg  => $error, 
    };
    bless $self, $class; 
}


## Both normal signature objects and error objects will have a pathname.
sub pathname { shift->{ pathname } }


##
# The following are reserved accessors. They are unimplemented because 
# I'm still considering their possible value. I believe that providing 
# this information to the user is probably outside this module's scope
# but it may be useful just the same. Out of these, I am most inclined
# to provide the failure() and errormsg() routines. 
sub failure  { _throw_exception( 'unimplemented' ) }
sub errormsg { _throw_exception( 'unimplemented' ) }
sub digest   { _throw_exception( 'unimplemented' ) }
sub ino      { _throw_exception( 'unimplemented' ) }
sub mode     { _throw_exception( 'unimplemented' ) }
sub uid      { _throw_exception( 'unimplemented' ) }
sub gid      { _throw_exception( 'unimplemented' ) }
sub size     { _throw_exception( 'unimplemented' ) } 
sub mtime    { _throw_exception( 'unimplemented' ) }
#
##


sub error { 
    my $self = shift;
    return undef unless exists $self->{ failure };
    if (wantarray) { 
        ( @{ $self }{ @ERRFIELDS } );
    } else {
        my $msg  = __PACKAGE__; 
           $msg .= " ERROR: $self->{ failure } on '$self->{ pathname }'";
           $msg .= " ($self->{ errormsg })" if exists $self->{ errormsg };
        return $msg;
    }
}


# Currently, this sub doesn't make sense it exists to provide functionality
# that will only become necessary if I add an update() method. 
sub was_error { 
    my $self = shift;
    return 1 if exists $self->{ old_sig } and $self->{ old_sig }->error;
    return 0;
}


       
sub old_and_new { 
    my $self  = shift;
    my $field = shift;

    # It doesn't make much sense to compare old and new error.
    _throw_exception( "bad method call " . $self->error ) if ( $self->error );

    return undef unless grep $field, @FIELDS;
    return ( $self->{ old_sig }{ $field }, $self->{ $field } );
}



sub is_same { 
    my $self = shift; 

    # It doesn't make much sense to see if an error has changed. 
    _throw_exception( "bad method call " . $self->error ) if ( $self->error );

    $self->_check_again;
    return "$self" eq "$self->{old_sig}";
}



sub changed { 
    my $self = shift; 

    # It doesn't make much sense to see if an error has changed. 
    _throw_exception( "bad method call " . $self->error ) if ( $self->error );

    $self->_check_again;
    return "$self" ne "$self->{old_sig}" unless wantarray;
     # XXX is string eq good enough here?
    grep { $self->{ $_ } ne $self->{ old_sig }{ $_ } } @FIELDS;
}



## Private instance methods

# This will handle error objects too but it shouldn't get any, right now.
# The functionality is there in case I later decide to add an update() 
# method to just update the signature rather than check it's state. For the
# time being, File::Signature->new($existing_sig->pathname) will have to do.
sub _check_again { 
    my $self = shift; 

    # Duplicate our $self and key the duplicate by "old_sig". 
    $self->{ old_sig } = __PACKAGE__->new_from_string( "$self" );

    # Create a new signature with the same path name. 
    my $newsig         = __PACKAGE__->new( $self->{ pathname } ); 

    # Clean our $self up by removing old fields. 
    delete $self->{ $_ } for grep { $_ ne 'pathname' } @FIELDS, @ERRFIELDS;

    # Copy the new signature into our $self one field at a time. 
    if ( $newsig->error ) { 
        $self->{ $_ } = $newsig->{ $_ } for ( @ERRFIELDS );
    } else {
        $self->{ $_ } = $newsig->{ $_ } for ( @FIELDS ); 
    }
}
 


sub _throw_exception { 
    my $msg = shift; 
    my $subroutine = (caller(1))[3];
    require Carp; 
    Carp::croak( "${subroutine}(): " . $msg );
}




1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

File::Signature - Detect changes to a file's content or attributes.

=head1 SYNOPSIS

  use File::Signature;
  my $sig = File::Signature->new('/some/file');
  
  # If you have a stringified signature stored in $string 
  # you can create a File::Signature object from it.
  my $sig = File::Signature->new_from_string($string);

  if (my $err = $sig->error) { 
      warn $err, "\n";
  }
  # You can use a signature object to re-check the same file.
  if ( $sig->is_same() ) { print "Ok. The signature is the same.\n" }
  if ( $sig->changed() ) { print "Uh Oh! The signature has changed.\n" }

  my @digests = $sig->old_and_new('digest');
  my @inodes  = $sig->old_and_new('ino'); 
  my @modes   = $sig->old_and_new('mode');
  my @uid     = $sig->old_and_new('uid');
  my @gid     = $sig->old_and_new('gid'); 
  my @mtime   = $sig->old_and_new('mtime'); 

  # A slightly more worthwhile use...
  my @fields = $sig->changed(); 
  for my $field (@fields) { 
      printf "$field was: %s but changed to %s.\n", 
                 $sig->old_and_new($field);
  }


=head1 ABSTRACT

This perl library uses perl5 objects to assist in determining whether a file's
contents or attributes have changed. It maintains several pieces of information
about the file: a digest (currently only MD5 is supported), its inode number, 
its mode, the uid of its owner, the gid of its group owner, and its last 
modification time. A File::Signature object is closely associated with a single
pathname. It provides a way to compare the state of a file over different 
points in time; it isn't useful for comparing different files.

=head1 DESCRIPTION

This module provides a way to monitor files for changes. It implements an object
oriented interface to file "signatures." In the case of this module, a 
signature includes an MD5 digest (other digests may be added later), the file's 
size, its inode number, its mode, its owner's uid, its group's gid, and its 
mtime. This information is associated with a file by the file's "pathname." The
pathname is considered to be the file's unique identifier. In reality, a file
may have more than one pathname, but this module doesn't recognize that. It 
will simply treat two differing pathnames as two different files, even if they 
refer to the same file. 

As this module checks whether a file changes over time, a minimal use of it
would include the time when the signature was created and a different
time when the signature is regenerated and compared with the previous one. The
amount of time between these checks is arbitrary. This module makes it 
easy to save a signature object and then load it and check for consistency 
at a later time, whether seconds or years have passed.

=head2 CONSTRUCTORS

=over 4

=item new()

This constructor requires a pathname argument. If one is not provided, it will 
throw an exception (i.e. croak.) If the pathname cannot be stat()'d or if it 
cannot be read, the object returned will hold an error accessible via the 
error() instance method. The pathname should be absolute and, if it isn't it 
well be resolved to an absolute pathname unless the "allow_relative_paths" 
configure option is provided. See L</configure()> below.

=item new_from_string()

This constructor takes a single argument, a previously stringified signature
object, and returns a new signature object created from the string.

=back

=head2 INSTANCE METHODS

=over 4

=item error()

If there was a non-fatal error when the object was constructed or when the last
check was performed, a signature error object is returned instead. This method
determines whether the object is an error object. It returns false if it isn't
and a true value if it is. The true value in that case will be a human readable
error message in scalar context or, in list context, list containing a 
"failure" message, the pathname, and an optional system error message.

=item is_same()

Updates the signature and checks whether it is the same. It returns true if it
is and false if it isn't. It will throw an exception (i.e. croak) if the 
current signature object reports an error. 

=item changed()

Updates the signature and checks whether it is has changed. It returns true if
it has and false if it hasn't. It will throw an exception (i.e. croak) if the 
current signature object reports an error.  

=item old_and_new()

This method requires a fieldname to be passes as a string. It returns a 
two-element list consisting of the previous and current value for the field 
with the supplied fieldname. If the fieldname is not recognized, it will return
undef. This is used primarily to determine what has changed once a change has 
been detected with is_same() or changed(). The currently accepted fieldnames 
are any of qw( digest ino mode uid gid size mtime pathname ). Note that the old
and new pathname fields should always be the same.

=back

=head2 OTHER CLASS METHODS

=over 4

=item configure()

This is used to configure special behavior for all instances. The options are 
passes as hash where the keys are option names and the values are the desired
settings. The following keys are recognized:

=over 4

=item use_digest_format

This key may be either 'bin', 'hex', or 'b64' and will determine whether the 
digest will be stored as a binary string, a string of hexadecimals, or a 
base64 encoded string. The default is 'hex', but that should not be relied upon
as it may change in the future. An unrecognized value will result in a binary 
string representation just as if 'bin' had been the value. If a binary string
is used, the L</stringify_separator> should not be changed from "\0"!

=item allow_relative_paths

A true value for this key will result in relative paths being permitted as the
pathname for signature objects. Usually, when a relative pathname is given in 
a call to the new() constructor, the absolute path is determined. This option
disables that behavior. Changing this option is NOT RECOMMENDED.

=item stringify_separator

This option changes the field separator that is used when a signature object is
stringified. By default this separator is a null ("\0"). It can be changed to 
any string but the string used must never appear in any of the fields. This 
includes the fields of signature error objects which sometimes contain system 
generated error messages. For example, colons and forward slashes are bad 
choices. Changing this option is NOT RECOMMENDED.

=back

=back

=head2 EXCEPTIONS

This is a list of all exceptions that thrown by File::Signature:

=over 4

=item "argument required"

Thrown by configure() and new_from_string() when called with no 
arguments.

=item "odd argument list (not a hash?)"

Thrown by configure() when called with an odd number of arguments. (It is to be
called with a hash.)

=item "argument was null"

Thrown by new_from_string() when called with an empty string.

=item "bad errobj string"

Thrown by new_from_string() when something that looks like a stringified
error object results in the wrong number of fields. 

=item "bad object string"

Thrown by new_from_string() when something that looks like a stringified
signature object results in the wrong number of fields. 

=item "pathname required"

Thrown by new() when called without an argument.

=item "pathname was null"

Thrown by new() when called without a null string as an argument.

=item "bad method call"

Thrown by is_same(), changed(), and old_and_new() when called on an error 
object. 

=back 

=head2 EXPORT

None. 

=head1 CHANGES

 $Log: Signature.pm,v $
 Revision 1.9  2003/08/12 19:53:03  jeremy
 Fixups to tests.

 Revision 1.8  2003/08/11 16:53:41  jeremy
 Fixed bad POD.

 Revision 1.7  2003/06/13 03:58:32  jeremy
 Bug fixes, doc updates, minor changes.

 Revision 1.6  2003/06/12 02:49:37  jeremy
 _throw_exception() fixed. Additional error states handled in 
 constructors.

 Revision 1.5  2003/06/10 22:03:11  jeremy
 POD updates.

 Revision 1.4  2003/06/08 12:59:25  jeremy
 POD changes.

 Revision 1.3  2003/06/08 12:36:24  jeremy
 More minor prepping for RCS.

 Revision 1.2  2003/06/08 12:33:38  jeremy
 Minor touch-ups for RCS prepping.


=head1 SEE ALSO

L<perlfunc/"stat">, L<MD5::Digest>, L<stat(2)>

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

=head1 AUTHOR

Jeremy Madea, E<lt>jdm@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Jeremy Madea. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
