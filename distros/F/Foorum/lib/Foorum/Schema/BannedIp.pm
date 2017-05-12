package Foorum::Schema::BannedIp;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('banned_ip');
__PACKAGE__->add_columns(
    'ip_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'cidr_ip',
    {   data_type     => 'VARCHAR',
        default_value => '',
        is_nullable   => 0,
        size          => 20
    },
    'time',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key('ip_id');

__PACKAGE__->resultset_class('Foorum::ResultSet::BannedIp');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::BannedIp - Table 'banned_ip'

=head1 COLUMNS

=over 4

=item ip_id

INT(11)

NOT NULL, PRIMARY KEY

=item cidr_ip

VARCHAR(20)

NOT NULL

=item time

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

