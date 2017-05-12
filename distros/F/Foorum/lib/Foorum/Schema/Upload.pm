package Foorum::Schema::Upload;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('upload');
__PACKAGE__->add_columns(
    'upload_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'user_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'forum_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'filename',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 36,
    },
    'filesize',
    {   data_type     => 'DOUBLE',
        default_value => undef,
        is_nullable   => 1,
        size          => 64
    },
    'filetype',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 4
    },
);
__PACKAGE__->set_primary_key('upload_id');

__PACKAGE__->resultset_class('Foorum::ResultSet::Upload');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::Upload - Table 'upload'

=head1 COLUMNS

=over 4

=item upload_id

INT(11)

NOT NULL, PRIMARY KEY

=item user_id

INT(11)

NOT NULL

=item forum_id

INT(11)

NOT NULL

=item filename

VARCHAR(36)



=item filesize

DOUBLE(64)



=item filetype

VARCHAR(4)



=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

