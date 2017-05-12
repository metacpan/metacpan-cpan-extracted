package Foorum::Schema::User;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('user');
__PACKAGE__->add_columns(
    'user_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'username',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 32,
    },
    'password',
    {   data_type     => 'VARCHAR',
        default_value => '000000',
        is_nullable   => 0,
        size          => 32,
    },
    'nickname',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 100,
    },
    'gender',
    {   data_type     => 'ENUM',
        default_value => 'NA',
        is_nullable   => 0,
        size          => 2
    },
    'email',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 255,
    },
    'point',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 8 },
    'register_time',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'register_ip',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 32,
    },
    'last_login_on',
    {   data_type     => 'INT',
        default_value => 0,
        is_nullable   => 1,
        size          => 11,
    },
    'last_login_ip',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 32,
    },
    'login_times',
    {   data_type     => 'MEDIUMINT',
        default_value => 1,
        is_nullable   => 0,
        size          => 8
    },
    'status',
    {   data_type     => 'ENUM',
        default_value => 'unverified',
        is_nullable   => 0,
        size          => 10,
    },
    'threads',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'replies',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'lang',
    {   data_type     => 'CHAR',
        default_value => 'cn',
        is_nullable   => 1,
        size          => 2
    },
    'country',
    {   data_type     => 'CHAR',
        default_value => 'cn',
        is_nullable   => 1,
        size          => 2
    },
    'state_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'city_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key('user_id');
__PACKAGE__->add_unique_constraint( 'email',    ['email'] );
__PACKAGE__->add_unique_constraint( 'username', ['username'] );

__PACKAGE__->might_have(
    'details' => 'Foorum::Schema::UserDetails',
    { 'foreign.user_id' => 'self.user_id' }
);

__PACKAGE__->resultset_class('Foorum::ResultSet::User');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::User - Table 'user'

=head1 COLUMNS

=over 4

=item user_id

INT(11)

NOT NULL, PRIMARY KEY

=item username

VARCHAR(32)

NOT NULL

=item password

VARCHAR(32)

NOT NULL, DEFAULT VALUE '000000'

=item nickname

VARCHAR(100)

NOT NULL

=item gender

ENUM(2)

NOT NULL, DEFAULT VALUE 'NA'

=item email

VARCHAR(255)

NOT NULL

=item point

INT(8)

NOT NULL

=item register_time

INT(11)

NOT NULL

=item register_ip

VARCHAR(32)

NOT NULL

=item last_login_on

INT(11)



=item last_login_ip

VARCHAR(32)



=item login_times

MEDIUMINT(8)

NOT NULL, DEFAULT VALUE '1'

=item status

ENUM(10)

NOT NULL, DEFAULT VALUE 'unverified'

=item threads

INT(11)

NOT NULL

=item replies

INT(11)

NOT NULL

=item lang

CHAR(2)

DEFAULT VALUE 'cn'

=item country

CHAR(2)

DEFAULT VALUE 'cn'

=item state_id

INT(11)

NOT NULL

=item city_id

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

