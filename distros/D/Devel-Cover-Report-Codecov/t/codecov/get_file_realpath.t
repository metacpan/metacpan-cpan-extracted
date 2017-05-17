use strict;
use warnings FATAL => 'all';
use utf8;

use Cwd::Guard qw/cwd_guard/;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov;

sub get_file_realpath {
    Devel::Cover::Report::Codecov::get_file_realpath(@_);
}

subtest basic => sub {
    my $guard = cwd_guard('t/data/proj_blib');
    is get_file_realpath('blib/lib/Example/Add.pm'), 'lib/Example/Add.pm';
    is get_file_realpath('lib/Example/Div.pm'), 'lib/Example/Div.pm';
};

done_testing;
