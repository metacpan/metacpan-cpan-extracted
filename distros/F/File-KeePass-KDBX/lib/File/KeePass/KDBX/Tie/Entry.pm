package File::KeePass::KDBX::Tie::Entry;
# ABSTRACT: Database entry

use warnings;
use strict;

use Crypt::Digest;
use Time::Piece;
use boolean;
use namespace::clean;

use parent 'File::KeePass::KDBX::Tie::Hash';

our $VERSION = '0.901'; # VERSION

my %GET = (
    accessed            => sub { File::KeePass::KDBX::_decode_datetime($_[0]->last_access_time) },
    usage_count         => sub { $_[0]->usage_count },
    expires_enabled     => sub { $_[0]->expires ? 1 : 0 },
    created             => sub { File::KeePass::KDBX::_decode_datetime($_[0]->creation_time) },
    expires             => sub { File::KeePass::KDBX::_decode_datetime($_[0]->expiry_time) },
    modified            => sub { File::KeePass::KDBX::_decode_datetime($_[0]->last_modification_time) },
    location_changed    => sub { File::KeePass::KDBX::_decode_datetime($_[0]->location_changed) },
    auto_type_munge     => sub { $_[0]->auto_type->{data_transfer_obfuscation} ? 1 : 0 },
    auto_type_enabled   => sub { $_[0]->auto_type->{enabled} ? 1 : 0 },
    auto_type           => sub { $_[-1]->_tie([], 'AssociationList', $_[0]) },
    comment             => sub { $_[0]->notes },
    username            => sub { $_[0]->username },
    password            => sub { $_[0]->password },
    url                 => sub { $_[0]->url },
    title               => sub { $_[0]->title },
    protected           => sub { $_[-1]->_tie({}, 'Protected', $_[0]) },
    override_url        => sub { $_[0]->override_url },
    tags                => sub { $_[0]->tags },
    icon                => sub { $_[0]->icon_id + 0 },
    id                  => sub { $_[0]->uuid },
    foreground_color    => sub { $_[0]->foreground_color },
    background_color    => sub { $_[0]->background_color },
    history             => sub { $_[-1]->_tie([], 'EntryList', $_[0], 'history') },
    strings             => sub { $_[-1]->_tie({}, 'Strings', $_[0]) },
    binary              => sub { $_[-1]->_tie({}, 'Binary', $_[0]) },
);
my %SET = (
    accessed            => sub { $_[0]->last_access_time(File::KeePass::KDBX::_encode_datetime($_)) },
    usage_count         => sub { $_[0]->usage_count($_) },
    expires_enabled     => sub { $_[0]->expires($_) },
    created             => sub { $_[0]->creation_time(File::KeePass::KDBX::_encode_datetime($_)) },
    expires             => sub { $_[0]->expiry_time(File::KeePass::KDBX::_encode_datetime($_)) },
    modified            => sub { $_[0]->last_modification_time(File::KeePass::KDBX::_encode_datetime($_)) },
    location_changed    => sub { $_[0]->location_changed(File::KeePass::KDBX::_encode_datetime($_)) },
    override_url        => sub { $_[0]->override_url($_) },
    auto_type_munge     => sub { $_[0]->auto_type->{data_transfer_obfuscation} = boolean($_) },
    auto_type           => sub { }, # TODO - Replace all autotype associations
    auto_type_enabled   => sub { $_[0]->auto_type->{enabled} = boolean($_) },
    comment             => sub { $_[0]->notes($_) },
    tags                => sub { $_[0]->tags($_) },
    protected           => sub { }, # TODO - Replace all protect flags
    title               => sub { $_[0]->title($_) },
    icon                => sub { $_[0]->icon_id($_) },
    id                  => sub { $_[0]->uuid(File::KeePass::KDBX::_encode_uuid($_)) },
    foreground_color    => sub { $_[0]->foreground_color($_) },
    background_color    => sub { $_[0]->background_color($_) },
    url                 => sub { $_[0]->url($_) },
    username            => sub { $_[0]->username($_) },
    password            => sub { $_[0]->password($_) },
    history             => sub { }, # TODO - Replace all history
    strings             => sub { }, # TODO - Replace all strings
    binary              => sub { }, # TODO - Replace all binaries
);

sub getters { \%GET }
sub setters { \%SET }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KeePass::KDBX::Tie::Entry - Database entry

=head1 VERSION

version 0.901

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KeePass-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
