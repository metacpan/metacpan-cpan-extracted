=head1 NAME

DynGig::Automata::EZDB::Alert - Extends DynGig::Util::EZDB.

=cut
package DynGig::Automata::EZDB::Alert;

use base DynGig::Util::EZDB;

use warnings;
use strict;

=head1 SCHEMA
 
 key TEXT NOT NULL,
 value BLOB,
 PRIMARY KEY ( key )

=cut
sub new
{
    DynGig::Util::EZDB->schema
    (
        key   => 'TEXT NOT NULL PRIMARY KEY',
        value => 'BLOB',
    );

    bless DynGig::Util::EZDB::new( @_ ), __PACKAGE__;
}

=head1 SYNOPSIS

See B<Util::DynGig::Automata::SQLite> for other methods.

 $db->delete( 'key1' );  ## delete record of 'key1' from all tables

=cut
sub delete  ## delete a key from all tables
{
    my ( $this, $key ) = @_;
    map { my $r = $this->_execute( $_, 'delete_key', $key ) } $this->table();
}

=head1 NOTE

See DynGig::Automata

=cut

1;

__END__
