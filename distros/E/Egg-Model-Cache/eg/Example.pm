package MyApp::Model::Cache::Example;
use strict;
use warnings;
use base qw/ Egg::Model::Cache::Base /;

our $VERSION= '0.01';

__PACKAGE__->config(
  label_name  => 'cache_name',
  cache_root => MyApp->path_to('cache'),
  namespace  => 'Example',
  );

__PACKAGE__->setup_cache('Cache::FileCache');

1;
