package BeerDB;
use Maypole::Application;
use Class::DBI::Loader::Relationship;

sub debug { $ENV{BEERDB_DEBUG} || 0 }
# This is the sample application.  Change this to the path to your
# database. (or use mysql or something)
use constant DBI_DRIVER => 'SQLite';
use constant DATASOURCE => $ENV{BEERDB_DATASOURCE} || 't/beerdb.db';


BEGIN {
    my $dbi_driver = DBI_DRIVER;
    if ($dbi_driver =~ /^SQLite/) {
        die sprintf "SQLite datasource '%s' not found, correct the path or "
            . "recreate the database by running Makefile.PL", DATASOURCE
            unless -e DATASOURCE;
        eval "require DBD::SQLite";
        if ($@) {
            eval "require DBD::SQLite2" and $dbi_driver = 'SQLite2';
        }
    }
    BeerDB->setup(join ':', "dbi", $dbi_driver, DATASOURCE);
}

# Give it a name.
BeerDB->config->application_name('The Beer Database');

# Change this to the root of the web site for your maypole application.
BeerDB->config->uri_base( $ENV{BEERDB_BASE} || "http://localhost/beerdb/" );

# Change this to the htdoc root for your maypole application.

my @root=  ('t/templates'); 
push @root,$ENV{BEERDB_TEMPLATE_ROOT} if ($ENV{BEERDB_TEMPLATE_ROOT});
BeerDB->config->template_root( [@root] ); 
# Specify the rows per page in search results, lists, etc : 10 is a nice round number
BeerDB->config->rows_per_page(10);

# Handpumps should not show up.
BeerDB->config->display_tables([qw[beer brewery pub style]]);
BeerDB::Brewery->untaint_columns( printable => [qw/name notes url/] );
BeerDB::Style->untaint_columns( printable => [qw/name notes/] );
BeerDB::Beer->untaint_columns(
    printable => [qw/abv name price notes url/],
    integer => [qw/style brewery score/],
    date =>[ qw/tasted/],
);
BeerDB::Pub->untaint_columns(printable => [qw/name notes url/]);

# Required Fields
BeerDB->config->{brewery}{required_cols} = [qw/name/];
BeerDB->config->{style}{required_cols} = [qw/name/];
BeerDB->config->{beer}{required_cols} = [qw/brewery name price/];
BeerDB->config->{pub}{required_cols} = [qw/name/];

BeerDB->config->{loader}->relationship($_) for (
    "a brewery produces beers",
    "a style defines beers",
    "a pub has beers on handpumps");

# For testing classmetadata
sub BeerDB::Beer::classdata :Exported {};
sub BeerDB::Beer::list_columns  { return qw/score name price style brewery url/};

1;
