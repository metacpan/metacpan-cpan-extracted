use strict;
use warnings;
use Encode;
use Encode::JP::Mobile;

use Test::More 'no_plan';

my $map = do "dat/convert-map-utf8.pl";

for my $from_carrier (qw( docomo kddi softbank )) {
    my $list = do "dat/$from_carrier-table.pl";
    for my $row (@$list) {
        my $code = $row->{unicode_auto} || $row->{unicode};
        my $convert_to = $map->{$from_carrier}{$code};
        test_all($from_carrier, $code, $convert_to);
    }
}

sub test_all {
    my ($from_carrier, $code, $convert_to) = @_;
    my $char = chr hex $code;

    for my $target_carrier (qw( docomo kddi softbank )) {  
        next if $target_carrier eq $from_carrier;
          
        my $convert = $convert_to->{$target_carrier};
        my $encoding = "x-utf8-$target_carrier";
    
        if ($convert->{type} eq 'pictogram') {
            my $pictogram = do {
                my $u = $convert->{unicode};
                $u =~ s{(....)}{chr hex $1}ge;
                $u;
            };
            is encode($encoding, $char),
               encode($encoding, $pictogram),
               "U+$code $from_carrier => $target_carrier (emoji to emoji[s])";
        }
        elsif ($convert->{type} eq 'name') {
            my $name = $convert->{unicode}; 
    
            is encode($encoding, $char, Encode::JP::Mobile::FB_CHARACTER),
               $name,
               "U+$code $from_carrier => $target_carrier (fallback)";
        }
    }
}
