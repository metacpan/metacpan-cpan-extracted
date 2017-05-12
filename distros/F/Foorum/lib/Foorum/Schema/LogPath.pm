package Foorum::Schema::LogPath;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('log_path');
__PACKAGE__->add_columns(
    'path_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'session_id',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 72,
    },
    'user_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'path',
    {   data_type     => 'VARCHAR',
        default_value => '',
        is_nullable   => 0,
        size          => 255
    },
    'get',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 255,
    },
    'post',
    {   data_type     => 'TEXT',
        default_value => undef,
        is_nullable   => 1,
        size          => 65535,
    },
    'time',
    {   data_type     => 'INT',
        default_value => 0,
        is_nullable   => 0,
        size          => 11,
    },
    'loadtime',
    {   data_type     => 'DOUBLE',
        default_value => 0,
        is_nullable   => 0,
        size          => 64
    },
);
__PACKAGE__->set_primary_key('path_id');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::LogPath - Table 'log_path'

=head1 COLUMNS

=over 4

=item path_id

INT(11)

NOT NULL, PRIMARY KEY

=item session_id

VARCHAR(72)



=item user_id

INT(11)

NOT NULL

=item path

VARCHAR(255)

NOT NULL

=item get

VARCHAR(255)



=item post

TEXT(65535)



=item time

INT(11)

NOT NULL

=item loadtime

DOUBLE(64)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

