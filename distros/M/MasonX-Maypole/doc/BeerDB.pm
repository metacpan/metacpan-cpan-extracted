package BeerDB;
use warnings;
use strict;

use Class::DBI::Loader::Relationship;

use MasonX::Maypole;
use base 'MasonX::Maypole';

BeerDB->setup( 'dbi:mysql:BeerDB', 
               'beerdbuser',
               'password',
               );

BeerDB->config->{view}           = 'MasonX::Maypole::View';
BeerDB->config->{template_root}  = '/home/beerdb/www/www/htdocs';
BeerDB->config->{uri_base}       = '/';
BeerDB->config->{rows_per_page}  = 10;
BeerDB->config->{display_tables} = [ qw( beer brewery pub style ) ];
BeerDB->config->{application_name} = 'The Beer Database';

BeerDB->config->masonx->{comp_root}  = [ [ factory => '/usr/local/www/maypole/factory' ] ];
BeerDB->config->masonx->{data_dir}   = '/home/beerdb/www/www/mdata/maypole';
BeerDB->config->masonx->{in_package} = 'BeerDB::TestApp';

BeerDB::Brewery->untaint_columns( printable => [qw/name notes url/] );

BeerDB::Style->untaint_columns( printable => [qw/name notes/] );

BeerDB::Beer->untaint_columns(
    printable => [qw/abv name price notes/],
    integer => [qw/style brewery score/],
    date => [ qw/date/],
);

BeerDB->config->{loader}->relationship($_) for (
    "a brewery produces beers",
    "a style defines beers",
    "a pub has beers on handpumps");

1;
