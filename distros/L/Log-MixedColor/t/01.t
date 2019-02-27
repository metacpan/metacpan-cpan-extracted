use strict;
use warnings;
use 5.10.0;

use Test::More tests => 21;
use Test::Output;
use Test::Trap;
#use lib 'lib';
use Log::MixedColor;
use Term::ANSIColor;

my $log = Log::MixedColor->new;
my $msg = 'this is a '.$log->q('test').' message';

# Testing info logging
my $info_str = color('green').'Info: this is a '.color('reset').color('black on_white').'test'.color('reset').color('green').' message'.color('reset')."\n";

stdout_is( sub { $log->info($msg) }, 
           '', 
           'info message with a quote - verbose and debug off' );

$log->verbose(1);
stdout_is( sub { $log->info_msg($msg) }, 
           $info_str, 
           'info_msg message with a quote - verbose on' );

$log->verbose(0);
$log->debug(1);
stdout_is( sub { $log->info_msg($msg) }, 
           $info_str, 
           'info_msg message with a quote - debug on' );

$log->verbose(1);
stdout_is( sub { $log->info($msg) }, 
           $info_str, 
           'info message with a quote - verbose and debug on' );

# Changing some defaults for info logging
my ( $c1, $c2, $c3, $c4 ) = ( color('green'), color('blue'), color('black on_white'), color('white on_black') );
for( $info_str ){
    s/Info:/For your info -/;
    s/\Q$c1\E/$c2/g;
    s/\Q$c3\E/$c4/g;
}
$log->info_prefix('For your info -');
$log->info_color( 'blue' );
$log->info_quote_color( 'white on_black' );
stdout_is( sub { $log->info($msg) }, 
           $info_str, 
           'info message with different colours and prefix' );

# Testing debug logging
my $dmsg_str = color('magenta').'Debug: this is a '.color('reset').color('blue').'test'.color('reset').color('magenta').' message'.color('reset')."\n";
$log->verbose(0);
$log->debug(0);

stdout_is( sub { $log->dmsg($msg) }, 
           '', 
           'dmsg message with a quote - verbose and debug off' );

$log->verbose(1);
stdout_is( sub { $log->debug_msg($msg) }, 
           '', 
           'debug_msg message with a quote - verbose on' );

$log->verbose(0);
$log->debug(1);
stdout_is( sub { $log->debug_msg($msg) }, 
           $dmsg_str, 
           'debug_msg message with a quote - debug on' );

$log->verbose(1);
stdout_is( sub { $log->dmsg($msg) }, 
           $dmsg_str, 
           'dmsg message with a quote - verbose and debug on' );

# Changing some defaults for debug logging
( $c1, $c2, $c3, $c4 ) = ( color('magenta'), color('yellow'), color('blue'), color('white on_black') );
for( $dmsg_str ){
    s/Debug:/Low level detail -/;
    s/\Q$c1\E/$c2/g;
    s/\Q$c3\E/$c4/g;
}
$log->debug_prefix('Low level detail -');
$log->debug_color( 'yellow' );
$log->debug_quote_color( 'white on_black' );
stdout_is( sub { $log->debug_msg($msg) }, 
           $dmsg_str, 
           'debug message with different colours and prefix' );

# Testing error logging
my $err_str = "\n".color('red').'Error: this is a '.color('reset').color('yellow').'test'.color('reset').color('red').' message!'.color('reset')."\n\n";
$log->verbose(0);
$log->debug(0);

stderr_is( sub { $log->err($msg) }, 
           $err_str, 
           'err message with a quote - verbose and debug off' );

$log->verbose(1);
stderr_is( sub { $log->err_msg($msg) }, 
           $err_str, 
           'err_msg message with a quote - verbose on' );

$log->verbose(0);
$log->debug(1);
stderr_is( sub { $log->err_msg($msg) }, 
           $err_str, 
           'err_msg message with a quote - debug on' );

$log->verbose(1);
stderr_is( sub { $log->err($msg) }, 
           $err_str, 
           'err message with a quote - verbose and debug on' );

# Changing some defaults for error logging
( $c1, $c2, $c3, $c4 ) = ( color('red'), color('blue'), color('yellow'), color('white on_black') );
for( $err_str ){
    s/Error:/Houston we have a problem -/;
    s/\Q$c1\E/$c2/g;
    s/\Q$c3\E/$c4/g;
}
$log->err_prefix('Houston we have a problem -');
$log->err_color( 'blue' );
$log->err_quote_color( 'white on_black' );
stderr_is( sub { $log->err_msg($msg) }, 
           $err_str, 
           'error message with different colours and prefix' );

# Testing fatal error logging
my @r = trap { $log->fatal($msg) };
is ( $trap->exit, 1, 'Fatal error exiting with 1' );
is ( $trap->stdout, '', 'Fatal error expecting no STDOUT' );
is ( $trap->stderr, $err_str, 'Fatal error on STDERR' );

@r = trap { $log->fatal_err($msg, 2) };
is ( $trap->exit, 2, 'Fatal error exiting with 2' );
is ( $trap->stdout, '', 'Fatal error expecting no STDOUT' );
is ( $trap->stderr, $err_str, 'Fatal error on STDERR' );
