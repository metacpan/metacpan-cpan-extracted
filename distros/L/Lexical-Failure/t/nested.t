use Test::More;

plan tests => 6;

my $DIE_LINE;

package Foo {
    use Test::More;
    use Lexical::Failure fail => 'error';

    sub import {
        my ($package, $fail_mode) = @_;
        ON_FAILURE($fail_mode);
    }

    sub public {
        if (private_level_1()) {
            diag "private_level_1() returned true";
        }
        else {
            diag "private_level_1() returned false";
        }
        fail 'Should not return from call to private_level_1()';
        return 1;
    }

    sub private_level_1 {
        private_level_2();
    }

    sub private_level_2 {
        $DIE_LINE = __LINE__ + 1;
        error 'failed';
    }
}

use Test::Effects;

subtest 'null mode' => sub {
    BEGIN { Foo->import('null') }

    effects_ok { Foo::public() }
               { #VERBOSE => 1,
                  return => undef,
               }
            => 'scalar context';

    effects_ok { Foo::public() }
               { #VERBOSE => 1,
                  return => [],
               }
            => 'list context';
};

subtest 'undef mode' => sub {
    BEGIN { Foo->import('undef') }

    effects_ok { Foo::public() }
               { #VERBOSE => 1,
                  return => undef,
               };
};

subtest 'failobj mode' => sub {
    BEGIN { Foo->import('failobj') }

    my $CROAK_LINE = __LINE__+1;
    my $result = Foo::public();

    effects_ok { !!$result }
               { #VERBOSE => 1,
                  return => q{},
               }
        => 'failobj checked';


    my $USE_LINE = __LINE__+1;
    effects_ok { $result+0 }
               { #VERBOSE => 1,
                     die => qr/\Qfailed at \E\S+\Q line $CROAK_LINE\E\n\QAttempt to use failure returned by Foo::public in addition at \E\S+\Q line \E$USE_LINE/,
               }
        => 'failobj used';
};

subtest 'die mode' => sub {
    BEGIN { Foo->import('die') }

    effects_ok { Foo::public() }
               { #VERBOSE => 1,
                     die => qr/\Qfailed at \E\S+\Q line $DIE_LINE/,
               };
};

subtest 'croak mode' => sub {
    BEGIN { Foo->import('croak') }

    my $CROAK_LINE = __LINE__+1;
    eval { Foo::public() };
    like $@, qr/\Qfailed at \E\S+\Q line $CROAK_LINE\E/;
};

subtest 'croak mode' => sub {
    BEGIN { Foo->import('confess') }

    my $CROAK_LINE = __LINE__+1;
    eval { Foo::public() };
    my $error = $@;
    like $error, qr/line $CROAK_LINE/  => 'croak line reported';
    like $error, qr/\Qfailed at \E\S+\Q line $DIE_LINE/ => 'die line reported';
};


done_testing();

