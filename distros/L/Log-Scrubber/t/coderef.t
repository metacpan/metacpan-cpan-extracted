#!/usr/bin/perl
use strict;
use warnings;

# Test scope, setup a basic test.
# Then enter a local scope and add new overrides
# Then leave scope and make sure it reverts back

use Test::More tests => 4;
use Log::Scrubber qw($SCRUBBER scrubber_enabled);

END { unlink "test.out"; }

_my_test('Nothing should be modified','Nothing should be modified');
$SIG{__WARN__} = sub { (CORE::warn 'w1: '.$_[0]); };
_my_test('Basic global override no scrubbing','w1: Basic global override no scrubbing');

Log::Scrubber::scrubber_add_scrubber({'codekey'=>sub { my ($key,$val) = @_; $val =~ s/Basic/Multiple/; return $val; },'override no'=> 'override with'});
Log::Scrubber::scrubber_add_signal('WARN');
$SCRUBBER = 1; is(scrubber_enabled(), 1);
_my_test('Basic global override no scrubbing','w1: Multiple global override with scrubbing');
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

1;
