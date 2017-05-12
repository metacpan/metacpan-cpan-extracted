#!/usr/bin/perl
use strict;
use warnings;

# Test scope, setup a basic test.
# Then enter a local scope and add new overrides
# Then leave scope and make sure it reverts back

use Test::More tests => 14;
use Log::Scrubber qw(disable $SCRUBBER scrubber_enabled scrubber);

BEGIN {
    require Exporter;
    eval { require Data::Dumper; $main::d_dumper = 1 };

    if ($main::d_dumper) {
      Data::Dumper->import(qw(Dumper));
    }
};


END { unlink "test.out"; }

Log::Scrubber::scrubber_remove_signal('__WARN__');
Log::Scrubber::scrubber_remove_signal('__DIE__');
Log::Scrubber::scrubber_remove_method('warnings::warn');
Log::Scrubber::scrubber_remove_method('warnings::warnif');

my $t = {
    'abc' => {
        'x' => {
            'x' => '123',
        },
    },
    'arr' => [456,789],
    };

$$t{'arr'}[2] = $$t{'arr'}; # throw in an evil recursion loop
$$t{'abc'}{'recursive'} = $t; # throw in an evil recursion loop

$$t{'undef'}{'hash'} = undef; # make sure we don't have problems with undefined values
$$t{'undef'}{'hash2'} = undef;
$$t{'undef'}{'hash3'} = undef;
$$t{'undef'}{'arr'} = [0,undef,undef,'101112']; # more undef, and a nested key with an identical name as a root key

Log::Scrubber::scrubber_add_scrubber({
    'abc'=> 'agood', # this will run if we are properly overriding hash keys
    '123'=> '1good', # this will run if we are properly overriding hash values
    '456'=> '4good', # this will run if we are properly overriding arrays
    '789'=> '7good', # this will run if we are properly overriding arrays
    '101112'=> '10ood', # this will run if we are properly nested hashes with identical names
    '\'1good'=> '\'1warn', # should not happen until we enable warnings
    });

SKIP: {
    skip 'Data::Dumper not found', 5 unless $main::d_dumper;

    is(scrubber_enabled(), 0,'Scrubber is disabled');
    _my_test($t,'123'); # make sure we really are disabled

    $SCRUBBER = 1;
    is(scrubber_enabled(), 1,'Scrubber is enabled');

    Log::Scrubber::scrubber_add_method('Data::Dumper::Dumper');
    Log::Scrubber::scrubber_add_method('Dumper');
    _my_test($t,'agood');
    _my_test($t,'1good');
    _my_test($t,'4good');
    _my_test($t,'7good');
    Log::Scrubber::scrubber_add_signal('__WARN__');
    _my_test($t,'1warn');

    $SCRUBBER = 0;
    is(scrubber_enabled(), 0,'Scrubber is disabled');
    _my_test($t,'abc'); # make sure our original values are all still there
    _my_test($t,'123');
    _my_test($t,'456');
    _my_test($t,'789');
    _my_test($t,'101112');
};

sub _read {
    open FILE, "test.out";
    my $ret = join('', <FILE>);
    close FILE;
    $ret =~ s/[\s\r\n]+$//;
    return $ret;
}

sub _setup {
    open STDERR, ">test.out";
    select((select(STDERR), $|++)[0]);
}

sub _my_test {
    my ($warn_data,$expected_result) = @_;
    eval { 
        _setup;
        warn Data::Dumper::Dumper $warn_data;
    };

    my $result = _read;
    my $quoted = quotemeta $expected_result;
    like ($result, qr/$quoted/, "warn contains: ".$expected_result);
}

1;
