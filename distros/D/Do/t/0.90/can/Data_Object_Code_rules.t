use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rules

=usage

  my $rules = $code->rules();

=description

The rules method returns consumed rules.

=signature

rules() : ArrayRef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Code';

my $data = Data::Object::Code->new(sub { 1 });

my $rules = $data->rules();

is_deeply $rules->[0], 'Data::Object::Rule::Defined';

ok 1 and done_testing;
