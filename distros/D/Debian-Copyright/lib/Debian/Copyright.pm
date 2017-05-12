=head1 NAME

Debian::Copyright - manage Debian copyright files

=head1 VERSION

This document describes Debian::Copyright version 0.2 .

=head1 SYNOPSIS

    my $c = Debian::Copyright->new();       # construct a new
    $c->read($file1);                       # parse debian copyright file
    $c->read($file2);                       # parse a second
    $c->write($ofile);                      # write to file

=head1 DESCRIPTION

Debian::Copyright can be used for the representation, manipulation and
merging of Debian copyright files in an object-oriented way. It provides easy
reading and writing of the F<debian/copyright> file found in Debian source
packages. Debian has recently started standardising its copyright files
around the machine-readable
L<DEP-5/Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/>
format. 

=head2 note on terminology

The term "Stanza" derives from the
L<dh-make-perl|http://packages.debian.org/sid/dh-make-perl> tool. The official
term would now be "Paragraph". For the purposes of discussing the DEP-5 format the terms are used interchangeably in this documentation.

=head1 FIELDS

=head2 header

An instance of L<Debian::Copyright::Stanza::Header> class. Contains the 
the first stanza of the copyright file. If multiple files were parsed only the
first will be retained.

=head2 files

A hash reference (actually L<Tie::IxHash> instance) with keys being the values
of the C<Files> clause and values instances of
L<Debian::Copyright::Stanza::Files> class.

=head2 licenses

A hash reference (actually L<Tie::IxHash> instance) with keys being the values
of the C<License> clause and values instances of
L<Debian::Copyright::Stanza::License> class.

=cut

package Debian::Copyright;
require v5.10.1;
use base 'Class::Accessor';
use strict;
use Carp;

our $VERSION = '0.2';

__PACKAGE__->mk_accessors(qw( _parser header files licenses ));

use Parse::DebControl;
use Debian::Copyright::Stanza::Header;
use Debian::Copyright::Stanza::Files;
use Debian::Copyright::Stanza::License;
use Tie::IxHash;

=head1 CONSTRUCTOR

=head2 new

Constructs a new L<Debian::Copyright> instance.

The C<header> field is initialised with an empty string.
The C<files_block> and C<license_block> fields are initialised with an
empty instance of L<Tie::IxHash>.

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    $self->_parser( Parse::DebControl->new );

    $self->header(undef);
    $self->files( Tie::IxHash->new );
    $self->licenses( Tie::IxHash->new );

    return $self;
}

=head1 METHODS

=head2 read I<file>

Parse L<debian/copyright> and accessors.

I<file> can be either a file name, an opened file handle or a string scalar
reference.

=cut

sub read {
    my ( $self, $file ) = @_;

    my $parser_method = 'parse_file';

    if ( ref($file) ) {
        $file          = $$file;
        $parser_method = 'parse_mem';
    }

    my $stanzas = $self->_parser->$parser_method( $file,
        { useTieIxHash => 1, verbMultiLine => 1 } );

    if (exists $stanzas->[0]->{Format}) {
        my $header = shift @$stanzas;
        if (! $self->header) {
             $self->header( Debian::Copyright::Stanza::Header->new($header) );
        }
    }

    for (@$stanzas) {
        next if $_->{Format};
        if ( $_->{Files} ) {
            $self->files->Push(
                $_->{Files} => Debian::Copyright::Stanza::Files->new($_) );
            next;
        }
        if ( $_->{License} ) {
            my $license = $_->{License};
            if ($license =~ m{\A([^\n]+)$}xms) {
                $license = $1;
            }
            else {
                croak "License stanza does not make sense";
            }
            $self->licenses->Push(
                $license => Debian::Copyright::Stanza::License->new($_) );
            next;
        }
        die "Got copyright stanza with unrecognised field\n";
    }
    return;
}

=head2 write I<file>

Writes a debian/copyright-like file in I<file> with the contents defined in the
accessor fields.

I<file> can be either a file name, an opened file handle or a string scalar
reference.

=cut

sub write {
    my ( $self, $file ) = @_;

    my @stanzas = (
        $self->header,
        $self->files->Values,
        $self->licenses->Values
    );
    my $string = join "\n", @stanzas;

    if ( ref($file) and ref($file) eq 'SCALAR' ) {
        $$file = $string;
    }
    elsif ( ref($file) and ref($file) eq 'GLOB' ) {
        $file->print($string);
    }
    else {
        my $fh;
        open $fh, '>', $file or die "Unable to open '$file' for writing: $!";

        print $fh $string;
    }
}

=head1 LIMITATIONS

=over

=item This module is written with one particular version of
L<DEP-5|http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/>
in mind. Furthermore version 0.1 of this software was for a draft
version the standard. The changes in going from draft to standard
were such that it was not worth attempting to maintain backwards
compatibility.

=item Test coverage is not yet complete.

=back

=head1 INCOMPATIBILITIES

This version is not backwards compatible with version 0.1.

=head1 ACKNOWLEDGEMENTS

Thanks to Charles Plessy for various comments regarding the documentation.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2012 Nicholas Bamber L<nicholas@periapt.co.uk>

This module was adapted from L<Debian::Control>.
Copyright (C) 2009 Damyan Ivanov L<dmn@debian.org> [Portions]

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

1;
