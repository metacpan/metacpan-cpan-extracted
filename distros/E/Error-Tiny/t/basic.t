use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Error::Tiny;

use lib 't/lib';

use CustomException;

subtest 'catch with class' => sub {
    my $called;

    try {
        die 'here';
    }
    catch Error::Tiny::Exception then {
        my $e = shift;

        $called++;
    };

    ok $called;
};

subtest 'default catch' => sub {
    my $called;

    try {
        die 'here';
    }
    catch {
        my $e = shift;

        $called++;
    };

    ok $called;
};

subtest 'transform string exception to object' => sub {
    my $error;

    try {
        die 'here';
    }
    catch {
        my $e = shift;

        $error = $e;
    };

    ok $error->isa('Error::Tiny::Exception');
};

subtest 'deep catch' => sub {
    my $called;

    try {
        die 'here';
    }
    catch CustomException then {} catch {
        my $e = shift;

        $called++;
    };

    ok $called;
};

subtest 'return last value scalar' => sub {
    my $called;

    my $return = try {
        'hi';
    }
    catch {
        undef;
    };

    is $return, 'hi';
};

subtest 'return last value array' => sub {
    my $called;

    my @return = try {
        (1, 2, 3);
    }
    catch {
        undef;
    };

    is_deeply \@return, [1, 2, 3];
};

subtest 'return last value from catch' => sub {
    my $called;

    my $return = try {
        die 'here';
    }
    catch {
        'hi';
    };

    is $return, 'hi';
};

subtest 'preserve context' => sub {
    my $called;

    my @return = try {
        wantarray ? 1 : 2;
    }
    catch {
        undef;
    };

    is_deeply \@return, [1];
};

subtest 'preserve context2' => sub {
    my $called;

    my $return = try {
        wantarray ? 1 : 2;
    }
    catch {
        undef;
    };

    is $return, 2;
};

subtest 'propagate error' => sub {
    ok exception {
        try { die 'here' } catch CustomException then {};
    };
};

subtest 'save info from string exception' => sub {
    my $error;

    try { die 'here' } catch { $error = shift };

    is $error->message, 'here';
    is $error->file, __FILE__;
    is $error->line, __LINE__ - 4;
};

subtest 'save info from object exception' => sub {
    my $error;

    try { CustomException->throw('error') } catch { $error = shift };

    is $error->message, 'error';
    is $error->file, __FILE__;
    is $error->line, __LINE__ - 4;
};

subtest 'stringify string exception' => sub {
    my $error;

    try { die 'here' } catch { $error = shift };

    like $error, qr/here/;
};

subtest 'stringify string exception confess' => sub {
    my $error;

    require Carp;

    try { Carp::confess('here') } catch { $error = shift };

    like $error, qr/here at [\S]+ line \d+/;
};

subtest 'stringify object exception' => sub {
    my $error;

    try { CustomException->throw('error') } catch { $error = shift };

    like $error, qr/error/;
};

subtest 'rethrow in catch' => sub {
    my $error = exception {
        try { CustomException->throw('error') }
        catch CustomException then {
            my $e = shift;

            CustomException->throw($e->message);
        }
    };

    is $error->message, 'error';
    is $error->file, __FILE__;
    is $error->line, __LINE__ - 6;
};

subtest 'rethrow' => sub {
    my $error = exception {
        try { CustomException->throw('error') }
        catch {
            my $e = shift;

            $e->rethrow;
        }
    };

    is $error->message, 'error';
    is $error->file, __FILE__;
    is $error->line, __LINE__ - 10;
};

done_testing;
