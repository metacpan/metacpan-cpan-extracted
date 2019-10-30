#!/usr/bin/perl

# Test the warning:: overrides

use Test::More tests => 7;
use warnings;
use warnings::register;
use Log::Scrubber;

scrubber_init( {
    '\x1b' => '[esc]',
    '4007000000027' => 'X' x 13,
    '1234' => 'X' x 4,
} );

END { unlink "test.out"; }

sub _read
{
    open FILE, "test.out";
    my $ret = join('', <FILE>);
    close FILE;
    return $ret;
}

sub _setup
{
    open STDERR, ">test.out";
    select((select(STDERR), $|++)[0]);
}

my $tests = {
    "escape --> \x1b" => "escape --> [esc]",
    "escape --> 4007000000027" => "escape --> XXXXXXXXXXXXX",
    "escape --> 1234" => "escape --> XXXX",
};

foreach my $key ( keys %$tests ) {
    eval {
        _setup;
        warnings::warn($key."\n");
    };

    my $result = _read;
    $result =~ s/\n.*$//s;
    is ($result, $tests->{$key}, "warnings::warn");

    eval {
        _setup;
        warnings::warnif("void", $key."\n");
    };

    $result = _read;
    $result =~ s/\n.*$//s;
    is ($result, $tests->{$key}, "warnings::warnif");
}

subtest "Deep recursion check" => sub {
    eval {
        # this test is HORRIBLE code, you should never do this...
        # but we are testing just in case someone actually does something like this
        _setup;
        local $SCRUBBER = 1;
        my $old_warn = $SIG{'__DIE__'};
        local $SIG{'__DIE__'} = sub {
            # simulate overriding warn with some other service/tool
            my $x = shift;
            $x = '$'.$x;
            $old_warn->($x,@_);
        };
        Log::Scrubber::scrubber_remove_signal('__DIE__');
        { # new scope
            local $SCRUBBER = 1;
            Log::Scrubber::scrubber_add_signal('__DIE__');
            my $old_warn = $SIG{'__DIE__'};
            local $SIG{'__DIE__'} = sub {
                # simulate overriding warn with some other service/tool
                my $x = shift;
                $x = '$'.$x;
                $old_warn->($x,@_);
            };
            Log::Scrubber::scrubber_remove_signal('__DIE__');
            { # new scope
                local $SCRUBBER = 1;
                Log::Scrubber::scrubber_add_signal('__DIE__');
                die 'moo1234';
            }
        }
    };
    my $e = $@;
    my $result = _read;
    cmp_ok($e,'=~','mooXXXX at ','Got the expected die message');
    cmp_ok($result,'=~','Deep recursion detected in Log::Scrubber','Protected against deep recursion');
};
