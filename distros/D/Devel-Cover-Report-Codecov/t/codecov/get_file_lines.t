use strict;
use warnings FATAL => 'all';
use utf8;

use t::Util;
use Devel::Cover::Report::Codecov;

sub get_file_lines {
    Devel::Cover::Report::Codecov::get_file_lines(@_);
}

subtest basic => sub {
    is get_file_lines('t/data/sample.pl'), 10;
};

done_testing;
