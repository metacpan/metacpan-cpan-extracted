use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

morphs

=usage

  my $morphs = $self->morphs('parent');

=description

Registers columns neccessary for polymorphism and returns the Column object set.

=signature

morphs(Str $name) : [Column]

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Table::Helpers;

can_ok "Doodle::Table::Helpers", "morphs";

my $d = Doodle->new;
my $t = $d->table('users');
my $x = $t->morphs('profile');

my $profile_type = $x->[0];
my $profile_fkey = $x->[1];

is $profile_type->name, 'profile_type';
is $profile_type->type, 'string';
isa_ok $profile_type, 'Doodle::Column';

is $profile_fkey->name, 'profile_fkey';
is $profile_fkey->type, 'integer';
isa_ok $profile_fkey, 'Doodle::Column';

ok 1 and done_testing;
