package Foorum::Schema::UserDetails;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('user_details');
__PACKAGE__->add_columns(
    'user_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'qq',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 14,
    },
    'msn',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 64,
    },
    'yahoo',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 64,
    },
    'skype',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 64,
    },
    'gtalk',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 64,
    },
    'homepage',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 255,
    },
    'birthday',
    {   data_type     => 'DATE',
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
);
__PACKAGE__->set_primary_key('user_id');

__PACKAGE__->belongs_to(
    'user' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.user_id' }
);
1;
__END__

=pod

=head1 NAME

Foorum::Schema::UserDetails - Table 'user_details'

=head1 COLUMNS

=over 4

=item user_id

INT(11)

NOT NULL, PRIMARY KEY

=item qq

VARCHAR(14)



=item msn

VARCHAR(64)



=item yahoo

VARCHAR(64)



=item skype

VARCHAR(64)



=item gtalk

VARCHAR(64)



=item homepage

VARCHAR(255)



=item birthday

DATE(10)



=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

