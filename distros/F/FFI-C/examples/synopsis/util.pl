use strict;
use warnings;
use FFI::C::Util qw( perl_to_c take );
use FFI::C::StructDef;
use FFI::Platypus::Memory qw( free );

my $def = FFI::C::StructDef->new(
  members => [
    x => 'uint8',
    y => 'sint64',
  ],
);
my $inst = $def->create;

# initalize members
perl_to_c($inst, { x => 1, y => 2 });

# take ownership
my $ptr = take $inst;

# since we took ownership, we are responsible for freeing the memory:
free $ptr;
