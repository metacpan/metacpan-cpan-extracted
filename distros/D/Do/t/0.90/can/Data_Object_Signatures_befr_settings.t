use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

befr_settings

=usage

  my $befr_settings = befr_settings();

=description

The befr_settings function returns the before-keyword configuration.

=signature

befr_settings(Str $arg1, Object $arg2) : (Str, HashRef)

=type

function

=cut

# TESTING

use_ok 'Data::Object::Signatures';

my $data = 'Data::Object::Signatures';

can_ok $data, 'befr_settings';

ok 1 and done_testing;
