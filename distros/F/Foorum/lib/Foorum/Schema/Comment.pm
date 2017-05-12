package Foorum::Schema::Comment;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('comment');
__PACKAGE__->add_columns(
    'comment_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'reply_to',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'text',
    {   data_type     => 'TEXT',
        default_value => undef,
        is_nullable   => 0,
        size          => 65535,
    },
    'post_on',
    {   data_type     => 'INT',
        default_value => 0,
        is_nullable   => 0,
        size          => 11,
    },
    'update_on',
    {   data_type     => 'INT',
        default_value => 0,
        is_nullable   => 1,
        size          => 11,
    },
    'post_ip',
    {   data_type     => 'VARCHAR',
        default_value => '',
        is_nullable   => 0,
        size          => 32
    },
    'formatter',
    {   data_type     => 'VARCHAR',
        default_value => 'ubb',
        is_nullable   => 0,
        size          => 16,
    },
    'object_type',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 30,
    },
    'object_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'author_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'title',
    {   data_type     => 'VARCHAR',
        default_value => '',
        is_nullable   => 0,
        size          => 255
    },
    'forum_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'upload_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key('comment_id');

# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->might_have(
    'upload' => 'Foorum::Schema::Upload',
    { 'foreign.upload_id' => 'self.upload_id' }
);

__PACKAGE__->resultset_class('Foorum::ResultSet::Comment');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::Comment - Table 'comment'

=head1 COLUMNS

=over 4

=item comment_id

INT(11)

NOT NULL, PRIMARY KEY

=item reply_to

INT(11)

NOT NULL

=item text

TEXT(65535)

NOT NULL

=item post_on

INT(11)

NOT NULL

=item update_on

INT(11)



=item post_ip

VARCHAR(32)

NOT NULL

=item formatter

VARCHAR(16)

NOT NULL, DEFAULT VALUE 'ubb'

=item object_type

VARCHAR(30)

NOT NULL

=item object_id

INT(11)

NOT NULL

=item author_id

INT(11)

NOT NULL

=item title

VARCHAR(255)

NOT NULL

=item forum_id

INT(11)

NOT NULL

=item upload_id

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

