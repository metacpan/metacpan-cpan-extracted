
# Auto generated during CLDR build

use lib 'lib', '../lib';
use Test::More;

use Locales;

diag("Verifying perl and js get_plural_form() behave the same for gv.");

if ( !$ENV{'RELEASE_TESTING'} ) {
    plan 'skip_all' => 'These tests are only run under RELEASE_TESTING.';
}

my $obj = Locales->new('gv') || die "Could not create object for gv: $@";

my @nums = ( 0, 1.6, 2.2, 3.14159, 42.78, 0 .. 256 );

eval 'use JE ()';
plan $@ ? ( 'skip_all' => 'JE.pm required for testing JS/Perl plural behavior tests' ) : ( 'tests' => ( scalar(@nums) * ( 4 + 2 ) ) );
my $js = JE->new();

use File::Slurp;
my $root = '.';    # TODO: make me portable
if ( -d '../share/' ) {
    $root = '..';
}
if ( !-d "$root/share/" ) {
    die "Can not determine share directory.";
}

my @cats = map { "args_$_" } $obj->get_plural_form_categories();
my $cats_args = join( ', ', map { "'$_'" } @cats );

my $jsfile = File::Slurp::read_file("$root/share/functions/$obj->{'locale'}.js") or die "Could not read '$root/share/functions/$obj->{'locale'}.js': $!";

for my $n (@nums) {
    my $res = $js->eval("var X = $jsfile;return X.get_plural_form($n)");
    is_deeply(
        [ $res->[0], $res->[1] ],    # have to do this to stringify JE object properly
        [ $obj->get_plural_form($n) ],
        "perl and js get_plural_form() behave the same. Tag: $obj->{'locale'} Number: $n"
    );
    is( $res->[1], 0, "using special is 0 for $n (no args)" );

    my $res_n = $js->eval("var X = $jsfile;return X.get_plural_form(-$n)");
    is_deeply(
        [ $res_n->[0], $res_n->[1] ],    # have to do this to stringify JE object properly
        [ $obj->get_plural_form("-$n") ],
        "perl and js get_plural_form() behave the same. Tag: $obj->{'locale'} Number: -$n"
    );
    is( $res_n->[1], 0, "using special is 0 for -$n (no args)" );

    my $res_s = $js->eval("var X = $jsfile;return X.get_plural_form($n,$cats_args)");
    is_deeply(
        [ $res_s->[0], $res_s->[1] ],    # have to do this to stringify JE object properly
        [ $obj->get_plural_form( $n, @cats ) ],
        "perl and js get_plural_form() behave the same. Tag: $obj->{'locale'} Number: $n"
    );
    is( $res_s->[1], 0, "using special is 0 for $n (args w/ no spec zero)" );

    if ( 2 == 4 ) {
        my $res_n = $js->eval("var X = $jsfile;return X.get_plural_form($n, $cats_args, 'spec_zeroth')");
        is_deeply(
            [ $res_n->[0], $res_n->[1] ],    # have to do this to stringify JE object properly
            [ $obj->get_plural_form( "$n", @cats, 'spec_zeroth' ) ],
            "perl and js get_plural_form() behave the same. Tag: $obj->{'locale'} Number: $n"
        );
        my $spec_bool = $n == 0 ? 1 : 0;
        is( $res_n->[1], $spec_bool, "using special is $spec_bool for $n (args w/ spec zero)" );
    }

    # TODO: ? too many/too few args and check for carp ?
}

