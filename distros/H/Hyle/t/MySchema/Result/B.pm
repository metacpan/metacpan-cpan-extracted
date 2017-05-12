package MySchema::Result::B;

use base qw/DBIx::Class::Core/;
__PACKAGE__->table('B');
__PACKAGE__->add_columns(qw/a/);
__PACKAGE__->set_primary_key('a');

 
1;
