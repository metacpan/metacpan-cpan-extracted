package Foorum::Schema::Hit;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('hit');
__PACKAGE__->add_columns(
    'hit_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'object_type',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 12,
    },
    'object_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'hit_new',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'hit_today',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'hit_yesterday',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'hit_weekly',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'hit_monthly',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'hit_all',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'last_update_time',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key('hit_id');

__PACKAGE__->resultset_class('Foorum::ResultSet::Hit');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::Hit - Table 'hit'

=head1 COLUMNS

=over 4

=item hit_id

INT(11)

NOT NULL, PRIMARY KEY

=item object_type

VARCHAR(12)

NOT NULL

=item object_id

INT(11)

NOT NULL

=item hit_new

INT(11)

NOT NULL

=item hit_today

INT(11)

NOT NULL

=item hit_yesterday

INT(11)

NOT NULL

=item hit_weekly

INT(11)

NOT NULL

=item hit_monthly

INT(11)

NOT NULL

=item hit_all

INT(11)

NOT NULL

=item last_update_time

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

