package Foorum::Schema::UserForum;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('user_forum');
__PACKAGE__->add_columns(
    'user_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'forum_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'status',
    {   data_type     => 'ENUM',
        default_value => 'user',
        is_nullable   => 0,
        size          => 9
    },
    'time',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key( 'user_id', 'forum_id' );

__PACKAGE__->resultset_class('Foorum::ResultSet::UserForum');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::UserForum - Table 'user_forum'

=head1 COLUMNS

=over 4

=item user_id

INT(11)

NOT NULL, PRIMARY KEY

=item forum_id

INT(11)

NOT NULL, PRIMARY KEY

=item status

ENUM(9)

NOT NULL, DEFAULT VALUE 'user'

=item time

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

