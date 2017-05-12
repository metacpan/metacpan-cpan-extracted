package RDBO::Album;

use strict;

use base qw(DB::Object);

__PACKAGE__->meta->setup(
   table => 'album',

   columns => [
       qw/ id artist_id title  /
   ],

   primary_key_columns => [ qw/ id / ],

   foreign_keys =>
   [
        artist_fk =>
        {
          class          => 'RDBO::Artist',
          key_columns    => { artist_id => 'id' },
        },
    ],

    relationships =>
    [
        artist_rel =>
        {
          type       => 'many to one',
          class      => 'RDBO::Artist',
          column_map => { artist_id => 'id' },
        },

    ],

);

sub active_column { 'title' }

=head1 AUTHOR

vti

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
