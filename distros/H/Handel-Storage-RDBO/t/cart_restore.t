#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 7;

    use_ok('Handel::Test::RDBO::Cart');
    use_ok('Handel::Test::RDBO::Cart::Item');
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
&run('Handel::Test::RDBO::Cart', 'Handel::Test::RDBO::Cart::Item', 1);

sub run {
    my ($subclass) = @_;


    ## test for Handel::Exception::Argument where first param is not a hashref
    ## or Handle::Cart subclass
    {
        try {
            local $ENV{'LANG'} = 'en';
            $subclass->restore(id => '1234');

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('Argument exception thrown');
            like(shift, qr/not a hash/i, 'no a hash ref in message');
        } otherwise {
            fail('Other exception thrown');
        };
    };


    ## test for Handel::Exception::Argument where first param is not a hashref
    ## or Handle::Cart::Item subclass
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $fakeitem = bless {}, 'FakeItem';
            $subclass->restore($fakeitem);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('Argument exception thrown');
            like(shift, qr/not a hash/i, 'no a hash ref in message');
        } otherwise {
            fail('Other exception thrown');
        };
    };
};
