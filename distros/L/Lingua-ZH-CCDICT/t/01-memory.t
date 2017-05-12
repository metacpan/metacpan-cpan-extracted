use strict;
use warnings;

use lib 't/lib';

use SharedTests;

use Lingua::ZH::CCDICT::Storage::InMemory;


my $dict =
    Lingua::ZH::CCDICT->new( storage => 'InMemory',
                           );

SharedTests::run_tests($dict);
