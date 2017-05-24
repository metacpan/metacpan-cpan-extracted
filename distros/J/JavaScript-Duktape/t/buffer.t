use lib './lib';
use strict;
use warnings;
use utf8;
use Encode;
use Data::Dumper;

use JavaScript::Duktape;
use Test::More;

subtest 'incoming buffer with raw data' => sub {
    my $js = JavaScript::Duktape->new;

    my $str = 'как дела';
    my $bytes = Encode::encode( 'UTF-8', $str );

    $js->set(
        load => sub {
            return bless( \$bytes => 'JavaScript::Duktape::Buffer' );
        }
    );

    my $ret = $js->eval(q{
        load().length;
    });

    is $ret, length($bytes);
};

subtest 'return buffer with raw data' => sub {
    my $js = JavaScript::Duktape->new;

    my $bytes = "\0\1\2";

    $js->set(
        load => sub {
            return bless( \$bytes => 'JavaScript::Duktape::Buffer' );
        }
    );

    my $ret = $js->eval(q{
        load();
    });

    is $ret, $bytes;
    is length($ret), 3;
};

subtest 'return buffer with large data' => sub {
    my $js = JavaScript::Duktape->new;

    my $bytes = "\0" x 10_000_000;

    $js->set(
        load => sub {
            return bless( \$bytes => 'JavaScript::Duktape::Buffer' );
        }
    );

    my $ret = $js->eval(q{
        load();
    });

    is $ret, $bytes;
    is length($ret), length($bytes);
};

subtest 'return buffer with utf8 data' => sub {
    my $js = JavaScript::Duktape->new;

    my $str = 'как дела';
    my $bytes = Encode::encode( 'UTF-8', $str );

    $js->set(
        load => sub {
            return bless( \$bytes => 'JavaScript::Duktape::Buffer' );
        }
    );

    my $ret = $js->eval(q{
        var buf = load();
        buf;
    });

    is $ret, $bytes;
    is length($ret), length($bytes);
};

subtest 'return undef buffer' => sub {
    my $js = JavaScript::Duktape->new;

    $js->set(
        load => sub {
            my $var;
            return bless( \$var => 'JavaScript::Duktape::Buffer' );
        }
    );

    my $ret = $js->eval(q{
        var buf = load();
        buf;
    });

    is $ret, '';
};

subtest 'return buffer with a zero' => sub {
    my $js = JavaScript::Duktape->new;

    $js->set(
        load => sub {
            my $var = '0';
            return bless( \$var => 'JavaScript::Duktape::Buffer' );
        }
    );

    my $ret = $js->eval(q{
        var buf = load();
        buf;
    });

    is $ret, '0';
};

done_testing;
