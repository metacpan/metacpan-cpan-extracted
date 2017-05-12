#!/usr/bin/env perl -w
use strict;
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Flatten;

use Exception::Chain;

subtest 'auto complete instance' => sub {
    throws_ok {
        eval {
            Exception::Chain->throw(
                message => 'invalid request',
            );
        };
        if (my $e = $@) {
            Exception::Chain->throw($e);
        }
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    like $e->to_string, qr{\Ainvalid request at t/auto_complete\.t line \d+\. at t/auto_complete\.t line \d+\.\z};
    note explain $e->to_string;
};

subtest 'not auto complete instance' => sub {
    throws_ok {
        eval {
            die 'invalid request';
        };
        if (my $e = $@) {
            Exception::Chain->throw($e);
        }
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    like $e->to_string, qr{\Ainvalid request at t/auto_complete\.t line \d+\. at t/auto_complete\.t line \d+\.\z};
    note explain $e->to_string;
};

subtest 'auto complete instance with message' => sub {
    throws_ok {
        eval {
            Exception::Chain->throw(
                message => 'invalid request',
            );
        };
        if (my $e = $@) {
            Exception::Chain->throw(
                message => 'invalid',
                error   => $e,
            );
        }
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    like $e->to_string, qr{\Ainvalid request at t/auto_complete\.t line \d+\. invalid at t/auto_complete\.t line \d+\.\z};
    note explain $e->to_string;
};

subtest 'no auto complete instance with message' => sub {
    throws_ok {
        eval {
            die 'connection failed';
        };
        if (my $e = $@) {
            Exception::Chain->throw(
                error   => $e,
                tag     => ['internal_server_error'],
                message => 'internal server error',
                delivery => { code => 500 },
            );
        }
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    like $e->to_string, qr{\Aconnection failed at t/auto_complete\.t line \d+\. internal server error at t/auto_complete\.t line \d+\.\z};
    is $e->match('internal_server_error'), 1;
    is_deeply $e->delivery, { code => 500 };
    note explain $e->to_string;
};

subtest 'chained instance' => sub {
    throws_ok {
        eval {
            Exception::Chain->throw(
                tag     => ['invalid_request'],
                message => 'invalid request',
            );
        };
        if (my $e = $@) {
            Exception::Chain->throw(
                error   => $e,
                tag     => ['user_error'],
                message => 'user error',
            );
        }
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    note explain $e->to_string;
    is $e->match('invalid_request'), 1;
    is $e->match('user_error'), 1;
};

subtest 'no message' => sub {
    eval {
        my $ret = Exception::Chain->throw(
            tag => ['invalid_request'],
        );
    };
    if (my $e = $@) {
        is ref $e, 'Exception::Chain';
    }
};

done_testing;
