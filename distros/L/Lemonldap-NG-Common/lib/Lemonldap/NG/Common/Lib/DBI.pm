package Lemonldap::NG::Common::Lib::DBI;

use strict;
use Exporter 'import';

our $VERSION   = '2.22.2';
our @EXPORT_OK = qw(check_dbh);

# Check if a DBI handle is still valid
# Returns the handle if valid, undef otherwise
# Also cleans up the handle if it's dead (can happen after Patroni failover)
sub check_dbh {
    my ($dbh) = @_;
    return unless $dbh;
    return $dbh if eval { $dbh->ping };

    # Connection is dead, clean up
    eval { $dbh->disconnect };
    return;
}

1;
