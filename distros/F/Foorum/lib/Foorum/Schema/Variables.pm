package Foorum::Schema::Variables;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('variables');
__PACKAGE__->add_columns(
    'type',
    {   data_type     => 'ENUM',
        default_value => 'global',
        is_nullable   => 0,
        size          => 6
    },
    'name',
    {   data_type     => 'VARCHAR',
        default_value => '',
        is_nullable   => 0,
        size          => 32
    },
    'value',
    {   data_type     => 'VARCHAR',
        default_value => '',
        is_nullable   => 0,
        size          => 255
    },
);
__PACKAGE__->set_primary_key( 'type', 'name' );

1;
__END__

=pod

=head1 NAME

Foorum::Schema::Variables - Table 'variables'

=head1 COLUMNS

=over 4

=item type

ENUM(6)

NOT NULL, PRIMARY KEY, DEFAULT VALUE 'global'

=item name

VARCHAR(32)

NOT NULL, PRIMARY KEY

=item value

VARCHAR(255)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

