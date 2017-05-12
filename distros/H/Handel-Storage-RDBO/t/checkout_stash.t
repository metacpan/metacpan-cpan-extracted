#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 12;

    use_ok('Handel::Test::RDBO::Checkout');
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
&run('Handel::Test::RDBO::Checkout', 'Handel::Checkout::Stash');

sub run {
    my ($subclass, $stashclass) = @_;


    ## Check the default stash creation
    {
        my $checkout = $subclass->new({
            stash => {foo => 'bar'}
        });
        isa_ok($checkout->stash, $stashclass);
        is($checkout->stash->{'foo'}, 'bar', 'stash item is set');
    };


    ## Check the stash parameter
    {
        my $stash = CustomStash->new({
            foo => 'bar'
        });
        my $checkout = Handel::Checkout->new({
            stash => $stash
        });

        isa_ok($checkout->stash, 'CustomStash');
        isa_ok($checkout->stash, 'Handel::Checkout::Stash');
        is($checkout->stash->{'foo'}, 'bar', 'stash item is set');

        $checkout->stash->clear;
        is_deeply($checkout->stash, {}, 'stash is now clear')
    };


    ## Check stash_class
    {
        Handel::Checkout->stash_class('CustomStash');

        my $checkout = Handel::Checkout->new;

        isa_ok($checkout->stash, 'CustomStash');
        isa_ok($checkout->stash, 'Handel::Checkout::Stash');
    };
};


## test for exception when non-hashref is given
{
    try {
        local $ENV{'LANG'} = 'en';
        my $stash = Handel::Checkout::Stash->new([]);

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/not a hash ref/i, 'message contains not a hashref');
    } otherwise {
        fail('Other exception caught');
    };
};


package CustomStash;
use strict;
use warnings;
use base 'Handel::Checkout::Stash';

1;

