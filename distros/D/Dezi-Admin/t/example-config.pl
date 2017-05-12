use Dezi::Stats;

my $dbfile   = $ENV{HOME} . '/projects/search_bench/stats.db';
my $invindex = $ENV{HOME} . '/projects/search_bench/dezi.index';

my $stats = Dezi::Stats->new(
    type     => 'DBI',
    dsn      => 'dbi:SQLite:dbname=' . $dbfile,
    username => 'ignored',
    password => 'ignored',
);

# init the db
my $dbh = $stats->conn->dbh;
my $r   = $dbh->do( $stats->schema );
if ( !$r ) {
    die "init sqlite db $dbfile failed: " . $dbh->errstr;
}

{   admin         => { extjs_uri => '//localhost/~karpet/ext-4.1.1a', },
    stats_logger  => $stats,
    admin_class   => 'Dezi::Admin',
    debug         => 1,
    engine_config => { index     => [$invindex], },
}

