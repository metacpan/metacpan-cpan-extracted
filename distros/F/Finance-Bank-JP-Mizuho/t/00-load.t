use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Test::More;

BEGIN {
    use_ok 'Finance::Bank::JP::Mizuho';
    use_ok 'Finance::Bank::JP::Mizuho::Account'
}

{
    ok ( Finance::Bank::JP::Mizuho->new, 'new' );
    ok ( Finance::Bank::JP::Mizuho::Account->new, 'new' );
}

done_testing;

