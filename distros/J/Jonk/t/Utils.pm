package t::Utils;
use strict;
use warnings;
use DBI;
use Test::More;

BEGIN {
  eval "use DBD::SQLite";
  plan skip_all => 'needs DBD::SQLite for testing' if $@;
}

sub _get_schema {
    my $dbh   = shift;
    my $table = shift || "job";

    my $driver = $dbh->{Driver}{Name};
    my $sql;
    if ( $driver eq 'mysql' ) {
        $sql = _read_pod('MySQL');
    } elsif ( $driver eq 'Pg' ) {
        $sql = _read_pod('PostgreSQL');
    } elsif ( $driver eq 'SQLite' ) {
        $sql = _read_pod('SQLite');
    } else {
        Carp::croak "this driver unsupport: $driver";
    }
    $sql =~ s/(CREATE\s+TABLE\s+)job/CREATE TABLE $table/;
    $sql;
}

sub _read_pod {
    my $type = shift;

    open my $fh, '<', './lib/Jonk.pm';
    my $read_schema = 0;
    my $schema='';
    while (<$fh>) {
        my $line = $_;
        if ($line =~ /$type/) {
            $read_schema = 1;
            next;
        }
        if ($read_schema && $line =~ /^=head/) {
            $read_schema = 0;
            last;
        }
        if ($read_schema) {
            $schema .= $line;
            next;
        }
    }
    $schema;
}

sub setup {
    my ($class, $table) = @_;
    my $dbh = DBI->connect('dbi:SQLite:');
    $dbh->do(_get_schema($dbh, $table));
    $dbh;
}

sub cleanup {
    my ($class, $dbh, $table) = @_;
    $table ||= "job";
    $dbh->do("DROP TABLE $table");
}

1;

