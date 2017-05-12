use Test::More;
use I22r::Translate;
use lib 't';
use strict;
use warnings;

I22r::Translate->config(
    timeout => 5,
    'Test::Backend::Reverser' => {
	ENABLED => 1,
    }
    );

my @r = I22r::Translate->translate_list(
    src => 'wx', dest => 'yz', delay => 1,
    text => [ 'text one', 'text two', 'text three', 'text four' ] );
ok(@r == 4);
ok(4 == grep(defined, @r), 'results available for all four inputs' );

Test::Backend::Reverser->config( delay => 3 );

@r = I22r::Translate->translate_list(
    src => 'wx', dest => 'yz',
    text => [ 'text five', 'text six', 'text seven', 'text eight' ] );
ok(1 <= grep(defined, @r), 'results available for some inputs' );
ok(4 > grep(defined, @r), 'results not available for all inputs' );

##################################################################

no warnings 'once';
%I22r::Translate::config = ();
$Test::Backend::Reverser::config = { };

I22r::Translate->config(
    timeout => 5,
    'Test::Backend::Reverser' => {
	ENABLED => 1,
    }
    );

@r = I22r::Translate->translate_list(
    src => 'wx', dest => 'yz', delay => 1,
    text => [ 'text one', 'text two', 'text three', 'text four' ] );
ok(@r == 4);
ok(4 == grep(defined, @r), 'results available for all four inputs' );

Test::Backend::Reverser->config( delay => 3 );

@r = I22r::Translate->translate_list(
    src => 'wx', dest => 'yz',
    text => [ 'text five', 'text six', 'text seven', 'text eight' ] );
ok(1 <= grep(defined, @r), 'results available for some inputs' );
ok(4 > grep(defined, @r), 'results not available for all inputs' );

my @s = I22r::Translate->translate_list(
    src => 'wx', dest => 'yz',
    text => [ 'text nine', 'text ten', 'text eleven', 'text twelve' ],
    timeout => 2 );
ok( 1 <= grep(defined,@s), 'results available for some inputs' );
ok( grep(defined,@r) > grep(defined,@s),
    'results available for fewer inputs' )
    or diag @r+0,@s+0;



done_testing();
