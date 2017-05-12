package Foorum::Schema::UserSettings;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('user_settings');
__PACKAGE__->add_columns(
    'user_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'type',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 48,
    },
    'value',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 48,
    },
);
__PACKAGE__->set_primary_key( 'user_id', 'type' );

1;
__END__

=pod

=head1 NAME

Foorum::Schema::UserSettings - Table 'user_settings'

=head1 COLUMNS

=over 4

=item user_id

INT(11)

NOT NULL, PRIMARY KEY

=item type

VARCHAR(48)

NOT NULL, PRIMARY KEY

=item value

VARCHAR(48)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

