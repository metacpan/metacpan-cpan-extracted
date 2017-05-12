use strict;
use warnings;

use Test::More tests => 4;

use Math::Util::CalculatedValue::Validatable;

my $ex = Math::Util::CalculatedValue::Validatable->new({
    name        => 'time_in_days',
    description => 'Counts in days',
    set_by      => 'Me',
    base_amount => 0
});

my $validation_methods = $ex->validation_methods;
is((grep { $_ eq '_validate_all_sub_adjustments' } @$validation_methods), '1', 'correct validation _validate_some_other_errors');
is($ex->initialized_correctly(), 1, 'initialized_correctly');
is($ex->confirm_validity(),      1, 'initialized_correctly');

my @errors = $ex->all_errors();
is(scalar(@errors), 0, 'no error');

1;
