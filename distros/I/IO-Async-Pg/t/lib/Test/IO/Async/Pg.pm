package Test::IO::Async::Pg;

use strict;
use warnings;
use Test2::V0;
use DBI;
use Exporter 'import';

our @EXPORT_OK = qw(
    require_postgres
    skip_without_postgres
    test_dsn
);

sub test_dsn {
    return $ENV{TEST_PG_DSN} // 'postgresql://postgres:test@localhost/test';
}

sub require_postgres {
    my $dsn = test_dsn();
    my $parsed = _dsn_to_dbi($dsn);

    my $dbh = eval {
        DBI->connect(
            $parsed->{dbi_dsn},
            $parsed->{user},
            $parsed->{password},
            { RaiseError => 1, PrintError => 0 }
        );
    };

    if ($@ || !$dbh) {
        skip_all("Cannot connect to PostgreSQL: " . ($@ || DBI->errstr));
    }

    $dbh->disconnect;
    return $dsn;
}

sub skip_without_postgres {
    my $dsn = test_dsn();
    my $parsed = _dsn_to_dbi($dsn);

    my $dbh = eval {
        DBI->connect(
            $parsed->{dbi_dsn},
            $parsed->{user},
            $parsed->{password},
            { RaiseError => 1, PrintError => 0 }
        );
    };

    if ($@ || !$dbh) {
        return;
    }

    $dbh->disconnect;
    return $dsn;
}

# Convert postgresql:// URI to DBI DSN components
sub _dsn_to_dbi {
    my ($uri) = @_;

    # Basic parsing - the real implementation is in IO::Async::Pg::Util
    if ($uri =~ m{^postgres(?:ql)?://(?:([^:]+)(?::([^@]+))?@)?([^:/]+)?(?::(\d+))?/(\w+)}) {
        my ($user, $pass, $host, $port, $db) = ($1, $2, $3, $4, $5);
        $host //= 'localhost';
        $port //= 5432;

        return {
            dbi_dsn  => "dbi:Pg:dbname=$db;host=$host;port=$port",
            user     => $user,
            password => $pass,
        };
    }

    die "Cannot parse DSN: $uri";
}

1;

__END__

=head1 NAME

Test::IO::Async::Pg - Test utilities for IO::Async::Pg

=head1 SYNOPSIS

    use Test::IO::Async::Pg qw(require_postgres);

    require_postgres();  # Skips test if no database

=cut
