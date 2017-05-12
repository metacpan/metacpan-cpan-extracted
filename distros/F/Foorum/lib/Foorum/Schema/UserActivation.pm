package Foorum::Schema::UserActivation;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('user_activation');
__PACKAGE__->add_columns(
    'user_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'activation_code',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 12,
    },
    'new_email',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 255,
    },
);
__PACKAGE__->set_primary_key('user_id');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::UserActivation - Table 'user_activation'

=head1 COLUMNS

=over 4

=item user_id

INT(11)

NOT NULL, PRIMARY KEY

=item activation_code

VARCHAR(12)



=item new_email

VARCHAR(255)



=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

