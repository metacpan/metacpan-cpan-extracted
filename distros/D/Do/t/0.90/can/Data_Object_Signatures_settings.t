use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

settings

=usage

  my $settings = settings();

=description

The settings function returns the settings for Function::Parameters
configuration.

=signature

settings(Str $arg1, Any @args) : HashRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Signatures';

my $data = 'Data::Object::Signatures';

can_ok $data, 'settings';

ok 1 and done_testing;
