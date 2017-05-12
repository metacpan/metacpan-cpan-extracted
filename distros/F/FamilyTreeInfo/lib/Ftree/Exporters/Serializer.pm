package Ftree::Exporters::Serializer;
use strict;
use warnings;
use version; our $VERSION = qv('2.3.41');
use Storable;
use Params::Validate qw(:all);
use Sub::Exporter -setup => { exports => [ qw(export) ] };

sub export {
  my ($filename, $family_tree_data) = validate_pos(@_, {type => SCALAR}, {type => HASHREF});
  Storable::nstore $family_tree_data, $filename;
}

1;
