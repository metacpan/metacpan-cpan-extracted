package BeerDB;
use Maypole::Application;
use Class::DBI::Loader::Relationship;

sub debug { $ENV{BEERDB_DEBUG} || 0 }
# This is the sample application.  Change this to the path to your
# database. (or use mysql or something)
use constant DBI_DRIVER => 'SQLite';
use constant DATASOURCE => $ENV{BEERDB_DATASOURCE} || 't/beerdb.db';

BeerDB->config->model('BeerDB::Base'); 

BEGIN {
    my $dbi_driver = DBI_DRIVER;
    if ($dbi_driver =~ /^SQLite/) {
	unless -e (DATASOURCE) {
	    die sprintf("SQLite datasource '%s' not found, correct the path or recreate the database by running Makefile.PL", DATASOURCE), "\n";
	}            
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

# Let TT templates recursively include  themselves
BeerDB->config->{view_options} = { RECURSION => 1, };

# Handpumps should not show up.
BeerDB->config->display_tables([qw[beer brewery pub style drinker pint person]]);
# Access handpumps if want
BeerDB->config->ok_tables([ @{BeerDB->config->display_tables}, qw[handpump]]);

BeerDB::Brewery->untaint_columns( printable => [qw/name notes url/] );
BeerDB::Style->untaint_columns( printable => [qw/name notes/] );
BeerDB::Beer->untaint_columns(
    printable => [qw/abv name price notes/],
    integer => [qw/style brewery score/],
    date =>[ qw/tasted/],
);
BeerDB::Pub->untaint_columns(printable => [qw/name notes url/]);
BeerDB::Drinker->untaint_columns( printable => [qw/handle created/] );
BeerDB::Pint->untaint_columns( printable => [qw/date_and_time/]);


# Required Fields
BeerDB->config->{brewery}{required_cols} = [qw/name/];
BeerDB->config->{style}{required_cols} = [qw/name/];
BeerDB->config->{beer}{required_cols} = [qw/brewery name price/];
BeerDB->config->{pub}{required_cols} = [qw/name/];
BeerDB->config->{drinker}{required_cols} = [qw/handle person/];
BeerDB->config->{pint}{required_cols} = [qw/drinker handpump/]; 
BeerDB->config->{person}{required_cols} = [qw/first_name sur_name dob email/];

# Columns to display 
sub BeerDB::Handpump::display_columns { qw/pub beer/ }

BeerDB->config->{loader}->relationship($_) for (
    "a brewery produces beers",
    "a style defines beers",
    "a pub has beers on handpumps",
    "a handpump defines pints",
    "a drinker drinks pints",);

# For testing classmetadata
#sub BeerDB::Beer::classdata :Exported {};
sub BeerDB::Beer::list_columns  { return qw/score name price style brewery/};

sub BeerDB::Handpump::stringify_self { 
	my $self = shift; 
	return $self->beer . " @ " . $self->pub;
}


1;
