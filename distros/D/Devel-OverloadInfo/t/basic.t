#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 0.88;

use Devel::OverloadInfo qw(overload_info overload_op_info is_overloaded);

sub MyModule::negate { -$_[0] }

my $num_sub;
BEGIN { $num_sub = sub { 0 } };
{
    package  # hide from PAUSE
        BaseClass;
    use overload (
        '""' => 'stringify',
        bool => 'boolify',
        '0+' => $num_sub,
    );

    sub boolify { 1 }
}

{
    package # hide from PAUSE
        ChildClass;
    use parent -norequire => 'BaseClass';

    use overload (
        neg => \&MyModule::negate,
        fallback => 1,
    );

    sub stringify { "foo" }
}

{
    package # hide from PAUSE
        EmptyOverload;
    use overload;
}

{
    package # hide from PAUSE
        InheritedOnly;
    use parent -norequire => 'BaseClass';
}

{
    package # hide from PAUSE
        NoOverload;

    sub wibble {}
}

for my $class (qw(BaseClass ChildClass EmptyOverload InheritedOnly)) {
    ok is_overloaded($class), "$class is overloaded";
}

for my $class (qw(NoOverload)) {
    ok !is_overloaded($class), "$class is not overloaded";
}

is overload_op_info('BaseClass', 'cmp'), undef,
    'overload_op_info() returns undef for non-overloaded op';

my $boi = overload_info('BaseClass');

# Whether undef fallback exists varies between perl versions
if (my $fallback = delete $boi->{fallback}) {
    is_deeply $fallback, {
        class => 'BaseClass',
        value => undef,
    }, 'BaseClass fallback is undef';
    is_deeply overload_op_info('BaseClass', 'fallback'),
        $fallback,
        "overload_op_info('BaseClass','fallback') matches overload_info()";
}
else {
    is overload_op_info('BaseClass', 'fallback'), undef,
        "overload_op_info('BaseClass','fallback') matches overload_info()";
}

is_deeply $boi,
    {
        '""' => {
            class => 'BaseClass',
            method_name => 'stringify',
        },
        bool => {
            class => 'BaseClass',
            method_name => 'boolify',
            code_class => 'BaseClass',
            code => \&BaseClass::boolify,
            code_name => "BaseClass::boolify",
        },
        '0+' => {
            class => 'BaseClass',
            code => $num_sub,
            code_name => 'main::__ANON__',
        },
    },
    "BaseClass overload info" or note explain $boi;

my $coi = overload_info('ChildClass');

is_deeply $coi,
    {
        fallback => {
            class => 'ChildClass',
            value => 1,
        },
        '""' => {
            class => 'BaseClass',
            method_name => 'stringify',
            code_class => 'ChildClass',
            code => \&ChildClass::stringify,
            code_name => 'ChildClass::stringify',
        },
        bool => {
            class => 'BaseClass',
            method_name => 'boolify',
            code_class => 'BaseClass',
            code => \&BaseClass::boolify,
            code_name => "BaseClass::boolify",
        },
        '0+' => {
            class => 'BaseClass',
            code => $num_sub,
            code_name => 'main::__ANON__',
        },
        neg => {
            class => 'ChildClass',
            code => \&MyModule::negate,
            code_name => 'MyModule::negate',
        },
    },
    "ChildClass overload info" or note explain $coi;

for my $op (sort keys %$coi) {
    is_deeply overload_op_info('ChildClass', $op),
        $coi->{$op},
        "overload_op_info('ChildClass', $op)";
}


is_deeply overload_info('InheritedOnly'),
    overload_info('BaseClass'),
    'InheritedOnly has same overloads as BaseClass';

is overload_op_info('NoOverload', 'fallback'), undef,
    'overload_op_info on non-overloaded class';

is_deeply overload_info('NoOverload'), {},
    'NoOverload has no overloads';

my $eoi = overload_info('EmptyOverload');

# Whether undef fallback exists varies between perl versions
if (my $fallback = delete $eoi->{fallback}) {
    is_deeply $fallback, {
        class => 'EmptyOverload',
        value => undef,
    }, 'EmptyOverload fallback is undef';
}

is_deeply $eoi, {},
    'EmptyOverload has no overloads';

done_testing;
