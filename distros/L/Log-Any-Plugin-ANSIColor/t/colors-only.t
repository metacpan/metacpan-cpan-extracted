use strict;
use warnings;
use Test::More;

use Log::Any::Test;
use Log::Any::Plugin;

use lib './t/lib';
use PluginTest  qw( check_log_colors );

my %colors = (
    trace => 'white on_red',
    warning => 'black on_white',
);

Log::Any::Plugin->add('ANSIColor', %colors);

check_log_colors(%colors);

done_testing;
