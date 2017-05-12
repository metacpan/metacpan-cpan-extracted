use strict;
use warnings;

use Test::More tests => 54;
use Test::NoWarnings;
use Test::Exception;

use Math::Util::CalculatedValue;

my $name     = 'Math::Util::CalculatedValue-';
my $desc     = 'Ran for Test';
my $set_by   = 'Test::More';
my $base_amt = 10;

my $cv = Math::Util::CalculatedValue->new({
    name        => $name . ' 1',
    description => $desc,
    set_by      => $set_by,
    base_amount => $base_amt
});

my $cv_op = Math::Util::CalculatedValue->new({
    name        => $name . ' 2',
    description => $desc,
    set_by      => $set_by,
    base_amount => 10
});

my $cv_extra = Math::Util::CalculatedValue->new({
    name        => $name . ' 3',
    description => $desc,
    set_by      => $set_by,
    base_amount => 12
});

my $cv_neg = Math::Util::CalculatedValue->new({
    name        => $name . ' 4',
    description => $desc,
    set_by      => $set_by,
    base_amount => -12
});

$cv->include_adjustment('add', $cv_op);
is($cv->amount, 20, 'Test for add');

is($cv->peek($cv_op->name),          $cv_op, 'peek finds the correct interal object');
is($cv->peek_amount($cv_op->name),   10,     'peek_amount returns the correct amount');
is($cv->peek($cv->name),             $cv,    'peek finds itself');
is($cv->peek('made_up_name'),        undef,  'peek returns undef if it cannot find the object by name');
is($cv->peek_amount('made_up_name'), undef,  'peek_amount returns undef if it cannot find the object by name');

$cv->include_adjustment('subtract', $cv_op);
is($cv->amount, 10, 'Test for subtract');

$cv->include_adjustment('multiply', $cv_op);
is($cv->amount, 100, 'Test for multiply');

$cv->include_adjustment('info', $cv_op);
is($cv->amount, 100, 'Test for info');

$cv->include_adjustment('reset', $cv_op);
is($cv->amount, 10, 'Test for reset');

$cv->include_adjustment('divide', $cv_op);
is($cv->amount, 1, 'Test for divide');

$cv->include_adjustment('exp', $cv_op);
is(sprintf("%.3f", $cv->amount), 22026.466, 'Test for exp');

$cv->include_adjustment('reset', $cv_op);
is($cv->amount, 10, 'Test for reset');

$cv->include_adjustment('log', $cv_op);
is(sprintf("%.3f", $cv->amount), 2.303, 'Test for log');

$cv->include_adjustment('info', $cv_op);
is(sprintf("%.3f", $cv->amount), 2.303, 'Test for info');

my $applied_wrong = Math::Util::CalculatedValue->new({
    name        => $name . '_fake',
    description => $desc,
    set_by      => $set_by,
    base_amount => $base_amt,
});

throws_ok { $cv->include_adjustment('dance', $applied_wrong) } qr/Operation \[dance\] is not supported/,
    'Throws exception when applying with a non-existent operation';
is(sprintf("%.3f", $cv->amount), 2.303, '...which leaves the current value unchanged');
is($cv->peek_amount($name . '_fake'), undef, '...and does not appear in the stack.');
throws_ok { $cv->include_adjustment('multiply', 2) } qr/Supplied adjustment must be type of Math::Util::CalculatedValue/,
    'Throws exception when applying a non CalculatedValue';
is(sprintf("%.3f", $cv->amount), 2.303, '...which leaves the current value unchanged.');

my $excl_calc = Math::Util::CalculatedValue->new({
    name        => 'exclusion',
    description => $desc,
    set_by      => $set_by,
    base_amount => 10
});

my $excl_repl = Math::Util::CalculatedValue->new({
    name        => 'exclusion',
    description => $desc,
    set_by      => $set_by,
    base_amount => 100
});

$cv_op->include_adjustment('multiply', $excl_calc);
is(sprintf("%.3f", $cv->amount), 4.605, 'Adjusting a sub adjustment changes the value wildly');
is($cv->replace_adjustment($excl_repl), 10, 'Able to replace the value we just added');
is(sprintf("%.3f", $cv->amount), 6.908, '...which changes the value wildly');
is($cv->replace_adjustment($excl_calc), 10, 'Can switch all ten back');
is(sprintf("%.3f", $cv->amount), 4.605, '...which puts it back to its previous crazy value.');
throws_ok { $cv->replace_adjustment('exclusion') } qr/Supplied replacement must be type/, 'Trying to replace with a nonCV does not replace anything';

is($cv->exclude_adjustment($excl_calc->name), 10, 'Exclude all 10 applications TO second object');
is(sprintf("%.3f", $cv->amount), 2.303, '...which puts the value back as it was');
is($cv->exclude_adjustment($cv_op->name),     10,               'Exclude all 10 applications OF second object');
is($cv->amount,                               $cv->base_amount, '...which resets the first object to its base value');
is($cv->exclude_adjustment($excl_calc->name), 10,               'Can still exclude all 10 applications TO second object again');
is($cv->amount,                               $cv->base_amount, '...with no change to the value.');

subtest 'cache invalidation' => sub {
    my $top = Math::Util::CalculatedValue->new({
        name        => 'top',
        description => $desc,
        set_by      => $set_by,
        base_amount => 1,
    });
    my $second = Math::Util::CalculatedValue->new({
        name        => 'second',
        description => $desc,
        set_by      => $set_by,
        base_amount => 2,
    });
    my $third = Math::Util::CalculatedValue->new({
        name        => 'third',
        description => $desc,
        set_by      => $set_by,
        base_amount => 3,
    });
    my $fourth = Math::Util::CalculatedValue->new({
        name        => 'fourth',
        description => $desc,
        set_by      => $set_by,
        base_amount => 4,
    });
    my $other_fourth = Math::Util::CalculatedValue->new({
        name        => 'fourth',
        description => $desc,
        set_by      => $set_by,
        base_amount => 2,
    });

    ok(!$top->_verified_cached_value, 'No cache with no amount');
    is($top->amount,                 1, 'top has proper amount');
    is($top->_verified_cached_value, 1, '... which gets cached.');
    ok($top->include_adjustment('subtract', $second), 'Now we subtract the next level');
    ok(!$top->_verified_cached_value, '... which cleared our cache');
    is($top->amount,                    -1, 'top has proper amount');
    is($top->_verified_cached_value,    -1, '... which gets cached.');
    is($second->_verified_cached_value, 2,  '... also on the second level.');
    ok($second->include_adjustment('multiply', $third), 'Now multiply in the third level');
    ok(!$top->_verified_cached_value, '... which causes the top level cache to disappear');
    is($top->amount, -5, '... but still return the proper amount');
    ok($third->include_adjustment('divide', $fourth), 'Now we start dividing by the fourth');
    is($top->amount, -0.5, '... but still return the proper amount');
    ok($top->replace_adjustment($other_fourth), 'So then we replace the fourth from using the top.');
    ok(!$second->_verified_cached_value,        'Which made us lose the cache on the second');
    ok(!$second->_verified_cached_value,        'and the third');
    is($top->amount, -2, '... and gives us the correct amount at the top');
};

$cv = Math::Util::CalculatedValue->new({
    name        => $name . '5',
    description => $desc,
    set_by      => $set_by,
    base_amount => $base_amt,
    minimum     => 50,
    maximum     => 150
});

$cv->include_adjustment('add', $cv_op);
is($cv->amount, 50, 'Test for add and minimum');

$cv->include_adjustment('multiply', $cv_op);
is($cv->amount, 150, 'Test for multiply');

$cv->include_adjustment('reset', $cv_op);
is($cv->amount, 50, 'Test for reset and min');

$cv->include_adjustment('log', $cv_op);
is($cv->amount, 50, 'Test for log minimum');

$cv = Math::Util::CalculatedValue->new({
    name        => $name . '6',
    description => $desc,
    set_by      => $set_by,
    base_amount => $base_amt,
    minimum     => -100,
    maximum     => 100,
    metadata    => 'wow'
});

is($cv->name,        $name . '6', 'Test for name');
is($cv->description, $desc,       'Test for description');
is($cv->minimum,     -100,        'Test for minimum');
is($cv->maximum,     100,         'Test for maximum');
is($cv->set_by,      $set_by,     'Test for set_by');
is($cv->metadata,    'wow',       'Test for metadata');
is($cv->base_amount, $base_amt,   'Test for base_amount');

$cv->include_adjustment('add', $cv_neg);
is($cv->amount, -2, 'Test for add with negative result');

$cv->include_adjustment('absolute', $cv_neg);
is($cv->amount,          12,      'Test for absolute');
is(ref $cv->adjustments, 'ARRAY', 'Adjustments returns array');

my $x = Math::Util::CalculatedValue->new({
    name        => $name . ' 1',
    description => $desc,
    set_by      => $set_by,
});
is($x->base_amount,     0,       'Test for default base_amount');
is(ref $x->adjustments, 'ARRAY', 'default adjustments are type of array');

throws_ok {
    Math::Util::CalculatedValue->new({
        description => $desc,
        set_by      => $set_by,
    });
}
qr/Attribute .* is required/, 'Missing Required Params';

throws_ok {
    $cv->include_adjustment('absolute', {});
}
qr/Supplied adjustment must be type of/, 'must be type of the same PACKAGE';

throws_ok {
    $cv->replace_adjustment({});
}
qr/Supplied replacement must be type/, 'must be type of the same PACKAGE';

throws_ok {
    Math::Util::CalculatedValue->new({
        name        => 'test',
        description => $desc,
        set_by      => $set_by,
        minimum     => 20,
        maximum     => 10
    });
}
qr/Provided maximum \[10\] is less than the provided minimum \[20\]/, 'Mim, Max Check';

