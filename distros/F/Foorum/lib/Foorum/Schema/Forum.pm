package Foorum::Schema::Forum;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('forum');
__PACKAGE__->add_columns(
    'forum_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'forum_code',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 25,
    },
    'name',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 100,
    },
    'description',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 255,
    },
    'forum_type',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 16,
    },
    'policy',
    {   data_type     => 'ENUM',
        default_value => 'public',
        is_nullable   => 0,
        size          => 9
    },
    'total_members',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 8 },
    'total_topics',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'total_replies',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'status',
    {   data_type     => 'ENUM',
        default_value => 'healthy',
        is_nullable   => 0,
        size          => 7,
    },
    'last_post_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key('forum_id');
__PACKAGE__->add_unique_constraint( 'forum_code', ['forum_code'] );

__PACKAGE__->has_many(
    'topics' => 'Foorum::Schema::Topic',
    { 'foreign.forum_id' => 'self.forum_id' }
);

__PACKAGE__->resultset_class('Foorum::ResultSet::Forum');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::Forum - Table 'forum'

=head1 COLUMNS

=over 4

=item forum_id

INT(11)

NOT NULL, PRIMARY KEY

=item forum_code

VARCHAR(25)

NOT NULL

=item name

VARCHAR(100)

NOT NULL

=item description

VARCHAR(255)

NOT NULL

=item forum_type

VARCHAR(16)

NOT NULL

=item policy

ENUM(9)

NOT NULL, DEFAULT VALUE 'public'

=item total_members

INT(8)

NOT NULL

=item total_topics

INT(11)

NOT NULL

=item total_replies

INT(11)

NOT NULL

=item status

ENUM(7)

NOT NULL, DEFAULT VALUE 'healthy'

=item last_post_id

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

