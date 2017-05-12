package Foorum::Schema::LogAction;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('log_action');
__PACKAGE__->add_columns(
    'user_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'action',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 24,
    },
    'object_type',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 12,
    },
    'object_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 1,
        size          => 11
    },
    'time',
    {   data_type     => 'INT',
        default_value => 0,
        is_nullable   => 0,
        size          => 11,
    },
    'text',
    {   data_type     => 'TEXT',
        default_value => undef,
        is_nullable   => 1,
        size          => 65535,
    },
    'forum_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
);

1;
__END__

=pod

=head1 NAME

Foorum::Schema::LogAction - Table 'log_action'

=head1 COLUMNS

=over 4

=item user_id

INT(11)

NOT NULL

=item action

VARCHAR(24)



=item object_type

VARCHAR(12)



=item object_id

INT(11)



=item time

INT(11)

NOT NULL

=item text

TEXT(65535)



=item forum_id

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

