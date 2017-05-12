package JavaScript::Framework::jQuery::Subtypes;

my @type;
BEGIN {
    @type = qw(
        cssAsset
        cssAssetList
        libraryAssets
        pluginAssets
    );
}

use warnings;
use strict;

use MooseX::Types::Moose qw( Int Str ArrayRef HashRef );
use MooseX::Types::Structured qw( Dict );
use MooseX::Types -declare => [ @type ];

our $VERSION = '0.05';

subtype cssAsset,
    as Dict[
        href => Str,
        media => Str,
    ];

subtype cssAssetList,
    as ArrayRef[ cssAsset ];

subtype libraryAssets,
    as Dict[
        src => ArrayRef[ Str ],
        css => cssAssetList,
    ];

subtype pluginAssets,
    as ArrayRef [
        Dict[
            name => Str,
            library => libraryAssets,
        ]
    ];

1;

=head1 NAME

JavaScript::Framework::jQuery::Subtypes - MooseX::Types type declarations

=head1 SYNOPSIS

 use JavaScript::Framework::jQuery::Subtypes ':all';

 # now you may use custom types in your 'has' declarations in Moose packages.

=head1 DESCRIPTION

This module provides all the subtype declarations for the Moose packages
in the JavaScript::Framework::jQuery namespace.

=head1 TYPES DEFINED

=head2 cssAsset

List of hash references, keys 'href' and 'media'.

=head2 cssAssetList

Reference to an array of cssAsset-type items.

=head2 libraryAssets

Reference to an array of references to hashes of 'src' (array ref) and
'css'.

=head2 pluginAssets

Reference to an array of references to hashes of 'name' and 'library' (reference
to an array of items of type libraryAssets).

=head1 AUTHOR

David P.C. Wollmann E<lt>converter42 at gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 David P.C. Wollmann, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

