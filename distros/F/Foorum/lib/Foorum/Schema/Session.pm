package Foorum::Schema::Session;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('session');
__PACKAGE__->add_columns(
    'id',
    {   data_type     => 'CHAR',
        default_value => '',
        is_nullable   => 0,
        size          => 72
    },
    'session_data',
    {   data_type     => 'TEXT',
        default_value => undef,
        is_nullable   => 1,
        size          => 65535,
    },
    'expires',
    { data_type => 'INT', default_value => 0, is_nullable => 1, size => 11 },
);
__PACKAGE__->set_primary_key('id');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::Session - Table 'session'

=head1 COLUMNS

=over 4

=item id

CHAR(72)

NOT NULL, PRIMARY KEY

=item session_data

TEXT(65535)



=item expires

INT(11)



=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

