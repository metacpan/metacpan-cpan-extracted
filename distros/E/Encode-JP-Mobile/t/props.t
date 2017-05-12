use strict;
use warnings;
use Test::More tests => 14;
use Encode::JP::Mobile ':props';

ok InKDDISoftBankConflicts();
ok InKDDICP932Pictograms();
ok InKDDIAutoPictograms();
ok InKDDIPictograms();

ok "\x{E501}" =~ /\p{InKDDISoftBankConflicts}/;
ok "\x{E44C}" !~ /\p{InKDDISoftBankConflicts}/;
ok "\x{E501}" =~ /\p{InKDDICP932Pictograms}/;
ok "\x{F0FC}" !~ /\p{InKDDICP932Pictograms}/;
ok "\x{F0FC}" =~ /\p{InKDDIAutoPictograms}/;
ok "\x{E501}" !~ /\p{InKDDIAutoPictograms}/;
ok "\x{F0FC}" =~ /\p{InKDDIPictograms}/;
ok "\x{E501}" =~ /\p{InKDDIPictograms}/;

my $possibly_kddi = "\x{E589} \x{E501}"; # E589 is only in KDDI
is guess_carrier($possibly_kddi), "kddi";

my $possibly_softbank = "\x{E44C} \x{E501}"; # E44C is only in SoftBank
is guess_carrier($possibly_softbank), "softbank";

sub guess_carrier {
    my $string = shift;
    if ($string =~ /\p{InKDDISoftBankConflicts}/) {
        eval { Encode::encode("x-sjis-kddi-cp932-raw", $string, Encode::FB_CROAK) };
        if ($@) {
            return 'softbank';
        } else {
            return 'kddi';
        }
    }

    return;
}
