use strict;
use warnings;
use Test::More;
use t::lib::MyExceptions;

eval {
    OverwriteAsString->throw('tar');
};

my $E = $@;
is "$E", 'OverwriteAsString: tar';

done_testing;
