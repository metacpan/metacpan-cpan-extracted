package Foorum::Schema::Message;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('message');
__PACKAGE__->add_columns(
    'message_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'from_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'to_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'title',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 255,
    },
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
    'post_ip',
    {   data_type     => 'VARCHAR',
        default_value => '',
        is_nullable   => 0,
        size          => 32
    },
    'from_status',
    {   data_type     => 'ENUM',
        default_value => 'open',
        is_nullable   => 0,
        size          => 7
    },
    'to_status',
    {   data_type     => 'ENUM',
        default_value => 'open',
        is_nullable   => 0,
        size          => 7
    },
);
__PACKAGE__->set_primary_key('message_id');

__PACKAGE__->has_one(
    'sender' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.from_id' }
);
__PACKAGE__->has_one(
    'recipient' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.to_id' }
);

__PACKAGE__->resultset_class('Foorum::ResultSet::Message');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::Message - Table 'message'

=head1 COLUMNS

=over 4

=item message_id

INT(11)

NOT NULL, PRIMARY KEY

=item from_id

INT(11)

NOT NULL

=item to_id

INT(11)

NOT NULL

=item title

VARCHAR(255)

NOT NULL

=item text

TEXT(65535)

NOT NULL

=item post_on

INT(11)

NOT NULL

=item post_ip

VARCHAR(32)

NOT NULL

=item from_status

ENUM(7)

NOT NULL, DEFAULT VALUE 'open'

=item to_status

ENUM(7)

NOT NULL, DEFAULT VALUE 'open'

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

