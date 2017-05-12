package Locale::Maketext::Lexicon::Slurp;

use strict;
use warnings;

use File::Basename ();
use Path::Class;

our $VERSION = "0.01";
our $AUTHORITY = 'NUFFIN';

sub read_file {
    my ( $self, %args ) = @_;

    local $/;

    my $file = $args{path};

    open my $fh, "<", $file or die "open($file): $!";

    binmode $fh, $args{binmode} if exists $args{binmode};

    scalar(<$fh>);
}

sub readdir {
    my ( $self, $dir ) = @_;
    grep { -f $_ } $dir->children;
}

sub get_files {
    my ( $self, $args ) = @_;

    my @files;
    my $dir = $args->{dir} && -d $args->{dir} ? Path::Class::dir($args->{dir}) : undef;

    if ( my $files = $args->{files} ) {
        if ( $dir ) {
            if ( (ref($files)||'') ne 'ARRAY' ) {
                @files = map { Path::Class::file($_) } glob( $dir->file($files)->stringify );
            } else {
                @files = map { $dir->file($_) } @$files;
            }
        } else {
            if ( (ref($files)||'') ne 'ARRAY' ) {
                @files = map { Path::Class::file($_) } glob($files);
            } else {
                @files = @$files;
            }
        }
    } elsif ( $dir ) {
        my $readdir = $args->{readdir} || "readdir";
        @files = $self->$readdir( $dir );
    } elsif ( $args->{dir} ) { # not a directory, special case for 1 arg form
        @files = map { Path::Class::file($_) } glob($args->{dir});
    }

    if ( my $re = $args->{regex} ) {
        @files = grep { $_ =~ $re } @files;
    }

    if ( my $filter = $args->{filter} ) {
        @files = grep { $self->$filter( $_ ) } @files;    
    }

    if ( @files ) {
        if ( $dir ) {
            my $dir_obj = Path::Class::dir($dir);
            return { map { Path::Class::file($_)->relative( $dir_obj )->stringify => "$_" } @files },
        } else {
            return { map { File::Basename::basename($_) => "$_" } @files };
        }
    }

    die "No files specified";
}

sub parse {
    my ( $self, @args ) = @_;

    unshift @args, "dir" if @args % 2 == 1; # work in Lexicon's * mode

    my $args = { @args };

    my $files = $self->get_files( $args );

    return {
        map {
            my $name = $_;
            my $path = $files->{$name};
            $name => sub {
                return $self->read_file(
                    %$args,
                    path => $path,
                    name => $name,
                    args => \@_
                )
            }
        } keys %$files
    };
}

1;

__END__

=pod

=head1 NAME

Locale::Maketext::Lexicon::Slurp - One message per file Maketext lexicon.

=head1 SYNOPSIS

    use Locale::Maketext::Lexicon {
        en => [ Slurp => [ "/my/dir/en", regex => qr{\.html$} ] ],
        de => [ Slurp => [ "/my/dir/de", files => [qw/blah.html foo.html/] ],
    }; 

=head1 DESCRIPTION

This maketext lexicon module provides a file based lexicon format, with the
file name (or relative path) acting as the message id, and the file contents
being the message string.

This is useful for displaying large bits of text, like several paragraphs of
instructions, or the answers to an FAQ, without needing to bother with
formatting and escaping the text in some format.

This lexicon provider is also geared towards subclassing. Hooks are provided to
make subclassing easy, so that you may add interpolation using a template
module, for example. See the L</METHODS> section for more details.

=head1 OPTIONS

The accepted options are:

=over 4

=item dir

The base directory for the message files

If the directory does not exist it's treated like a glob pattern. See C<files>
for more details.

Used by C<get_files>.

=item files

An array reference or a glob pattern of files to use as messages.

If C<dir> is also specified then the files are considered relative and the
relative paths are the IDs. If C<dir> is not specified, then the files are
assumed to be valid full paths (relative or absolute) and the file name becomes
the ID.

If unspecified then all of the files in C<dir> are used.

Used by C<get_files>.

=item regex

An regex filter to apply to file names. Gets matched on the full path.

This is always applied if it exists, even if C<filter> also exists, and if
globbing was used.

Used by C<get_files>.

=item filter

An optional code ref filter to apply to files. Gets the lexicon factory object
as the invocant, and a L<Path::Class::File> object as the argument.

This is always applied if it exists, even if C<regex> also exists, and if
globbing was used.

Used by C<get_files>.

=item binmode

The C<binmode> to apply after opening a file for reading.

Used by C<read_file>.

=item readdir

A code reference (or method name) to use instead of C<readdir>, for when
something like recursion is needed and a subclass of this module is too
daunting. See C<readdir> (the method) for details.

Used by C<get_files>.

=back

If the argument list is odd sized, the first item is assumed to be the value of
the C<dir> argument.

=head1 METHODS

These methods are not generally exposed to the user, but are documented for subclassing.

=over 4

=item B<parse (@args)>

Called by L<Locale::Maketext::Lexicon>. Used internally to set up the lexicon entries.

=item B<read_file (%args)>

This base implementation of C<read_file> reads the contents of the file
specified by the C<path> argument. Also takes an optional C<binmode> argument,
which can be set in the import statement. See L</OPTIONS>.

Additional, and currently unused arguments passed to this method are:

=over 4

=item name

The ID of the message

=item args

The arguments given to C<maketext> for interpolation.

=back

=item B<get_files ($args)>

Enumerate all the files (returns a hash reference of ID to path) in the
specified source.

See L</OPTIONS> for the parameters it supports and how they behave.

=item B<readdir ($dir)>

Used to list the sub items of a directory.  Mostly a convenience method.

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 TODO

Consider caching options (the the OS page cache should be enough).

=head1 AUTHOR

Yuval Kogman

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
