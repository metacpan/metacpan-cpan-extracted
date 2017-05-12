package Foorum::Schema::Stat;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('stat');
__PACKAGE__->add_columns(
    'stat_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'stat_key',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 255,
    },
    'stat_value',
    {   data_type     => 'BIGINT',
        default_value => 0,
        is_nullable   => 0,
        size          => 21
    },
    'date',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key('stat_id');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::Stat - Table 'stat'

=head1 COLUMNS

=over 4

=item stat_id

INT(11)

NOT NULL, PRIMARY KEY

=item stat_key

VARCHAR(255)

NOT NULL

=item stat_value

BIGINT(21)

NOT NULL

=item date

INT(8)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

