#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More 'no_plan';
use Lingua::Translate;

# auto misused
{
    my $died = 0;

    eval {

        local $SIG{__DIE__} = sub {
            return if $_[0] !~ m{\A auto \s }xms;
            $died = 1;
        };

        Lingua::Translate->new(
            back_end => 'Google',
            src      => 'auto',
            dest     => 'de',
        );
    };

    ok( $died, 'died on incorrect use of auto src' );
}

# no api key
{
    my $xl8r = Lingua::Translate->new(
        back_end => 'Google',
        src      => 'en',
        dest     => 'de',
    );

    my $died = 0;

    eval {

        local $SIG{__DIE__} = sub {
            return if $_[0] !~ m{ \s API \s key \s }xms;
            $died = 1;
        };

        $xl8r->translate('hello world');
    };

    ok( $died, 'died on omitted api key' );
}

__END__
