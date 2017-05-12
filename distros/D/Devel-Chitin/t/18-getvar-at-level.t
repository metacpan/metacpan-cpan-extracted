use strict;
use warnings;

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
use Devel::Chitin::GetVarAtLevel;

run_test(
    28,
    sub {
        our $our_var = 'ourvar';
        no strict 'vars';
        no warnings 'once';
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
            28;
        };
        $test_vars->('arg1','arg2');
    },
    \&Devel::Chitin::GetVarAtLevelTest::do_test_vars,
    'done',
);

package Devel::Chitin::GetVarAtLevelTest;
sub do_test_vars {
    my $db = shift;

    is_var($db, 0, '$version', v1.2.3, 'Get value of version variable');
    is_var($db, 0, '$x', 'hello', 'Get value of $x inside test_vars');
    is_var($db, 1, '$x', 1, 'Get value of $x one level up');
    is_var($db, 0, '$y', 2, 'Get value of $y inside test_vars');
    is_var($db, 1, '$y', 2, 'Get value of $y one level up');
    is_var($db, 0, '$z',
            { one => 1, two => 2 },
            'Get value of $z inside test_vars');
    is_var($db, 1, '$z', undef, '$z is not available one level up');

    is_var($db, 0, '$our_var', 'ourvar', 'Get value of $our_var inside test_vars');
    is_var($db, 1, '$our_var', 'ourvar', 'Get value of $our_var one level up');
    is_var($db, 0, '@bare_array',
            ['barevar','barevar'],
            'Get value of bare pkg var @bare_array inside test_vars');
    is_var($db, 1,'@bare_array',
            ['barevar','barevar'],
            'Get value of bare pkg var @bare_array one level up');
    is_var($db, 0, '$bare_array[1]',
            'barevar',
            'Get value of bare package var element $bare_array[1]');

    is_var($db, 0, '%bare_hash',
            { key1 => 1, key2 => 2 },
            'Get value of bare package var %bare_hash inside test_vars');
    is_var($db, 1, '$bare_hash{key1}',
            1,
            'Get value of bare package var element $bare_hash{key1}');

    is_var($db, 0, '$Other::Package::variable', 'pkgvar',
        'Get value of pkg global $Other::Package::variable inside test_vars');
    is_var($db, 1,'$Other::Package::variable', 'pkgvar',
            'Get value of pkg global $Other::Package::variable one level up');

    is_var($db, 0, '@my_list', [ 0,1,2 ], 'Get value of my var @my_list inside test_vars');

    is_var($db, 0, '$my_list[1]', 1, 'Get value of $my_list[1]');
    is_var($db, 0, '$my_list[$one]', 1, 'Get value of $my_list[$one]');
    is_var($db, 0, '@my_list[1, $two]', [1, 2], 'Get value of my var @my_list[1, $two]');
    is_var($db, 0, '@my_list[$zero..3]', [0,1,2,undef],
            'Get value of my var @my_list[$zero..3]');

    is_var($db, 0, '$my_hash{1}', 'one', 'Get value of $my_hash{1}');
    is_var($db, 0, '@my_hash{1,2}', ['one','two'],
            'Get value of @my_hash{1,2}');
    is_var($db, 0, '@my_hash{$one,2}', ['one','two'],
            'Get value of @my_hash{$one,2}');
    is_var($db, 0, '@my_hash{@my_list, 2}',
            [undef,'one','two','two'],
            'Get value of @my_hash{@my_list,2}');
    is_var($db, 0, '@my_hash{$one,"2"}', ['one','two'],
            'Get value of @my_hash{"1","2"}');
    is_var($db, 0, '@my_hash{qw( 1 2 )}', ['one','two'],
            'Get value of @my_hash{$one,2}');

    is_var($db, 0, '@_', ['arg1','arg2'], 'Get @_ inside test_vars');
}

sub is_var {
    my($db, $level, $varname, $expected, $msg) = @_;
    my $got = $db->get_var_at_level($varname, $level);
    if (ref $expected) {
        Test::More::is_deeply($got, $expected, $msg);
    } else {
        Test::More::is($got, $expected, $msg);
    }
}

