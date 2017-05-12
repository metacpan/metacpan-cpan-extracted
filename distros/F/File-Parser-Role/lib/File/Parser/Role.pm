package File::Parser::Role;

use 5.008;

use warnings;
use strict;
use utf8;
use Carp;
use IO::File;
use IO::String;

use version; our $VERSION = qv('0.2.4');
use Moo::Role;
use MooX::Aliases;

# File things
has file     =>  ( is => "ro", alias => [qw/path filepath/] );
has size     =>  ( is => "ro" );
has filename =>  ( is => "ro" );
has encoding =>  ( is => "ro"   );
has fh       =>  ( is => "lazy" );

requires "parse";

sub _build_fh {

    my $self = shift;

    ## If stringified input is a readable file, treat it like that
    if ( -r "${\ $self->file }" ) {

        my $fh = IO::File->new( $self->file, "r" );

        ## set it to the (possibly) specified encoding
        if ( defined $self->encoding ) {
            binmode $fh, sprintf(":encoding(%s)", $self->encoding) or confess $!;
        }
        return $fh;

    }

    ## A scalar reference is assumed to be content to be parsed
    elsif ( ref $self->file eq "SCALAR" ) {
        return IO::String->new( $self->file );
    }

    ## If it's any kind of object, assume it can be <read> from
    elsif ( ref $self->file ) {

        ## assume its something that can be read from as a file handle
        ## set encoding and use it
        if ( defined $self->encoding ) {
            binmode $self->file, sprintf(":encoding(%s)", $self->encoding) or confess $!;
        }
        return $self->file;

    }

    ## can't grok it
    else {
        confess "Cannot work with input file - its neither a readable path nor a reference";
    }

}

around BUILDARGS => sub {

    my ($orig, $class) = (shift, shift);

    my @args = @_;

    if ( @args == 1 and (ref( $args[0])||'') ne 'HASH' ) {
        @args = ({ file => $args[0] });
    }

    if ( not exists $args[0]->{file} and defined $args[0]->{filename} ) {
        ## filename gets deleted for now and only re-inserted later on
        ## if proven to be a valid filename
        $args[0]->{file} = delete $args[0]->{filename};
    }

    ## capture the aliases this way
    my $obj = $class->$orig(@args);
    my $f = $obj->{file};

    ## test if it seems to be a path to a file
    if ( defined $f and -e "$f" ) {

        ## size (most likely) and filename can now be set

        ## only sets/overrides size if it isn't already set
        $obj->{size} = -s "$f" unless exists $obj->{size};

        ## set filename if not already set
        $obj->{filename} = "$f" unless defined $obj->{filename};

    }

    return $obj;

};

sub BUILD {
    my $self = shift;
    $self->parse;
};

1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

File::Parser::Role - Read and prepare parsing of file (or glob) data
from some source

=head1 VERSION

This document describes File::Parser::Role version 0.2.4 This is a
Moo::Role for reading (and then parsing) single data files. It makes
the constructor support 3 kinds of file sources:

=over

=item a path to a readable file

=item a file handle or anything that can be read like one

=item a scalar references to content

=back

It also provides an attribute C<fh> that is a handle to the contents
of the file argument.

=head1 SYNOPSIS

    package MyClassThatDoesStuffWithAFile;

    sub parse {
        my $self = shift;

        # ... do stuff, $self->fh available
    }

    with "File::Parser::Role";

And then in some nearby code:

    my $obj = MyClassThatDoesStuffWithAFile->new("some_file.txt");
    # or #
    my $obj = MyClassThatDoesStuffWithAFile->new(file => "some_file.txt");

    ## and with encoding:
    my $obj = MyClassThatDoesStuffWithAFile->new( file => "some_file.txt", encoding => "utf8" );
    ## encoding can be anything that binmode's encoding() can understand.

    print $obj->filename; # "some_file.txt"
    print $obj->size;     # size of some_file.txt

    ## - OR -

    my $fh = IO::File->new( "< some_file.txt" );
    ## you are responsible for encoding on this handle!

    my $obj = MyClassThatDoesStuffWithAFile->new( file => $fh );

    ## no filename nor file size available

    ## - OR -

    my $file_content = slurp_file( "some_file.txt" );
    my $obj = MyClassThatDoesStuffWithAFile->new( file => \$file_content );

    ## you are also responsible for encoding on this data
    ## no file name nor file size available

=head1 DESCRIPTION

This role provides all the bare necessities, and then some, that you
expect when you want to parse or otherwise handle a chunk of content
typically provided as a file.

It is motivated by, and ideal for, objects that parse files.

=head1 INTERFACE

=head2 new

The constructor is meant to be all expected kinds of flexible:

=over

=item * new("file") # a local filename

=item * new($fh)

=item * new( file => "file", encoding => "utf8" ); # also works with: C<new({ ... })>

=item * new( \"some content" )

=back

The constructor tests the argument to see if it's a path to a local
file. If so, it records its C<filename> and C<size> in those two
attributes.

It stringifies the file argument for this check, allowing file objects
that stringify to paths to work correctly. This applies among others
to Path::Tiny.

If a reference or an object is passed as the argument, (that does not
stringity fo a readable local file), it is assumed to be something
that can be read with the <> operator and passed unchanged to the
C<fh> attribute of the class.

=head2 fh

Returns ro handle (IO::File for files, IO::String for content) to the
contents of the input, be it a file or a sclar reference or an already
opened file handle

If the input argument is assumed to be a readable handle to content,
it is passed straight through with this method.

=head2 parse

A required method that you must write! It is run in BUILD

=head1 DIAGNOSTICS

=over

=item C<< Cannot work with input file >>

The file argument is neither an existing file, an object nor a
reference to content

=back

=head1 DEPENDENCIES

=over

=item * L<Moo>

=item * L<Moo::Role>

=item * L<MooX::Aliases>

=item * L<IO::String>

=item * L<Test::Most>

=item * L<Test::Output>

=item * L<Test::Warnings>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 REPOSITORY

L<https://github.com/torbjorn/File-Parser-Role>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-file-parser-role@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Torbjørn Lindahl  C<< <torbjorn.lindahl@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Torbjørn Lindahl C<<
<torbjorn.lindahl@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


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
