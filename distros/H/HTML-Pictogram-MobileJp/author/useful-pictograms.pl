use strict;
use warnings;
use HTML::Pictogram::MobileJp::Map qw/$DOCOMO $EZWEB $SOFTBANK/;
use Encode::JP::Mobile::Charnames;

binmode STDOUT, ':utf8';

for my $number (sort { $a <=> $b } keys %$DOCOMO) {
    next unless $EZWEB->{$number};
    next unless $SOFTBANK->{$number};
    next if utf8::is_utf8($SOFTBANK->{$number});
    next if utf8::is_utf8($EZWEB->{$number});

    my $name = Encode::JP::Mobile::Charnames::unicode2name(hex $DOCOMO->{$number});
    printf "%s %s\n",  $number, $name;
}

