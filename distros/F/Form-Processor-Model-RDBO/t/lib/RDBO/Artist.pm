package RDBO::Artist;

use strict;

use base qw(DB::Object);

__PACKAGE__->meta->setup(
   table => 'artist',

   columns => [
       qw/ id name  /
   ],

   primary_key_columns => [ qw/ id / ],

   unique_key => [ qw/ name / ],

    relationships =>
    [
        albums => {
            type       => 'one to many',
            class      => 'RDBO::Album',
            column_map => { id => 'artist_id' },
        },
        genres => {
            type      => 'many to many',
            map_class => 'RDBO::ArtistGenreMap',
            map_from  => 'artist',
            map_to    => 'genre'
        }
    ],
);

=head1 AUTHOR

vti

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
