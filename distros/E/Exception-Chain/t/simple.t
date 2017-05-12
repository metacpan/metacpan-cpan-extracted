#!/usr/bin/env perl -w
use strict;
use lib 't/lib';
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Flatten;

use Exception::Chain;
use MyException;

subtest 'simple' => sub {
    throws_ok {
        Exception::Chain->throw(
            message => 'invalid request',
        );
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    like $e->to_string, qr{invalid request at t.simple.t line};
    like "$e", qr{invalid request at t.simple.t line};
    note explain $e->to_string;
    is $e->first_message, 'invalid request';
};

subtest 'dumped hash' => sub {
    throws_ok {
        Exception::Chain->throw(
            message => { error_code => 1 },
        );
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    like $e->to_string, qr|{'error_code' => 1} at t.simple\.t line|;
    note explain $e->to_string;
    is $e->first_message, "{'error_code' => 1}";
};

subtest 'dumped array' => sub {
    throws_ok {
        Exception::Chain->throw(
            message => [ 1, 2 ],
        );
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    like $e->to_string, qr|\[1,2\] at t.simple\.t line|;
    note explain $e->to_string;
    is $e->first_message, "[1,2]";
};

subtest 'chain message' => sub {
    throws_ok {
        eval {
            Exception::Chain->throw(
                message => 'invalid request',
            );
        };
        if (my $e = $@) {
            $e->rethrow('operation denied');
        }
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    like $e->to_string, qr{\Ainvalid request at t.simple\.t line \d+\. operation denied at t.simple\.t line \d+\.\z};
    note explain $e->to_string;
};

subtest 'match single' => sub {
    throws_ok {
        Exception::Chain->throw(
            tag     => 'invalid request',
            message => 'msg is invalid parameter',
        );
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    is $e->match('invalid request'), 1, 'match exception is ok';
    is $e->match('not match'),       0, 'match exception is ok';
    is $e->first_message, 'msg is invalid parameter';
};

subtest 'match plural' => sub {
    my @condition = ('invalid request', 'unauthorized');
    throws_ok {
        Exception::Chain->throw(
            tag     => 'invalid request',
            message => 'msg is invalid parameter',
        );
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    is $e->match(@condition), 1, 'match exception is ok';

    throws_ok {
        Exception::Chain->throw(
            tag     => 'unauthorized',
            message => 'user_id is invalid',
        );
    } 'Exception::Chain', 'throws ok';
    $e = $@;
    is $e->match(@condition), 1, 'match exception is ok';
};

subtest 'define multi tag' => sub {
    throws_ok {
        Exception::Chain->throw(
            tag     => ['connection failed', 'crit'],
            message => 'dbname=user is connection failed',
        );
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    is $e->match('connection failed'), 1, 'match exception is ok';
    is $e->match('crit'),              1, 'match exception is ok';
};

subtest 'chain tag' => sub {
    throws_ok {
        eval {
            Exception::Chain->throw(
                tag     => 'connection failed',
                message => 'dbname=user is connection failed'
            );
        };
        if (my $e = $@) {
            $e->rethrow(tag => 'internal server error');
        }
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    is $e->match('connection failed'), 1, 'match exception is ok';
    is $e->match('internal server error'), 1, 'match exception is ok';
};

subtest 'throw object' => sub {
    throws_ok {
        Exception::Chain->throw(
            message  => 'dbname=user is connection failed',
            delivery => My::Response->new(500, 'internal server error'),
        );
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    is $e->delivery->{code}, 500;
    is $e->delivery->{msg},  'internal server error';
};

subtest 'override object' => sub {
    throws_ok {
        eval {
            Exception::Chain->throw(
                message  => 'dbname=user is connection failed',
                delivery => My::Response->new(500, 'internal server error'),
            );
        };
        if (my $e = $@) {
            Exception::Chain->throw(
                error    => $e,
                delivery => My::Response->new(400, 'override'),
            );
        }
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    is $e->delivery->{code}, 400;
    is $e->delivery->{msg},  'override';
};

subtest 'delivery on the occasion of chain' => sub {
    throws_ok {
        eval {
            Exception::Chain->throw(
                message  => 'dbname=user is connection failed',
            );
        };
        if (my $e = $@) {
            Exception::Chain->throw(
                error    => $e,
                delivery => My::Response->new(500, 'internal server error'),
            );
        }
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    is $e->delivery->{code}, 500;
    is $e->delivery->{msg},  'internal server error';
};

subtest 'skip level' => sub {
    subtest 'not use' => sub {
        throws_ok {
            MyException->throw;
        } 'Exception::Chain', 'throws ok';
        my $e = $@;
        like $e->to_string, qr{t/lib/MyException};
    };

    subtest 'use ' => sub {
        local $Exception::Chain::SkipDepth += 1;
        throws_ok {
            MyException->throw;
        } 'Exception::Chain', 'throws ok';
        my $e = $@;
        like $e->to_string, qr{t/simple};
    };
};

subtest 'add message' => sub {
    eval {
        Exception::Chain->throw(
            message  => 'dbname=user is connection failed',
        );
    };
    if (my $e = $@) {
        $e->add_message('add message');
        note explain $e->to_string;
        like $e->to_string, qr{\Adbname=user is connection failed at t.simple\.t line \d+\. add message at t.simple\.t line \d+\.\z};
    }
};

done_testing;


package
    My::Response;
sub new {
    my ($class, $code, $msg) = @_;
    bless {
        code => $code,
        msg  => $msg,
    }, $class;
}

1;
