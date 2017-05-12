package IO::InSitu;

use version; $VERSION = qv('0.0.2');

use warnings;
use strict;
use Carp;

sub import {
    no strict 'refs';
    *{caller().'::open_rw'} = \&open_rw;
}

sub _make_tmp {
    my ($in_name) = @_;
    return "$in_name.bak";
}

sub open_rw {
    my $opt_arg = ref $_[-1] eq 'HASH' ? pop : {};

    my ($in_name, $out_name) = splice @_, 0, 2;
    $out_name = $in_name if !defined $out_name;

    croak 'Usage: open_rw($in_filename, $opt_out_filename, \%opt_options)'
        if @_ || !defined $out_name;

    my $make_tmp = defined $opt_arg->{tmp} ? $opt_arg->{tmp} : \&_make_tmp;

    croak "Can't open non-existent input file '$in_name'"
        if !( ref $in_name ||  -e $in_name );

    my ($in, $out);

    if (-e $out_name) {
        my ($in_dev,  $in_node)  = stat $in_name;
        my ($out_dev, $out_node) = stat $out_name;

        goto NORMAL_IN if $in_dev != $out_dev || $in_node != $out_node;

        use File::Temp qw( :POSIX );

        my $tmp_name = $make_tmp->($in_name);

        use File::Copy;
        copy($in_name, $tmp_name);

        $in = IO::File::SE->new($tmp_name, '<')
            or croak "Can't open copy of input file '$in_name'";

        goto NORMAL_OUT;
    }

NORMAL_IN:
    open $in, '<', $in_name
        or croak "Can't open input file '$in_name': $!";

NORMAL_OUT:
    open $out, '>', $out_name
        or croak "Can't open output file '$out_name': $!";

    return ($in, $out);
}

package IO::File::SE;
use base qw( IO::File );
use Carp;

my %file_name_of;

sub new {
    my ($class, $name, @otherargs) = @_;
    my $fh = $class->SUPER::new($name, @otherargs);
    $file_name_of{$fh} = $name;
    return $fh;
}

sub DESTROY {
    my ($self) = @_;
    $self->SUPER::DESTROY();
    unlink $file_name_of{$self};
    return;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

IO::InSitu - Avoid clobbering files opened for both input and output


=head1 VERSION

This document describes IO::InSitu version 0.0.1


=head1 SYNOPSIS

    use IO::InSitu;

    my ($in, $out) = open_rw($infile_name, $outfile_name);

    for my $line (<$in>) {
        $line =~ s/foo/bar/g;
        print {$out} $line;
    }

  
=head1 DESCRIPTION

When users want to do in-situ processing on a file, they often specify
it as both the input and output file:

    > myapp -i sample_data -o sample_data -op=normalize

But, if the C<-i> and C<-o> flags are processed independently, the program
will usually open the file for input, open it again for output (at which
point the file will be truncated to zero length), and then attempt to
read in the first line of the now-empty file:

    # Open both filehandles...
    use Fatal qw( open );
    open my $src,  '<', $source_file;
    open my $dest, '>', $destination_file;

    # Read, process, and output data, line-by-line...
    while (my $line = <$src>) {
        print {$dest} transform($line);
    }

Not only does this not perform the requested transformation on the file,
it also destroys the original data. Fortunately, this problem is
extremely easy to avoid: just make sure that you unlink the output file
before you open it:

    # Open both filehandles...
    use Fatal qw( open );
    open my $src,  '<', $source_file;
    unlink $destination_file;
    open my $dest, '>', $destination_file;

    # Read, process, and output data, line-by-line...
    while (my $line = <$src>) {
        print {$dest} transform($line);
    }

If the input and output files are different, unlinking the output file
merely removes a file that was about to be rewritten anyway. Then the
second open simply recreates the output file, ready for writing.

If the two filenames actually refer to a single in-situ file, unlinking
the output filename removes that filename from its directory, but
doesn't remove the file itself from the filesystem. The file is already
open through the filehandle in $input, so the filesystem will preserve
the unlinked file until that input filehandle is closed. The second open
then creates a new version of the in-situ file, ready for writing.

The only limitation of this technique is that it changes the inode of
any in-situ file . That can be a problem if the file has any hard-linked
aliases, or if other applications are identifying the file by its inode
number. If either of those situations is possible, you can preserve the
in-situ file's inode by using the C<open_rw()> subroutine that is
exported from this module:

    # Open both filehandles...
    use IO::InSitu;
    my ($src, $dest) = open_rw($source_file, $destination_file);

    # Read, process, and output data, line-by-line...
    while (my $line = <$src>) {
        print {$dest} transform($line);
    }

=head1 INTERFACE

=over

=item C<($in_fh, $out_fh) = open_rw($infile_name, $outfile_name, \%options)>

=item C<($in_fh, $out_fh) = open_rw($in_out_file_name, \%options)>

The C<open_rw()> subroutine takes the names of two files: one to be
opened for reading, the other for writing. If you only give it a single
filename, it opens that file for both reading and writing.

It returns a list of two filehandles, opened to those two files.
However, if the filename(s) refer to the same file, C<open_rw()> first
makes a temporary copy of the file, which it opens for input. It then
opens the original file for output. In such cases, when the input
filehandle is eventually closed, IO::InSitu arranges for the temporary
file to be automatically deleted.

This approach preserves the original file's inode, but at the cost of
making a temporary copy of the file. The name of the temporary is
usually formed by appending '.bak' to the original filename, but this
can be altered, by passing the C<'tmp'> option to C<open_rw()>:

    my ($src, $dest) = open_rw($source, $destination, {tmp=>\&temp_namer});

The C<'tmp'> option expects to be passed a reference to a subroutine. That
subroutine will be called and passed the name of the input file. It is
expected to return the name of the back-up file. For example:

    sub tmp_namer {
        my ($input_file) = @_;

        return "$input_file.orig";
    }

=back

=head1 DIAGNOSTICS

=over

=item C<< Usage: open_rw( $in_filename, $out_filename, \%options ) >>

You called C<open_rw()> with less than two arguments, or more than three.
Pass the function two filenames, and (optionally) a reference to any options.


=item C<< Can't open non-existent input file '%s' >>

You specified an input file that does not exist on the filesystem.
Usually caused by a misspelling, or an incorrect file path.


=item C<< Can't open input file '%s' >>

You specified an input file that exists on the filesystem but could not
be opened for reading.  Usually caused by insufficient file permissions.


=item C<< Can't open copy of input file '%s' >>

The module was unable to create (or access) its back-up copy of the
input file. This is usually caused by insufficient file permissions on
the directory where the back-up is supposed to be written.


=item C<< Can't open output file '%s' >>

You specified an output file that could not be opened for writing.
This usually means the directory into which the output file was to be placed
is non-existent or you don't have write permission to the directory or the
output file.

=back


=head1 CONFIGURATION AND ENVIRONMENT

IO::InSitu requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-io-insitu@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
