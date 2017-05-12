package Foorum::Schema::UserOnline;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('user_online');
__PACKAGE__->add_columns(
    'sessionid',
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
    'title',
    {   data_type     => 'VARCHAR',
        default_value => '',
        is_nullable   => 0,
        size          => 255
    },
    'start_time',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'last_time',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key('sessionid');

__PACKAGE__->resultset_class('Foorum::ResultSet::UserOnline');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::UserOnline - Table 'user_online'

=head1 COLUMNS

=over 4

=item sessionid

VARCHAR(72)

PRIMARY KEY

=item user_id

INT(11)

NOT NULL

=item path

VARCHAR(255)

NOT NULL

=item title

VARCHAR(255)

NOT NULL

=item start_time

INT(11)

NOT NULL

=item last_time

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

