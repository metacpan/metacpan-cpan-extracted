# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024-2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for reading and writing ValueFile files

package File::ValueFile;

use v5.10;
use strict;
use warnings;

use Carp;
use Data::Identifier v0.08;
use parent 'Data::Identifier::Interface::Known';

our $VERSION = v0.09;

my @wellknown = (
    Data::Identifier->new(uuid => '54bf8af4-b1d7-44da-af48-5278d11e8f32', displayname => 'ValueFile'),
    Data::Identifier->new(uuid => 'e5da6a39-46d5-48a9-b174-5c26008e208e', displayname => 'tagpool-source-format'),
    Data::Identifier->new(uuid => '11431b85-41cd-4be5-8d88-a769ebbd603f', displayname => 'tagpool-directory-info-format'),
    Data::Identifier->new(uuid => 'afdb46f2-e13f-4419-80d7-c4b956ed85fa', displayname => 'tagpool-taglist-format-v1'),
    Data::Identifier->new(uuid => '25990339-3913-4b5a-8bcf-5042ef6d8b5e', displayname => 'tagpool-httpd-htdirectories-format'),
    Data::Identifier->new(uuid => '5a1895b8-61f1-4ce1-a44f-1a239b7d9de7', displayname => 'tagpool-source-format-hybrid'),
    Data::Identifier->new(uuid => 'f06c2226-b33e-48f2-9085-cd906a3dcee0', displayname => 'tagpool-source-format-modern-limited'),
    Data::Identifier->new(uuid => '1c71f5b1-216d-4a9b-81a1-54dc22d8a067', displayname => 'tagpool-source-format-modern-full'),
    Data::Identifier->new(uuid => '7e5d56d4-98e6-4205-89c0-763e1d729531', displayname => 'utf-8-marker'),
    Data::Identifier->new(uuid => '2ec67bbe-4698-4a0c-921d-1f0951923ee6', displayname => 'dot-repeat-marker'),
);

$_->register foreach @wellknown;

my %_is_utf8 = (
    (map {$_ => undef} (
            'e5da6a39-46d5-48a9-b174-5c26008e208e', # tagpool-source-format
            '11431b85-41cd-4be5-8d88-a769ebbd603f', # tagpool-directory-info-format
            '7e5d56d4-98e6-4205-89c0-763e1d729531', # utf-8-marker
        )),
);




sub add_utf8_marker {
    my ($pkg, $class, $id) = @_;

    if (!defined($class) || !defined($id)) {
        croak 'Class or identifier not defined';
    }

    if ($class ne 'format' && $class ne 'feature') {
        croak 'Class given with an unsupported value: '.$class;
    }

    $_is_utf8{Data::Identifier->new(from => $id)->ise} = undef;
}

# ---- Private helpers ----

sub _is_utf8 {
    my ($pkg, $id) = @_;
    return exists $_is_utf8{Data::Identifier->new(from => $id)->ise};
}

sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    croak 'Unsupported options passed' if scalar(keys %opts);
    return (\@wellknown, rawtype => 'uuid') if $class eq ':all';
    croak 'Unsupported class';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ValueFile - module for reading and writing ValueFile files

=head1 VERSION

version v0.09

=head1 SYNOPSIS

    use File::ValueFile;

This module only provides some global functionality.

For reading and writing ValueFiles see L<File::ValueFile::Simple::Reader> and L<File::ValueFile::Simple::Writer>.

=head1 METHODS

=head2 known

    my @list = File::ValueFile->known($class [, %opts ] );

This method will return a list of well known tags of the given class C<$class>.
It is an implementation of L<Data::Identifier::Interface::Known/known>.
See there for details

Currently no specific classes is defined. The pseudo class C<:all> is however supported.

=head2 add_utf8_marker

    File::ValueFile->add_utf8_marker(format => $id);
    # or:
    File::ValueFile->add_utf8_marker(feature => $id);

Add a format or feature (given by C<$id>) as a marker for UTF-8 en/decoding.
Formats and features that have been marked to use UTF-8 are autodetected
in L<File::ValueFile::Simple::Reader> and L<File::ValueFile::Simple::Writer>.

C<$id> can be any value supported by L<Data::Identifier/new>'s C<from> mode.
However It is often wise to pass an instance of L<Data::Identifier> which is already
registered using L<Data::Identifier/register>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
