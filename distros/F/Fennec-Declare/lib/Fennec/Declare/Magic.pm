package Fennec::Declare::Magic;
use strict;
use warnings;

use Devel::Declare::Interface;
use Devel::Declare::Parser;
use Devel::Declare::Parser::Fennec;

sub import {
    my $class       = shift;
    my $destination = caller;

    enhance( $destination, $_, "fennec" ) for qw/
        tests describe it cases case before_each after_each around_each
        before_all after_all around_all before_case after_case
    /;
}

1;
