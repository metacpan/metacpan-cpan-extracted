use Carp;
use DBI;
use DBD::SQLite;
use File::Temp qw( tempfile tempdir );
use Dezi::Bot::Queue::DBI;
use Dezi::Bot::Handler::FileCacher;

# init temp db
my ( undef, $dbfile ) = tempfile();
$dbfile = $ENV{DEZI_BOT_DBFILE} if $ENV{DEZI_BOT_DBFILE};
my $dsn = 'dbi:SQLite:dbname=' . $dbfile;
my $dbh = DBI->connect($dsn);

# init the schema
my $r;
$r = $dbh->do( Dezi::Bot::Queue::DBI->schema );
if ( !$r ) {
    croak "init queue table in $dbfile failed: " . $dbh->errstr;
}
$r = $dbh->do( Dezi::Bot::Handler::FileCacher->schema );
if ( !$r ) {
    croak "init filecache table in $dbfile failed: " . $dbh->errstr;
}

my $tmpdir = tempdir( CLEANUP => 1 );
my $cachedir = tempdir();    # don't clean up

warn "cachedir=$cachedir\n";

my $config = {
    handler_class  => 'Dezi::Bot::Handler::FileCacher',
    handler_config => {
        root_dir => $cachedir,
        dsn      => $dsn,
        username => 'ignored',
        password => 'ignored',
    },
    spider_config => {
        debug      => $ENV{PERL_DEBUG},
        email      => 'bot-test@dezi.org',
        file_rules => [
            'filename contains \?', # skip any link with query params attached
            'pathname is /~karpet/',    # skip root
        ],
        delay => 0,                     # CHANGE THIS! for real servers
    },
    queue_config => {
        type     => 'DBI',
        dsn      => $dsn,
        username => 'ignored',
        password => 'ignored',
    },
    cache_config => {
        driver    => 'File',
        root_dir  => $tmpdir,
        namespace => 'dezibot',
    },
};
