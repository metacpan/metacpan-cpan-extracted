#
# $Id: CompressOnClose.pm,v 1.3 2003/12/28 15:29:05 james Exp $
#

=head1 NAME

IO::File::CompressOnClose - compress a file when done writing to it

=head1 SYNOPSIS

 use IO::File::CompressOnClose;
 my $io = IO::File::CompressOnClose->new('>foo');
 print $io "foo bar baz\n";
 $io->close;  # file will be compressed to foo.gz on unix or
              # foo.zip on Windows

To change compression schema to a class (which is expected to have
a C<< ->compress() >> class method):

 $io->compressor('Foo::Bar');

To change compression scheme to an arbitrary coderef:

 $io->compressor(\&coderef);

=cut

package IO::File::CompressOnClose;

use strict;
use warnings;

use vars        qw|@ISA $VERSION|;

@ISA          = qw|IO::File|;
$VERSION      = '0.11';

use Carp        qw|croak|;
use IO::File;

# default compression format by platform
my %platform_to_compressor = (
    dos     => 'IO::File::CompressOnClose::Zip',
    MSWin32 => 'IO::File::CompressOnClose::Zip',
    '*'     => 'IO::File::CompressOnClose::Gzip',
);

# open the file
sub open
{

    my $self = shift;
    my($file) = @_;

    # if we are the base class, set our compressor per our platform
    # otherwise compressing using whatever class we are
    if( ref $self eq __PACKAGE__ ) {
        $self->compressor( $platform_to_compressor{$^O} ||
                           $platform_to_compressor{'*'} );
    }
    else {
        $self->compressor( ref $self );
    }
    
    # default to removing the original file after compression
    $self->delete_after_compress(1);

    # figure out if the file was opened for write
    # (borrowed from IO::File::open)
    if( @_ > 1 ) {
        my $mode = $_[1];
        if( $mode =~ m/^\d+$/ ) {
            # we don't deal with numeric modes yet
            croak("numeric modes not supported by IO::File::CompressOnClose");
        }
        elsif( $mode =~ m/:/ ) {
            # nor do we deal with IO layers
            croak("io layers not supported by IO::File::CompressOnClose");
        }
        unless( IO::Handle::_open_mode_string($mode) =~ m/>/ ) {
            return $self->SUPER::open(@_);
        }
        $self->compress_on_close(1);
    }
    else {
        if( $file =~ m/>/ ) {
            $self->compress_on_close(1);
        }
    }
    
    # remove redirection characters from the filename
    $file =~ s/[<>]+//;

    # get the absolute path to the file
    if (! File::Spec->file_name_is_absolute($file)) {
        $file = File::Spec->rel2abs(File::Spec->curdir(),$file);
    }
    $self->filename( $file );
    
    # get our parent class to do the real open
    my $rc = $self->SUPER::open(@_);
    
    # if the file doesn't exist then we probably were given
    # something esoteric like >&1
    unless( -f $file ) {
        $self->compress_on_close(0);
        croak("'$file' does not exist after open");
    }
    
    return $rc;
    
}

# set the default compression scheme
sub _set_compressor
{
    
    my $self = shift;
    
    # set the compressor based upon our class
    $self->compressor( $platform_to_compressor{$^O} ||
                       $platform_to_compressor{'*'} );

    return $self;                       
                       
}

# close and compress the file
sub close
{

    my $self = shift;

    # dispatch to our parent class to do the real close
    $self->SUPER::close(@_);

    # skip out if we've already been invoked
    return 1 if( $self->compressed );
    
    # skip out if we aren't supposed to compress
    return 1 unless( $self->compress_on_close );
    
    # make sure we have a valid compression class or func
    my $compressor = $self->compressor;
    if( ref $compressor eq 'CODE' ) {
        $compressor->($self->filename, $self->compress_to)
            && $self->compressed(1);
    }
    else {
        # load the compression class if it isn't already
        unless( UNIVERSAL::isa($compressor, 'UNIVERSAL') ) {
            eval "require $compressor";
            if( $@ ) {
                croak("could not load compression class $compressor: $@");
            }
        }
        # make sure it is a subclass
        unless( UNIVERSAL::isa($compressor, __PACKAGE__) ) {
            croak("$compressor is not a subclass of " . __PACKAGE__);
        }
        # make sure it can compress
        unless( UNIVERSAL::can($compressor, 'compress') ) {
            croak("$compressor cannot 'compress'");
        }
        # re-bless ourselves into the subclass
        bless $self, $compressor;
        
        # dispatch to the compress method
        $self->compress($self->filename, $self->compress_to)
            && $self->compressed(1);
    }
    
    # unlink the original file
    if( $self->delete_after_compress ) {
        unless( unlink($self->filename) ) {
            croak("cannot unlink ", $self->filename, " after compress: $!");
        }
    }
    
    return 1;

}


# make sure that our close is called on object destruction
sub DESTROY
{
    
    my $self = shift;
    if( $self->opened ) { $self->close }

}


# accessor methods
sub filename
{
    
    my($self, $newval) = @_;
    my $oldval = ${*$self}->{filename};
    ${*$self}->{filename} = $newval if( @_ > 1 );
    return $oldval;
    
}

sub compress_to
{
    
    my($self, $newval) = @_;
    my $oldval = ${*$self}->{compress_to};
    ${*$self}->{compress_to} = $newval if( @_ > 1 );
    return $oldval;
    
}

sub compressor
{
    
    my($self, $newval) = @_;
    my $oldval = ${*$self}->{compressor};
    ${*$self}->{compressor} = $newval if( @_ > 1 );
    return $oldval; 
    
}

sub compress_on_close
{
    
    my($self, $newval) = @_;
    my $oldval = ${*$self}->{compress_on_close} ? 1 : 0;
    if( @_ > 1 ) {
        ${*$self}->{compress_on_close} = $newval ? 1 : 0;
    }
    return $oldval;
    
}

sub delete_after_compress
{
    
    my($self, $newval) = @_;
    my $oldval = ${*$self}->{delete_after_compress} ? 1 : 0;
    if( @_ > 1 ) {
        ${*$self}->{delete_after_compress} = $newval ? 1 : 0;
    }
    return $oldval;
    
}

sub compressed
{
    
    my($self, $newval) = @_;
    my $oldval = ${*$self}->{compressed} ? 1 : 0;
    if( @_ > 1 ) {
        ${*$self}->{compressed} = $newval ? 1 : 0;
    }
    return $oldval;
    
}

# keep require happy
1;


__END__

=head1 DESCRIPTION

To conserve disk space, it can be helpful to compress files that your
program creates as soon as possible. The IO::Zlib module is a great way to
do this, but it suffers from one (unavoidable) drawback: the files are
only accessible as compressed files.

What IO::File::CompressOnClose provides is an IO::File compatible way to
have the files created by your program written out as plain text files but
compressed when they are closed. This allows you to tail a file using a
vanilla 'tail -f' without having to worry about manually compressing the
file when direct access to it is no longer necessary.

You open a file using IO::File::CompressOnClose in much the same was as you
would open a file using IO::File (with one caveat; see below). If you
construct an object of class IO::File::CompressOnClose then the compression
scheme will be chosen based upon your platform (Zip for DOS/Windows and Gzip
for any other platform).

If you prefer to choose the specific compression scheme ahead of time you
can instantiate an object of a subclass of IO::File::CompressOnClose. The
Zip and Gzip subclasses are part of this distribution; other compression
schemes may be supported in the future.

When compression takes places, the original file is deleted; you can disable
this behaviour by setting the B<delete_after_compress> attribute.

=head1 FILE NAMES

After the file is opened using IO::File, a test is made to see if the file
exists.  If this test fails, an exception is thrown.  This is a crude but
hopefully effective way to prevent using esoteric filenames (C<< +> >> or
C<< >&2 >>) or piped opens (C<< |/bin/date >>).

=head1 FILE MODES

At present, IO::File::CompressOnClose is not terribly clever about file
modes. It can only handle file modes of the form C<< ">file" >> or C<<
"file", "w" >>. Attempts to use numeric modes or IO layers will throw an
exception.

Supporting these other modes may be considered for future versions of this
module depending on user interest.

=head1 ACCESSORS

An IO::File::CompressOnClose object has several get/set accessor methods.
When used to set an attribute, the accessors return the previous value of
the attribute.

=head2 filename()

The absolute filename that will be compressed upon close. It would be unwise
to change this unless you know what you are doing.

=head2 compress_to()

The absolute filename that the compressed file will take. If this is set
prior to the file being closed then the specific name will be used.
Otherwise the name will be generated by the compression class or subroutine.

If all you wish to do is override the default compression suffix (say to use
F<.gzip> instead of F<.gz>) then you should be careful to add the suffix to
the absolute source file path using the C<< ->filename() >> accessor:

 $io->compress_to( $io->filename . '.gzip' );

=head2 compressor()

The class to be used for compression, or a coderef that will perform the
same task.  This attribute will be set when the file is first opened, and
may be modified thereafter.

For details on the calling syntax of the class or coderef, see
L<"SUBCLASSING"> and L<"USING AN ANONYMOUS SUBROUTINE TO COMPRESS"> below.

=head2 compress_on_close()

This accessor will return 1 or 0 to indicate whether the file will be
compressed on close. For files opened for write or append, this will be 1.
For files opened for read, this will be 0.

If a file is opened for write but subsequent events dictate that the file
not be compressed on close, this method may be used to change the attribute
prior to closing the file.

=head2 delete_after_compress()

This accessor will return 1 or 0 to indicate whether the original file will
be deleted after being compressed.

=head2 compressed()

This accessor will return 1 or 0 to indicate whether the file has been
compressed or not.

=head1 SUBCLASSING

To support a new compression scheme, follow the layout of one of the
existing subclasses (Zip or Gzip).

Your class must meet these requirements:

=over 4

=item * it must be loadable (duh)

=item * it must be a subclass of IO::File::CompressOnClose.

=item * it must have a B<compress> method.

=back

When the class is successfully loaded, the IO::File::CompressOnClose object
will be re-blessed into the new class.  The B<compress> method will then be
invoked on the object with two parameters: the source file name and the
destination file name. If the destination file name is undefined, the method
should choose a suitable default.

=head1 USING AN ANONYMOUS SUBROUTINE TO COMPRESS

As an alternative to using a dedicated class for compression, an anonymous
subroutine (aka CODEREF) may be used. In this case the calling syntax
differs slightly: only the source and destination file names will be passed.
The destination file naming rules apply as described for subclassing.

=head1 TODO

=over 4

=item * support numeric file modes and IO layers in open method

=item * support other compression schemes (LZH, Bzip2, etc.)

=back

=head1 BUGS

There are probably some lurking. I'm not entirely sure what would happen if
you try to use one of Perl's more esoteric file opening styles such as C<<
"+>" >>.

Pipes are also probably bad news.

=head1 AUTHOR

James FitzGibbon E<lt>jfitz@CPAN.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, James FitzGibbon.  All Rights Reserved.

This module is free software. You may use it under the same terms as perl
itself.

=cut

#
# EOF
