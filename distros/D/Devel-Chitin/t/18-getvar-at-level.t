use Test2::V0;
no warnings qw(void once);
no strict 'vars';
use lib 't/lib';
use TestHelper qw(is_var_at_level ok_location);

our $our_var = 'ourvar';
@bare_array = ('barevar', 'barevar');
%bare_hash = ( key1 => 1, key2 => 2 );
use strict 'vars';
$Other::Package::variable = 'pkgvar';
my $x = 1;
my $y = 2;
my $test_vars = sub {
    my $x = 'hello',
    my $z = { one => 1, two => 2 };
    my $zero = 0;
    my $one = 1;
    my $two = 2;
    my @my_list = (0,1,2);
    my %my_hash = (1 => 'one', 2 => 'two', 3 => 'three');
    my $version = v1.2.3;
    $DB::single=1;
    24;
};
$test_vars->('arg1','arg2');

sub __tests__ {
    plan tests => 28;

    is_var_at_level('$version', 0, v1.2.3, 'Get value of version variable');
    is_var_at_level('$x', 0, 'hello', 'Get value of $x inside test_vars');
    is_var_at_level('$x', 1, 1, 'Get value of $x one level up');
    is_var_at_level('$y', 0, 2, 'Get value of $y inside test_vars');
    is_var_at_level('$y', 1, 2, 'Get value of $y one level up');
    is_var_at_level('$z', 0,
            { one => 1, two => 2 },
            'Get value of $z inside test_vars');
    is_var_at_level('$z', 1, undef, '$z is not available one level up');

    is_var_at_level('$our_var', 1, 'ourvar', 'Get value of $our_var inside test_vars');
    is_var_at_level('$our_var', 1, 'ourvar', 'Get value of $our_var one level up');
    is_var_at_level('@bare_array', 0,
            ['barevar','barevar'],
            'Get value of bare pkg var @bare_array inside test_vars');
    is_var_at_level('@bare_array', 1,
            ['barevar','barevar'],
            'Get value of bare pkg var @bare_array one level up');
    is_var_at_level('$bare_array[1]', 0,
            'barevar',
            'Get value of bare package var element $bare_array[1]');

    is_var_at_level('%bare_hash', 0,
            { key1 => 1, key2 => 2 },
            'Get value of bare package var %bare_hash inside test_vars');
    is_var_at_level('$bare_hash{key1}', 1,
            1,
            'Get value of bare package var element $bare_hash{key1}');

    is_var_at_level('$Other::Package::variable', 0, 'pkgvar',
        'Get value of pkg global $Other::Package::variable inside test_vars');
    is_var_at_level('$Other::Package::variable', 1, 'pkgvar',
            'Get value of pkg global $Other::Package::variable one level up');

    is_var_at_level('@my_list', 0, [ 0,1,2 ], 'Get value of my var @my_list inside test_vars');

    is_var_at_level('$my_list[1]', 0, 1, 'Get value of $my_list[1]');
    is_var_at_level('$my_list[$one]', 0, 1, 'Get value of $my_list[$one]');
    is_var_at_level('@my_list[1, $two]', 0, [1, 2], 'Get value of my var @my_list[1, $two]');
    is_var_at_level('@my_list[$zero..3]', 0, [0,1,2,undef],
            'Get value of my var @my_list[$zero..3]');

    is_var_at_level('$my_hash{1}', 0, 'one', 'Get value of $my_hash{1}');
    is_var_at_level('@my_hash{1,2}', 0, ['one','two'],
            'Get value of @my_hash{1,2}');
    is_var_at_level('@my_hash{$one,2}', 0, ['one','two'],
            'Get value of @my_hash{$one,2}');
    is_var_at_level('@my_hash{@my_list, 2}', 0,
            [undef,'one','two','two'],
            'Get value of @my_hash{@my_list,2}');
    is_var_at_level('@my_hash{$one,"2"}', 0, ['one','two'],
            'Get value of @my_hash{"1","2"}');
    is_var_at_level('@my_hash{qw( 1 2 )}', 0, ['one','two'],
            'Get value of @my_hash{$one,2}');

    is_var_at_level('@_', 0, ['arg1','arg2'], 'Get @_ inside test_vars');
}

