package Foorum::Schema::PollOption;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('poll_option');
__PACKAGE__->add_columns(
    'option_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'poll_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'text',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 255,
    },
    'vote_no',
    {   data_type     => 'MEDIUMINT',
        default_value => 0,
        is_nullable   => 0,
        size          => 8
    },
);
__PACKAGE__->set_primary_key('option_id');

__PACKAGE__->belongs_to(
    'poll' => 'Foorum::Schema::Poll',
    { 'foreign.poll_id' => 'self.poll_id' }
);
__PACKAGE__->has_many(
    'results' => 'Foorum::Schema::PollResult',
    { 'foreign.option_id' => 'self.option_id' }
);
1;
__END__

=pod

=head1 NAME

Foorum::Schema::PollOption - Table 'poll_option'

=head1 COLUMNS

=over 4

=item option_id

INT(11)

NOT NULL, PRIMARY KEY

=item poll_id

INT(11)

NOT NULL

=item text

VARCHAR(255)



=item vote_no

MEDIUMINT(8)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

