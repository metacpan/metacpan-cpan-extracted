package Foorum::Schema::Poll;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('poll');
__PACKAGE__->add_columns(
    'poll_id',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    'forum_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'author_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'multi',
    { data_type => 'ENUM', default_value => 0, is_nullable => 0, size => 1 },
    'anonymous',
    { data_type => 'ENUM', default_value => 0, is_nullable => 0, size => 1 },
    'time',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    'duration',
    {   data_type     => 'INT',
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    'vote_no',
    {   data_type     => 'MEDIUMINT',
        default_value => 0,
        is_nullable   => 0,
        size          => 8
    },
    'title',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 1,
        size          => 128,
    },
    'hit',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key('poll_id');

__PACKAGE__->might_have(
    'author' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.author_id' }
);
__PACKAGE__->has_many(
    'options' => 'Foorum::Schema::PollOption',
    { 'foreign.poll_id' => 'self.poll_id' }
);
__PACKAGE__->has_many(
    'results' => 'Foorum::Schema::PollResult',
    { 'foreign.poll_id' => 'self.poll_id' }
);
1;
__END__

=pod

=head1 NAME

Foorum::Schema::Poll - Table 'poll'

=head1 COLUMNS

=over 4

=item poll_id

INT(11)

NOT NULL, PRIMARY KEY

=item forum_id

INT(11)

NOT NULL

=item author_id

INT(11)

NOT NULL

=item multi

ENUM(1)

NOT NULL

=item anonymous

ENUM(1)

NOT NULL

=item time

INT(10)



=item duration

INT(10)



=item vote_no

MEDIUMINT(8)

NOT NULL

=item title

VARCHAR(128)



=item hit

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

