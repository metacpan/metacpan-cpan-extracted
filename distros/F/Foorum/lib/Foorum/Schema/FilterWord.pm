package Foorum::Schema::FilterWord;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('filter_word');
__PACKAGE__->add_columns(
    'word',
    {   data_type     => 'VARCHAR',
        default_value => undef,
        is_nullable   => 0,
        size          => 64,
    },
    'type',
    {   data_type     => 'ENUM',
        default_value => 'username_reserved',
        is_nullable   => 0,
        size          => 19,
    },
);
__PACKAGE__->set_primary_key( 'word', 'type' );

__PACKAGE__->resultset_class('Foorum::ResultSet::FilterWord');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::FilterWord - Table 'filter_word'

=head1 COLUMNS

=over 4

=item word

VARCHAR(64)

NOT NULL, PRIMARY KEY

=item type

ENUM(19)

NOT NULL, PRIMARY KEY, DEFAULT VALUE 'username_reserved'

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

