use 5.014;
use warnings;

use Test::More;
plan tests => 3;

# Where the fail() comes from...
use lib 'tlib';
use TestModule errors => 'failobj';

# Track line from which failure should be reported...
my $CROAK_LINE;
my $CROAK_LINE2;

# Try to fail in void context...
my $died;
for (1..1) {
    local $SIG{__DIE__} = sub {
        like shift, qr{\A \QDidn't succeed at $CROAK_LINE\E }xms
            => 'Correct exception message 1';
        $died = 1;
        close *STDERR;
    };

    BEGIN { $CROAK_LINE = __FILE__ . ' line ' . (__LINE__ + 1); }
    eval { TestModule::dont_succeed() };
    ok $died => 'This should be test 2';
}

fail 'Should have croaked from unchecked failure'
    if !$died;


# Try to fail in non-void context...
undef $died;
for (1..1) {
    local $SIG{__DIE__} = sub {
        like shift, qr{\A \QDidn't succeed at $CROAK_LINE2\E }xms
            => 'Correct exception message 2';
        $died = 1;
        close *STDERR;
    };

    BEGIN { $CROAK_LINE2 = __FILE__ . ' line ' . (__LINE__ + 1); }
    my $result = TestModule::dont_succeed();
    ok !$died => 'This should be test 3';
}
