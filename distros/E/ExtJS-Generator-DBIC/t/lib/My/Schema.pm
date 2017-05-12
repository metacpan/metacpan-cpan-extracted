package My::Schema;
use base 'DBIx::Class::Schema';
use strict;
use warnings;

__PACKAGE__->load_namespaces;

#__PACKAGE__->register_class('Another', 'My::Schema::Another');
#__PACKAGE__->register_class('Basic', 'My::Schema::Basic');

1;
