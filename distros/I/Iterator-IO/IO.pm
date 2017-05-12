=for gpg
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

=head1 NAME

Iterator::IO - Filesystem and stream iterators.

=head1 VERSION

This documentation describes version 0.02 of Iterator::IO.pm, August 23, 2005.

=cut

use strict;
use warnings;
package Iterator::IO;
our $VERSION = '0.02';

use base 'Exporter';
use vars qw/@EXPORT @EXPORT_OK %EXPORT_TAGS/;

@EXPORT      = qw(idir_listing idir_walk ifile ifile_reverse);
@EXPORT_OK   = @EXPORT;

use Iterator;

# Function name: idir_listing
# Synopsis:      $iter = idir_listing ($path)
# Description:   Returns the full file names in the specified directory.
# Created:       07/28/2005 by EJR
# Parameters:    $path - Directory.  If omitted, uses current dir.
# Returns:       Iterator
# Exceptions:    Iterator::X::Am_Now_Exhausted
sub idir_listing
{
    require IO::Dir;
    require Cwd;

    my $path = shift || Cwd::getcwd();
    $path =~ s|/ \z||x;   # remove any trailing slash
    my $d = new IO::Dir $path;
    Iterator::X::IO_Error (message => qq{Cannot read "$path": $!},
                           error => $!)
        unless $d;

    return Iterator->new (sub
    {
        # Get next file, skipping . and ..
        my $next;
        while (1)
        {
            $next = $d->read;

            if (! defined $next)
            {
                undef $d;   # allow garbage collection
                Iterator::is_done();
            }

            last  if $next ne '.'  &&  $next ne '..';
        }

        # Return the filename
        return "$path/$next";
    });
}


# Function name: idir_walk
# Synopsis:      $iter = idir_walk ($path)
# Description:   Returns the directory tree below a given dir.
# Created:       07/28/2005 by EJR
# Parameters:    $path - Directory.  If omitted, uses current dir.
# Returns:       Iterator
# Exceptions:    Iterator::X::Am_Now_Exhausted
sub idir_walk
{
    my @dir_queue;
    my $path = shift;
    my $files = idir_listing($path);

    return Iterator->new (sub
    {
        # If no more files in current directory,
        # get next directory off the queue
        while ($files->is_exhausted)
        {
            # Nothing else on the queue?  Then we're done.
            if (@dir_queue == 0)
            {
                undef $files;    # allow garbage collection
                Iterator::is_done();
            }

            # Create an iterator to return the files in that directory
            $files = idir_listing(shift @dir_queue);
        }

        # Get next file in current directory
        my $next = $files->value;

        # If this is a directory (and not a symlink), remember it for later recursion
        if (-d $next  &&  !-l $next)
        {
            unshift @dir_queue, $next;
        }

        return $next;
    });
}

# Function name: ifile
# Synopsis:      $iter = ifile ($filename, {options});
# Description:   Returns the lines of a file, one at a time.
# Created:       07/28/2005 by EJR
# Parameters:    $filename - File name to open.
#                \%options - hashref of options
# Returns:       Iterator
# Exceptions:    Iterator::X::Parameter_Error
#                Iterator::X::IO_Error
#                Iterator::X::Am_Now_Exhausted
sub ifile
{
    require IO::File;

    my $filename  = shift;

    # Options
    my ($autochomp, $sep_defined, $separator);
    $autochomp = 1;    # default

    ################################################################
    # Backwards-compatibility block.
    # THIS WILL GO AWAY!
    #
    # This parses the old 'chomp' and 'nochomp' and 'sep' arguments.
    if (@_)
    {
        if ($_[0] eq 'chomp'  ||  $_[0] eq 'nochomp'  ||  !defined($_[0]))
        {
            my $chomp_opt = shift;
            if (defined $chomp_opt)
            {
                Iterator::X::Parameter_Error->throw(q{Invalid "chomp" argument to ifile})
                    if ($chomp_opt ne 'chomp'  &&  $chomp_opt ne 'nochomp');

                $autochomp = $chomp_opt eq 'chomp';
            }

            # Separator argument
            if (@_)
            {
                $sep_defined = 1;
                $separator   = shift;
            }
        }
    }
    ################################################################

    if (@_)
    {
        Iterator::X::Parameter_Error->throw
            (q{Second argument to ifile must be a hashref})
            if ref $_[0] ne 'HASH';

        Option: while (my ($opt,$val) = each %{$_[0]})
        {
            my $lcopt = lc $opt;   # because we're friendly.

            if ($lcopt eq 'chomp')
            {
                $autochomp = $val;
                next Option;
            }
            if ($lcopt eq 'rs'  ||  $lcopt eq '$/'  ||  $lcopt eq 'input_record_separator')
            {
                $separator   = $val;
                $sep_defined = 1;
                next Option;
            }
            Iterator::X::OptionError->throw
                (message => qq{Unknown option: "$opt" in call to ifile},
                 name    => $opt);
        }
    }

    # Open the file handle.
    my $fh = new IO::File ($filename);
    Iterator::X::IO_Error (message => qq{Cannot read "$filename": $!},
                           error => $!)
        unless $fh;

    return Iterator->new (sub
    {
        my $line;

        # Get next line (delimited by $separator if such is defined);
        {
            local $/ = $sep_defined? $separator : $/;
            $line = $fh->getline();
            chomp $line  if defined $line  &&  $autochomp;
        }

        # Done?
        if (!defined $line)
        {
            $fh->close;
            undef $fh;
            Iterator::is_done();
        }

        # Return the line
        return $line;
    });
}

# Function name: ifile_reverse
# Synopsis:      $iter = ifile_reverse ($filename, {options})
# Description:   Returns the lines of a file, in reverse order
# Created:       07/28/2005 by EJR
# Parameters:    $filename - File name to open.
#                \%options - options: chomp => bool, $/ => string
# Returns:       Iterator
# Exceptions:    Iterator::X::Parameter_Error
#                Iterator::X::IO_Error
#                Iterator::X::Am_Now_Exhausted
sub ifile_reverse
{
    require IO::File;

    my $filename  = shift;

    # Options
    my ($autochomp, $sep_defined, $separator);
    $autochomp = 1;    # default

    ################################################################
    # Backwards-compatibility block.
    # THIS WILL GO AWAY!
    #
    # This parses the old 'chomp' and 'nochomp' and 'sep' arguments.
    if (@_)
    {
        if ($_[0] eq 'chomp'  ||  $_[0] eq 'nochomp'  ||  !defined($_[0]))
        {
            my $chomp_opt = shift;
            if (defined $chomp_opt)
            {
                Iterator::X::Parameter_Error->throw(q{Invalid "chomp" argument to ifile})
                    if ($chomp_opt ne 'chomp'  &&  $chomp_opt ne 'nochomp');

                $autochomp = $chomp_opt eq 'chomp';
            }

            # Separator argument
            if (@_)
            {
                $sep_defined = 1;
                $separator   = shift;
            }
        }
    }
    ################################################################

    if (@_)
    {
        Iterator::X::Parameter_Error->throw
            (q{Second argument to ifile_reverse must be a hashref})
            if ref $_[0] ne 'HASH';

        Option: while (my ($opt,$val) = each %{$_[0]})
        {
            my $lcopt = lc $opt;   # because we're friendly.

            if ($lcopt eq 'chomp')
            {
                $autochomp = $val;
                next Option;
            }
            if ($lcopt eq 'rs'  ||  $lcopt eq '$/'  ||  $lcopt eq 'input_record_separator')
            {
                $separator   = $val;
                $sep_defined = 1;
                next Option;
            }
            Iterator::X::OptionError->throw
                (message => qq{Unknown option: "$opt" in call to ifile},
                 name    => $opt);
        }
    }

    # Must read chunks of the end of the file into memory
    my $block_size   = 8192;   # somewhat arbitrary

    my $fh = IO::File->new ($filename)
        or Iterator::X::IO_Error (message => qq{Cannot read "$filename": $!},
                                  error => $!);

    # Buffer variables
    my $leftover;
    my @lines;

    # Are we at the start of the file?
    my $at_start = sub {$fh->tell == 0};

    my $break = sub
    {
        my $block = shift;
        $block .= $leftover if defined $leftover;

        # Split up the block
        my $sep = $sep_defined? $separator : $/;
        @lines = reverse split /(?<=\Q$sep\E)/, $block;
        $leftover = pop @lines;
    };

    my $prev_block = sub
    {
        my $pos = $fh->tell;
        my $bytes = 1 + ($pos-1) % $block_size;
        my $buf;

        my $seek_ok = seek $fh, -$bytes, 1;
        Iterator::X::IO_Error->throw
                (message => qq{Seek error on $filename: $!},
                 os_error => $!)
            unless $seek_ok;

        my $num_read = read $fh, $buf, $bytes;
        Iterator::X::IO_Error->throw
                (message => qq{Read error on $filename: $!},
                 os_error => $!)
            if ! defined $num_read;

        seek $fh, -$bytes, 1;
        Iterator::X::IO_Error->throw
                (message => qq{Seek error on $filename: $!},
                 os_error => $!)
            unless $seek_ok;

        return $buf;
    };

    seek $fh, 0, 2;    # end of file
    $break->( $prev_block->() );

    return Iterator->new (sub
    {
        if (@lines == 0)
        {
            if ($at_start->())
            {
                @lines = $leftover;
                undef $leftover;
            }
            else
            {
                $break->( $prev_block->() );
            }
        }

        # Return the line (chomped if so requested)
        my $line = shift @lines;

        # Exhausted?
        Iterator::is_done()
            if ! defined $line;

        my $sep = $sep_defined? $separator : $/;
        $line =~ s/\Q$sep\E$//  if $autochomp;
        return $line;
    });
}


1;
__END__

=head1 SYNOPSIS

 use Iterator::IO;

 # Return the names of files in a directory (except . and ..)
 $iter = idir_listing ($path);

 # Return all the files in a directory tree, one at a time.
 # Like File::Find, in slow motion.
 $iter = idir_walk ($path);

 # Return the lines of a file, one at a time.
 $iter = ifile ($filename, \%options);

 # Return the lines of a file, in reverse order
 $iter = ifile_reverse ($filename, \%options);

=head1 DESCRIPTION

This module provides filesystem and stream iterator functions.  See
the L<Iterator> module for more information about how to use
iterators.

=head1 FUNCTIONS

=over 4

=item idir_listing

 $iter = idir_listing ($path);

Iterator that returns the names of the files in the C<$path>
directory.  If C<$path> is omitted, defaults to the current directory.
Does not return the C<.> and C<..> files (under unix).

Requires L<IO::Dir> and L<Cwd>.

I<Example:>

To return only certain files, combine this with an igrep:

 $iter = igrep {-s && -M < 1} idir "/some/path";

(Returns non-empty files modified less than a day ago).
(L<igrep|Iterator::Util/igrep>) is defined in the L<Iterator::Util>
module).

=item idir_walk

 $iter = idir_walk ($path);

Returns the files in a directory tree, one by one.  It's sort of like
L<File::Find> in slow motion.

Requires L<IO::Dir> and L<Cwd>.

=item ifile

 $iter = ifile ($filename, \%options);

Opens a file, generates an iterator to return the lines of the file.

C<\%options> is a reference to a hash of options.  Currently, two
options are supported:

=over 2

=item chomp

C<chomp =E<gt> boolean> indicates whether lines should be C<chomp>ed
before being returned by the iterator.  The default is true.

=item $/

C<'$/' =E<gt> value> specifies what string to use as the record
separator.  If not specified, the current value of C<$/> is used.

"C<rs>" or "C<input_record_separator>" may be used as option names
instead of "C<$/>", if you find that to be more readable.  See
the L<English> module.

=back

Option names are case-insensitive.

C<ifile> requires L<IO::File>.

=item ifile_reverse

 $iter = ifile_reverse ($filename, \%options);

Exactly the same as L</ifile>, but reads the lines of the file
backwards.

The C<input_record_separator> option values C<undef> (slurp whole
file) and scalar references (fixed-length records) are not currently
supported.

=back

=head1 INTERFACE CHANGE

In version 0.01 of Iterator::IO, the L</ifile> and L<ifile_reverse>
functions accepted their options in a different manner.  This has now
changed to operate via a hash reference of options.  The old way will
still work, but is deprecated and I<will> be removed in a future
release.

=head1 EXPORTS

This module exports all function names to the caller's namespace by
default.

=head1 DIAGNOSTICS

Iterator::IO uses L<Exception::Class> objects for throwing exceptions.
If you're not familiar with Exception::Class, don't worry; these
exception objects work just like C<$@> does with C<die> and C<croak>,
but they are easier to work with if you are trapping errors.

See the L<Iterator|Iterator/DIAGNOSTICS> module documentation for more
information on how to trap and handle these exception objects.

=over 4

=item * Parameter Errors

Class: C<Iterator::X::Parameter_Error>

You called an Iterator::IO function with one or more bad parameters.
Since this is almost certainly a coding error, there is probably not
much use in handling this sort of exception.

As a string, this exception provides a human-readable message about
what the problem was.

=item * Exhausted Iterators

Class: C<Iterator::X::Exhausted>

You called C<value> on an iterator that is exhausted; that is, there
are no more values in the sequence to return.

As a string, this exception is "Iterator is exhausted."

=item * I/O Errors

Class: C<Iterator::X::IO_Error>

This exception is thrown when any sort of I/O error occurs; this
only happens with the filesystem iterators.

This exception has one method, C<os_error>, which returns the original
C<$!> that was trapped by the Iterator object.

As a string, this exception provides some human-readable information
along with C<$!>.

=item * Internal Errors

Class: C<Iterator::X::Internal_Error>

Something happened that I thought couldn't possibly happen.  I would
appreciate it if you could send me an email message detailing the
circumstances of the error.

=back

=head1 REQUIREMENTS

Requires the following additional modules:

L<Iterator>

L<IO::Dir> and L<Cwd> are required if you use L</idir_listing> or
L</idir_walk>.

L<IO::File> is required if you use L</ifile> or L</ifile_reverse>

=head1 SEE ALSO

I<Higher Order Perl>, Mark Jason Dominus, Morgan Kauffman 2005.

L<http://perl.plover.com/hop/>

=head1 THANKS

Much thanks to Will Coleda and Paul Lalli (and the RPI lily crowd in
general) for suggestions for the pre-release version.

=head1 AUTHOR / COPYRIGHT

Eric J. Roode, roode@cpan.org

Copyright (c) 2005 by Eric J. Roode.  All Rights Reserved.
This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

To avoid my spam filter, please include "Perl", "module", or this
module's name in the message's subject line, and/or GPG-sign your
message.

=cut

=begin gpg

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.4.1 (Cygwin)

iD8DBQFDC5SrY96i4h5M0egRAnaKAJ9VJIIEh1DqBRhw0wyk4ceczcRw0ACg9QOs
6bT8QG6x/dRiXj17nuiyWmk=
=VvwS
-----END PGP SIGNATURE-----

=end gpg
