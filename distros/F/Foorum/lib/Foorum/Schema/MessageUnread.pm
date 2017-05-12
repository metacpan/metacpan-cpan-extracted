package Foorum::Schema::MessageUnread;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('message_unread');
__PACKAGE__->add_columns(
    'message_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
    'user_id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key( 'message_id', 'user_id' );

1;
__END__

=pod

=head1 NAME

Foorum::Schema::MessageUnread - Table 'message_unread'

=head1 COLUMNS

=over 4

=item message_id

INT(11)

NOT NULL, PRIMARY KEY

=item user_id

INT(11)

NOT NULL, PRIMARY KEY

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

