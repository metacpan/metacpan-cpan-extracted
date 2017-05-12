#===============================================================================
#
#  DESCRIPTION:  test for Games::Go::AGA::Parse::Exceptions
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  11/10/2011 09:47:43 AM
#===============================================================================

use 5.008;
use strict;
use warnings;

use Test::More tests => 3;                      # last test to print
use Test::Exception;
use File::Spec;
use Readonly;

# VERSION

use_ok 'Games::Go::AGA::Parse::Exceptions';

eval {
    Games::Go::AGA::Parse::Exception->throw(
        error => 'first error',
    );
};
is $@, "first error", "first OK";

eval {
    Games::Go::AGA::Parse::Exception->throw(
        error       => 'second error',
        filename    => 'a_file',
        line_number => '44',
    );
};
is $@, "second error at line 44 in a_file", "second OK";
