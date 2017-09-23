use strict;
use warnings;
use Test::More;

use Log::Any::Test;
use Log::Any::Plugin;

use lib './t/lib';
use PluginTest  qw( check_log_colors );


Log::Any::Plugin->add('ANSIColor');

my %default_colors = do {
    no warnings 'once';
    %Log::Any::Plugin::ANSIColor::default;
};

check_log_colors(%default_colors);

done_testing;
