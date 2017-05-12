MyApp::Model::DBIC::Example::Moniker;
use strict;
use warnings;

our $VERSION = '0.01';

  __PACKAGE__->load_components("PK::Auto", "Core");
  __PACKAGE__->table("example_table");
  __PACKAGE__->add_columns(
    "id", {
      data_type   => "smallint",
      is_nullable => 0,
      },
    "hoge", {
      data_type     => "character varying",
      default_value => undef,
      is_nullable   => 0,
      },
   );

1;
