package BeerDB;
use lib 'lib'; # where Maypole::Plugin::Authorization lives
use Maypole::Application (Authorization);
#use Class::DBI::Loader::Relationship;

sub debug { $ENV{BEERDB_DEBUG} }
# This is a test application for Maypole::Plugin::Authorization.
use constant DATASOURCE => 't/beerdb.db';

BEGIN {
    my $dbi_driver = 'SQLite';
    die sprintf "SQLite datasource '%s' not found, correct the path or "
        . "recreate the database by running Makefile.PL", DATASOURCE
        unless -e DATASOURCE;
    eval "require DBD::SQLite";
    if ($@) {
        eval "require DBD::SQLite2" and $dbi_driver = 'SQLite2';
    }
    BeerDB->setup(join ':', "dbi", $dbi_driver, DATASOURCE);
}

sub authenticate {
    my ($self, $r) = @_;

    # Allow unrestricted access to frontpage and breweries
    # so we can check Maypole is working before we test our module
    return Maypole::Constants::OK unless $r->model_class;
    return Maypole::Constants::OK if $r->model_class eq 'BeerDB::Brewery';

    # BeerDB::Style is used to test error-handling for a missing user
    return Maypole::Constants::OK if $r->model_class eq 'BeerDB::Style';

    # Simulate authentication of user
    $r->user(BeerDB::Users->retrieve(1));
    
    # Test authorize
    $r->template('no_permission') unless $self->authorize($r);
    return Maypole::Constants::OK;
}

BeerDB->config->application_name('Authorization Test Beer Database');
BeerDB->config->uri_base("http://localhost/beerdb/");

#---------------------------------

# This is the data an Authentication module must supply for us ...
# Tell us where to find the user class:
Maypole::Config->mk_accessors('auth');
BeerDB->config->auth({
    user_class  => 'BeerDB::Users',
});

# And tell us who the user is:
Maypole->mk_accessors('user');

#---------------------------------

# Declare some actions to allow testing of get_authorized classes and
# get_authorized_methods
{
    package BeerDB::Beer;
    sub classes :Exported {}
    sub methods :Exported {}
}

{
    package BeerDB::Style;
    sub classes :Exported {}
    sub methods :Exported {}
}

#---------------------------------

1;
