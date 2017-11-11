use strict;
use warnings;
use Test::More;

use Jojo::Role ();

my $last_role;
push @Jojo::Role::ON_ROLE_CREATE, sub {
  ($last_role) = @_;
};

eval q{
  package MyRole;
  use Jojo::Role;
};

is $last_role, 'MyRole', 'role create hook was run';

eval q{
  package MyRole2;
  use Jojo::Role;
};

is $last_role, 'MyRole2', 'role create hook was run again';

done_testing;
