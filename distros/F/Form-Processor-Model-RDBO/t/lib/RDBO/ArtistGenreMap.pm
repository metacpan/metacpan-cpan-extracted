package RDBO::ArtistGenreMap;

use strict;

use base 'DB::Object';

__PACKAGE__->meta->setup(
    table => 'artist_genre_map',

    columns => [ qw/ artist_id genre_id / ],

    primary_key_columns => [ 'artist_id', 'genre_id' ],

    foreign_keys => [
        artist => {
            class       => 'RDBO::Artist',
            key_columns => { artist_id => 'id' }
        },
        genre => {
            class       => 'RDBO::Genre',
            key_columns => { genre_id => 'id' }
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
