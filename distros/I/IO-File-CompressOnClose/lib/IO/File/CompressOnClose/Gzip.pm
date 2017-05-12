#
# $Id: Gzip.pm,v 1.2 2003/12/28 00:15:15 james Exp $
#

=head1 NAME

IO::File::CompressOnClose::Gzip - Gzip compression for
IO::File::CompressOnClose

=head1 SYNOPSIS

 use IO::File::AutoCompress::Gzip;
 my $file = IO::File::CompressOnClose::Gzip->new('>foo');
 print $file "foo bar baz\n";
 $file->close;  # file will be compressed to foo.gz

=cut

package IO::File::CompressOnClose::Gzip;

use strict;
use warnings;

use vars        qw|$VERSION @ISA|;

@ISA          = qw|IO::File::CompressOnClose|;
$VERSION      = $IO::File::CompressOnClose::VERSION;

use Carp        qw|croak|;
use IO::File;
use IO::File::CompressOnClose;
use IO::Zlib;


# compress using gzip
sub compress
{

    my($self, $src_file, $dst_file) = @_;
    
    # tack on a .gz extension
    unless( $dst_file ) {
        $dst_file = "$src_file.gz";
    }
    
    # compress the file
    my($in,$out);
    unless( $in = IO::File->new($src_file, 'r') ) {
        croak("cannot open $src_file for read: $!");
    }
    unless( $out = IO::Zlib->new($dst_file, 'w') ) {
        croak("cannot open $dst_file for write: $!");
    }

    while( <$in> ) {
        print $out $_;
    }

    # close both files
    unless( $in->close ) {
        croak("cannot close $src_file after read: $!");
    }
    unless( $out->close ) {
        croak("cannot close $dst_file after write: $!");
    }
    
}

# keep require happy
1;


__END__

=head1 DESCRIPTION

IO::File::CompressOnClose::Gzip is a subclass of IO::File::CompressOnClose
that compresses a file using IO::Zlib when it is closed.

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
