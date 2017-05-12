=head1 NAME

DynGig::Range::Cluster::EZDB - Extends DynGig::Util::EZDB

=cut
package DynGig::Range::Cluster::EZDB;

use base DynGig::Util::EZDB;

use strict;
use warnings;

=head1 SCHEMA
 
 key TEXT NOT NULL,
 value TEXT NOT NULL,
 PRIMARY KEY ( key )

=cut
sub new
{
    DynGig::Util::EZDB->schema
    (
        key   => 'TEXT NOT NULL PRIMARY KEY',
        value => 'TEXT NOT NULL',
    );

    bless DynGig::Util::EZDB::new( @_ ), __PACKAGE__;
}

=head1 METHODS

See base class for additional methods.

=head2 get()

Loads all tables into a HASH. Also see dump().
Returns HASH reference in scalar context.
Returns flattened HASH in list context.

=cut
sub get
{
    my $this = shift;
    my %config = map { $_ => scalar $this->dump( $_ ) } $this->table();

    return wantarray ? %config : \%config;
}

=head1 NOTE

See DynGig::Range::Cluster

=cut

1;

__END__

