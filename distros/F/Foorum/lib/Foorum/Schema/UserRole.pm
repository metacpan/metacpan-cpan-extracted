package Foorum::Schema::UserRole;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('user_role');
__PACKAGE__->add_columns(
    'user_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'role',
    {   data_type     => 'ENUM',
        default_value => 'user',
        is_nullable   => 1,
        size          => 9
    },
    'field',
    {   data_type     => 'VARCHAR',
        default_value => '',
        is_nullable   => 0,
        size          => 32
    },
);

__PACKAGE__->belongs_to(
    'user' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.user_id' }
);
1;
__END__

=pod

=head1 NAME

Foorum::Schema::UserRole - Table 'user_role'

=head1 COLUMNS

=over 4

=item user_id

INT(11)

NOT NULL

=item role

ENUM(9)

DEFAULT VALUE 'user'

=item field

VARCHAR(32)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

