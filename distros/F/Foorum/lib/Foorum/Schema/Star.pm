package Foorum::Schema::Star;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('star');
__PACKAGE__->add_columns(
    'user_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'object_type',
    {   data_type     => 'VARCHAR',
        default_value => '',
        is_nullable   => 0,
        size          => 12
    },
    'object_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'time',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key( 'user_id', 'object_id', 'object_type' );

__PACKAGE__->resultset_class('Foorum::ResultSet::Star');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::Star - Table 'star'

=head1 COLUMNS

=over 4

=item user_id

INT(11)

NOT NULL, PRIMARY KEY

=item object_type

VARCHAR(12)

NOT NULL, PRIMARY KEY

=item object_id

INT(11)

NOT NULL, PRIMARY KEY

=item time

INT(10)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

