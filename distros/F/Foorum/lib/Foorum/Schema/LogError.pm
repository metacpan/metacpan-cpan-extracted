package Foorum::Schema::LogError;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('log_error');
__PACKAGE__->add_columns(
    'error_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'level',
    {   data_type     => 'SMALLINT',
        default_value => 1,
        is_nullable   => 0,
        size          => 1
    },
    'text',
    {   data_type     => 'TEXT',
        default_value => undef,
        is_nullable   => 0,
        size          => 65535,
    },
    'time',
    {   data_type     => 'INT',
        default_value => 0,
        is_nullable   => 0,
        size          => 11,
    },
);
__PACKAGE__->set_primary_key('error_id');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::LogError - Table 'log_error'

=head1 COLUMNS

=over 4

=item error_id

INT(11)

NOT NULL, PRIMARY KEY

=item level

SMALLINT(1)

NOT NULL, DEFAULT VALUE '1'

=item text

TEXT(65535)

NOT NULL

=item time

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

