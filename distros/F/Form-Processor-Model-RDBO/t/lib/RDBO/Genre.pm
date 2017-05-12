package RDBO::Genre;

use strict;

use base 'DB::Object';

__PACKAGE__->meta->setup(
    table => 'genre',

    columns => [ qw/ id name / ],

    primary_key_columns => [ 'id' ],

    unique_key => 'name',

    relationships => [
        artist_genre_map => {
            type       => 'one to many',
            class      => 'RDBO::ArtistGenreMap',
            column_map => { id => 'genre_id' }
        },
        artists => {
            type      => 'many to many',
            map_class => 'RDBO::ArtistGenreMap',
            map_from  => 'genre',
            map_to    => 'artist'
        }
    ]
);

=head1 AUTHOR

vti

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
