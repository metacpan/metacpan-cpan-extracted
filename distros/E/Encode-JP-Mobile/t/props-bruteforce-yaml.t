use strict;
use warnings;
use Test::More;
use Encode;
use Encode::JP::Mobile ':props';

eval { require YAML };
plan skip_all => $@ if $@;

my $docomo_dat   = YAML::LoadFile("dat/docomo-table.yaml");
my $docomo       = +{ map { $_->{unicode} => 1 } @$docomo_dat };
my $softbank_dat = YAML::LoadFile("dat/softbank-table.yaml");
my $softbank     = +{ map { $_->{unicode} => 1 } @$softbank_dat };
my $kddi_dat     = YAML::LoadFile("dat/kddi-table.yaml");
my $kddi_cp932   = +{ map { $_->{unicode} => 1 } @$kddi_dat };
my $kddi_auto    = +{ map { $_->{unicode_auto} => 1 } @$kddi_dat };

plan 'no_plan';

test_all('docomo', InDoCoMoPictograms(), $docomo);
test_all('softbank', InSoftBankPictograms(), $softbank);
test_all('kddi', InKDDIPictograms(), +{ %$kddi_cp932, %$kddi_auto });
test_all('kddi-cp932', InKDDICP932Pictograms(), $kddi_cp932);
test_all('kddi-auto', InKDDIAutoPictograms(), $kddi_auto);
test_all('kddi-softbank-conflicts-1', InKDDISoftBankConflicts(), +{ %$kddi_cp932 });
test_all('kddi-softbank-conflicts-2', InKDDISoftBankConflicts(), +{ %$softbank });

sub test_all {
    my ($name, $property, $map) = @_;

    range_each($property => sub {
        my $uni = sprintf '%X', shift;
        ok $map->{$uni}, "$name $uni";
    });
}

sub range_each {
    my ($map, $code) = @_;

    for my $range (split /\n/, $map) {
        next unless $range;
        my ($min, $max) = map { hex $_ } split /\t/, $range;
        my $i = $min;
        if ($max) {
            while ($i <= $max) {
                $code->( $i );
                $i++;
            }
        } else {
            $code->($min);
        }
    }
}

