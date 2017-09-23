use strict;
use warnings;
use Test::More;

use Log::Any::Test;
use Log::Any::Plugin;

use lib './t/lib';
use PluginTest  qw( check_log_colors );


my $warning;
local $SIG{__WARN__} = sub { $warning .= shift };

my %colors = (
    trace   => 'white on_red',
    warning => 'black on_white',
);

my %bad = (
    error  => 'pink',   # bad color
    panic  => 'black',  # bad log method
    scream => 'blue',   # bad log method
);

Log::Any::Plugin->add('ANSIColor', %colors, %bad);

like($warning, qr/Unknown logging methods: panic, scream at/,
        "Warned about bad methods");
like($warning, qr/^Invalid color name "pink" for error at/,
        "Warned about bad colors");

check_log_colors(%colors);

done_testing;
