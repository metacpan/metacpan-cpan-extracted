package Foorum::Schema::UserProfilePhoto;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('user_profile_photo');
__PACKAGE__->add_columns(
    'user_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'type',
    {   data_type     => 'ENUM',
        default_value => 'upload',
        is_nullable   => 0,
        size          => 6
    },
    'value',
    {   data_type     => 'VARCHAR',
        default_value => 0,
        is_nullable   => 0,
        size          => 255
    },
    'width',
    {   data_type     => 'SMALLINT',
        default_value => 0,
        is_nullable   => 0,
        size          => 6
    },
    'height',
    {   data_type     => 'SMALLINT',
        default_value => 0,
        is_nullable   => 0,
        size          => 6
    },
    'time',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key('user_id');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::UserProfilePhoto - Table 'user_profile_photo'

=head1 COLUMNS

=over 4

=item user_id

INT(11)

NOT NULL, PRIMARY KEY

=item type

ENUM(6)

NOT NULL, DEFAULT VALUE 'upload'

=item value

VARCHAR(255)

NOT NULL

=item width

SMALLINT(6)

NOT NULL

=item height

SMALLINT(6)

NOT NULL

=item time

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

