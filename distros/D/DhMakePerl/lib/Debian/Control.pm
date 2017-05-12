
=head1 NAME

Debian::Control - manage Debian source package control files

=head1 SYNOPSIS

    my $c = Debian::Control->new();         # construct a new
    $c->read($file);                        # parse debian/control file
    $c->write($file);                       # write to file
    print $c->source->Source;
    print $c->source->Build_Depends;        # Debian::Dependencies object
    $c->binary->{'libfoo-perl'}->Description(
        "Foo Perl module\n" .
        " Foo makes this and that"
    );

=head1 DESCRIPTION

Debian::Control can be used for representation and manipulation of Debian
source package control files in an object-oriented way. It provides easy
reading and writing of the F<debian/control> file found in Debian source
packages.

=head1 FIELDS

=over

=item source

An instance of L<Debian::Control::Stanza::Source> class. Contains the source
stanza of the Debian source package control file.

=item binary

A hash reference with keys being binary
package names and values instances of L<Debian::Control::Stanza::Binary> class.
Contains the information of the binary package stanzas of Debian source package
control file.

=item binary_tie

A L<Tie::IxHash> object tied to the B<binary> hash.

=back

=cut

package Debian::Control;

use base 'Class::Accessor';
use strict;
use warnings;

our $VERSION = '0.77';

__PACKAGE__->mk_accessors(qw( source binary binary_tie _parser ));

use Parse::DebControl;
use Debian::Control::Stanza::Source;
use Debian::Control::Stanza::Binary;

=head1 CONSTRUCTOR

=over

=item new

Constructs a new L<Debian::Control> instance.

The C<source> field is initialized with an empty instance of
L<Debian::Control::Stanza::Source> and C<binary> field is initialized with an
empty instance of L<Tie::IxHash>.

=back

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    $self->_parser( Parse::DebControl->new );

    my %b;
    $self->binary_tie( tie %b, 'Tie::IxHash' );
    $self->binary( \%b );
    $self->source( Debian::Control::Stanza::Source->new );

    return $self;
}

=head1 METHODS

=over

=item read I<file>

Parse L<debian/control> and populate C<source> and C<binary> accessors.

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

    for (@$stanzas) {
        if ( $_->{Source} ) {
            $self->source( Debian::Control::Stanza::Source->new($_) );
        }
        elsif ( $_->{Package} ) {
            $self->binary_tie->Push(
                $_->{Package} => Debian::Control::Stanza::Binary->new($_) );
        }
        else {
            die "Got control stanza with neither Source nor Package field\n";
        }
    }
}

=item write I<file>

Writes a debian/control-like file in I<file> with the contents defined in the
C<source> and C<binary> fields.

I<file> can be either a file name, an opened file handle or a string scalar
reference.

All dependency lists are sorted before writing.

=cut

sub write {
    my ( $self, $file ) = @_;

    for my $s ( $self->source, $self->binary_tie->Values ) {
        for ( $s->fields ) {
            $s->$_->sort if $s->is_dependency_list($_);
        }
    }

    if ( ref($file) and ref($file) eq 'SCALAR' ) {
        $$file = join( "\n", $self->source, $self->binary_tie->Values );
    }
    elsif ( ref($file) and ref($file) eq 'GLOB' ) {
        $file->print( join( "\n", $self->source, $self->binary_tie->Values ) );
    }
    else {
        my $fh;
        open $fh, '>', $file or die "Unable to open '$file' for writing: $!";

        print $fh join( "\n", $self->source, $self->binary_tie->Values );
    }
}

=item is_arch_dep

Returns true if the package is architecture-dependent. This is determined by
the C<Architecture> field of the first binary package. If it equals to C<all>,
then the package is architecture-independent; otherwise it is
architecture-dependent.

Returns I<undef> if it is not possible to determine whether the package is
architecture-dependent or not. This is the case when there are no binary
package stanzas present or the first has no C<Archiitecture> field.

=cut

sub is_arch_dep {
    my $self = shift;

    my $bin = $self->binary_tie->Values(0);

    return undef unless $bin;

    my $arch = $bin->Architecture;

    return undef unless defined($arch);

    return ( $arch ne 'all' );
}

=back

=head1 SEE ALSO

L<Debian::Control::Stanza::Source>, L<Debian::Control::Stanza::Binary>,
L<Debian::Control::FromCPAN>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 Damyan Ivanov L<dmn@debian.org>

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

1;
