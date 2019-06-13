use Test::More;

use Linux::Capabilities;

my $obj = Linux::Capabilities->new;
ok $obj, 'constructed';

done_testing;