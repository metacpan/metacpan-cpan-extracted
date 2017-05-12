#
# $Id: Zip.pm,v 1.1 2003/12/28 00:15:15 james Exp $
#

=head1 NAME

IO::File::CompressOnClose::Zip - Zip compression for
IO::File::CompressOnClose

=head1 SYNOPSIS

 use IO::File::AutoCompress::Zip;
 my $file = IO::File::CompressOnClose::Zip->new('>foo');
 print $file "foo bar baz\n";
 $file->close;  # file will be compressed to foo.zip

=cut

package IO::File::CompressOnClose::Zip;

use strict;
use warnings;

use vars                        qw|$VERSION @ISA|;

@ISA                          = qw|IO::File::CompressOnClose|;
$VERSION                      = $IO::File::CompressOnClose::VERSION;

use Archive::Zip                qw|:ERROR_CODES|;
use Carp                        qw|croak|;
use IO::File;   
use IO::File::CompressOnClose;


# compress using zip
sub compress
{

    my($self, $src_file, $dst_file) = @_;
    
    # tack on a .gz extension
    unless( $dst_file ) {
        $dst_file = "$src_file.zip";
    }
    
    # create a new archive
    my $zip = Archive::Zip->new
        or croak("cannot instantiate Archive::Zip object");
    
    # figure out the name of the member in the archive
    my $member_name;
    unless( $member_name = $self->member_filename ) {
        require File::Basename;
        $member_name = File::Basename::basename($src_file);
    }
    
    # add the source file to the archive
    unless( $zip->addFile( $src_file, $member_name ) ) {
        croak("cannot add $src_file to archive");
    }
    
    # write out the archive
    unless( AZ_OK == $zip->writeToFileNamed( $dst_file ) ) {
        croak("cannot write archive $dst_file");
    }
    
}


# accessor methods
sub member_filename
{
    
    my($self, $newval) = @_;
    my $oldval = ${*$self}->{member_filename};
    ${*$self}->{member_filename} = $newval if( @_ > 1 );
    return $oldval;
    
}

# keep require happy
1;


__END__

=head1 DESCRIPTION

IO::File::CompressOnClose::Zip is a subclass of IO::File::CompressOnClose
that creates a zip archive containing a file when that file is closed.

By default, the archive will be named after the source file with the suffix
'.zip'. The archive will contain a single file named after the basename of
the source file.  The name that the file inside the archive is given may be
overriden with the C<< ->member_filename() >> accessor.

=head1 ACCESSORS

In addition to the accessors provided by IO::File::CompressOnClose, an
IO::File::CompressOnClose::Zip object has several get/set accessor methods.
When used to set an attribute, the accessors return the previous value of
the attribute.

=head2 member_filename()

The name that the file in the archive will be given. By default, this is the
basename of the source filename.

=head1 SEE ALSO

L<IO::File::CompressOnClose>

=head1 AUTHOR

James FitzGibbon E<lt>jfitz@CPAN.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, James FitzGibbon.  All Rights Reserved.

This module is free software. You may use it under the same terms as perl
itself.

=cut

#
# EOF
