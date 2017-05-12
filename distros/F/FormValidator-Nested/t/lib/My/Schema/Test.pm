package My::Schema::Test;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("test");
__PACKAGE__->add_columns(
  "id",
  { data_type => "TINYINT", default_value => undef, is_nullable => 0, size => 3 },
  "mail",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("unique_mail", ["mail"]);
1;
