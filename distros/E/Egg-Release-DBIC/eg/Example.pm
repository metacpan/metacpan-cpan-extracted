package MyApp::Model::DBIC::Example;
use strict;
use warnings;
use base qw/ Egg::Model::DBIC::Schema /;

our $VERSION = '0.01';

__PACKAGE__->config(

#  label_name   => 'myschema',
#  label_source => {
#    hoge => 'mymoniker',
#    },

  dsn      => 'dbi:SQLite;dbname=dbfile',
  user     => 'db_user',
  password => 'db_password',
  options  => {
    AutoCommit => 1,
    RaiseError => 1,
    PrintError => 0,
    },

  );

__PACKAGE__->load_classes;

1;
