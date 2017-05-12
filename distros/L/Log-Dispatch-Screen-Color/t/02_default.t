use strict;
use warnings;
use Test::More tests => 11;

use IO::Scalar;
use Term::ANSIColor;
use Log::Dispatch::Screen::Color;

my $log = Log::Dispatch::Screen::Color->new(
    name      => 'test',
    min_level => 'debug',
    stderr    => 0,
);

# my @levels = qw( debug info notice warning err error crit critical alert emerg emergency );
run_test('debug');
run_test('info'     , 'blue');
run_test('notice'   , 'green');
run_test('warning'  , 'black' , 'yellow');
run_test('err'      , 'red'   , 'yellow');
run_test('error'    , 'red'   , 'yellow');
run_test('crit'     , 'black' , 'red'   );
run_test('critical' , 'black' , 'red'   );
run_test('alert'    , 'white' , 'red'   , 1);
run_test('emerg'    , 'yellow', 'red'   , 1);
run_test('emergency', 'yellow', 'red'   , 1);


sub run_test {
    my($level, $text, $background, $is_bold) = @_;

    my $prefix = '';
    my $suffix = '';
    if ($is_bold) {
        $prefix .= color('bold');
        $suffix .= color('reset');
    }
    if ($background) {
        $prefix .= color("on_$background");
        $suffix .= color('reset');
    }
    if ($text) {
        $prefix .= color($text);
        $suffix .= color('reset');
    }

    my $out = capture(
        sub {
            $log->log( level => $level, message => $level );
        }
    );
    diag($out);
    is($out, "$prefix$level$suffix", "log method with $level");
}


sub capture {
    my $cb = shift;
    tie *STDOUT, 'IO::Scalar', \my $out;
    $cb->();
    untie *STDOUT;
    $out;
}
