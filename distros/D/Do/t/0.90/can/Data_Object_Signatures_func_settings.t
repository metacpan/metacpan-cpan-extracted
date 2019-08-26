use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

func_settings

=usage

  my $func_settings = func_settings();

=description

The func_settings function returns the fun-keyword configuration.

=signature

func_settings(Str $arg1, Object $arg2) : (Str, HashRef)

=type

function

=cut

# TESTING

use_ok 'Data::Object::Signatures';

my $data = 'Data::Object::Signatures';

can_ok $data, 'func_settings';

ok 1 and done_testing;
