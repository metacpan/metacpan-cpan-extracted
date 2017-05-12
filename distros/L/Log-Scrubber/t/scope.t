#!/usr/bin/perl
use strict;
use warnings;

# Test scope, setup a basic test.
# Then enter a local scope and add new overrides
# Then leave scope and make sure it reverts back

use Test::More tests => 15;
use Log::Scrubber qw($SCRUBBER scrubber_enabled);

END { unlink "test.out"; }

_my_test('Nothing should be modified','Nothing should be modified');
$SIG{__WARN__} = sub { (CORE::warn 'w1: '.$_[0]); };
_my_test('Basic global override no scrubbing','w1: Basic global override no scrubbing');

Log::Scrubber::scrubber_add_scrubber({'Basic'=>'Multiple','override no'=> 'override with'});
Log::Scrubber::scrubber_add_signal('WARN');
$SCRUBBER = 1; is(scrubber_enabled(), 1);
_my_test('Basic global override no scrubbing','w1: Multiple global override with scrubbing');
$SCRUBBER = 0; is(scrubber_enabled(), 0);
_my_test('Basic global override no scrubbing','w1: Basic global override no scrubbing');
$SCRUBBER = 1; is(scrubber_enabled(), 1);

for (1) {
    note "ENTER LOCAL SCOPE\n";
    local $SCRUBBER; is(scrubber_enabled(), 1);
    Log::Scrubber::scrubber_add_scrubber({'global'=> 'local'});
    _my_test('Basic global override no scrubbing','w1: Multiple local override with scrubbing');
    $SCRUBBER = 0; is(scrubber_enabled(), 0);
    _my_test('Basic global override no scrubbing','w1: Basic global override no scrubbing');
    note "LEAVE LOCAL SCOPE\n";
}
note "LEFT LOCAL SCOPE\n";
               is(scrubber_enabled(), 1);
_my_test('Basic global override no scrubbing','w1: Multiple global override with scrubbing');
$SCRUBBER = 0; is(scrubber_enabled(), 0);
_my_test('Basic global override no scrubbing','w1: Basic global override no scrubbing');
#!/usr/bin/perl

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
    my ($warn_text,$expected_result) = @_;
    eval { 
        _setup;
        warn($warn_text."\n");
    };

    my $result = _read;
    is ($result, $expected_result, "warn: ".$result);
}
