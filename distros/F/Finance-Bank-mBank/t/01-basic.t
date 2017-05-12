#!perl -T

use Test::More tests => 9;
use Test::Exception;

use Finance::Bank::mBank;

{
    my $b;
    lives_ok {
        $b = Finance::Bank::mBank->new()
    } "No params? OK";
    
    lives_ok {
        $b = Finance::Bank::mBank->new( userid => 111, password => 'aaa' )
    } "userid and password are accepted";

    is( $b->userid, 111);
    is( $b->password, 'aaa');
    ok(!$b->_is_logged_on);

    lives_ok {
        $b = Finance::Bank::mBank->new({ userid => 112, password => 'aab' })
    } "userid and password are accepted also as a hashref";

    is( $b->userid, 112);
    is( $b->password, 'aab');
    ok(!$b->_is_logged_on);
    
}

