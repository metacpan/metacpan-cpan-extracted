package MyApp::Model::DBI::Example;
use strict;
use warnings;
use base qw/ Egg::Model::DBI::Base /;

our $VERSION = '0.01';

# $ENV{DBI_TRACE}= 3;

__PACKAGE__->config(
  default  => 0,
  dsn      => 'dbi:SQLite:dbname=dbfile',
  user     => 'db_user',
  password => 'db_pawword',
  options  => {
    AutoCommit => 1,
    RaiseError => 1,
    PrintError => 0,
    },
  );

1;
