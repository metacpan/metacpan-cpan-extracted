package Foorum::Schema::PollResult;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('poll_result');
__PACKAGE__->add_columns(
    'option_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'poll_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'poster_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'poster_ip',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 32,
    },
);

__PACKAGE__->belongs_to(
    'poll' => 'Foorum::Schema::Poll',
    { 'foreign.poll_id' => 'self.poll_id' }
);
__PACKAGE__->belongs_to(
    'option' => 'Foorum::Schema::PollOption',
    { 'foreign.option_id' => 'self.option_id' }
);
1;
__END__

=pod

=head1 NAME

Foorum::Schema::PollResult - Table 'poll_result'

=head1 COLUMNS

=over 4

=item option_id

INT(11)

NOT NULL

=item poll_id

INT(11)

NOT NULL

=item poster_id

INT(11)

NOT NULL

=item poster_ip

VARCHAR(32)



=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

