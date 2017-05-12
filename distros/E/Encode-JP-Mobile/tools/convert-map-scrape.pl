use strict;

# http://labs.unoh.net/2007/02/post_65.html to dat/convert-map-utf8.yaml
# perl tools/convert-map-scrape.pl > dat/convert-map-utf8.yaml

use Encode;
use Encode::JP::Mobile 0.09;
use LWP::Simple;
use YAML;

my %files;
for my $file (qw( emoji_e2is.txt emoji_i2es.txt emoji_s2ie.txt )) {
    $files{$file} = decode('cp932', get("http://labs.unoh.net/$file"));
}

my $no2uni = {};
for my $file (keys %files) {
    for my $line (split /\n/, $files{$file}) {
        next unless $line =~ /^%/;
        my ($no, $byte) = split "\t", $line;
        
        $file eq 'emoji_i2es.txt' && do {
            $no2uni->{$no} = sprintf '%04X', ord decode('x-sjis-docomo', pack 'H*', $byte);
        };
        
        $file eq 'emoji_e2is.txt' && do {
            $no2uni->{$no} = sprintf '%04X', ord decode('x-sjis-kddi-auto', pack 'H*', $byte);
        };
        
        $file eq 'emoji_s2ie.txt' && do {
            $no2uni->{$no} = sprintf '%04X', ord decode('x-sjis-softbank', "\x1b\x24$byte\x0f");
        };
    }
}

my %map;
for my $file (keys %files) {
    for my $line (split /\n/, $files{$file}) {
        next unless $line =~ /^%/;
        chomp $line;

        $file eq 'emoji_i2es.txt' && do {
            my ($docomo, undef, $kddi, $softbank) = split "\t", $line;
            $map{docomo}{ $no2uni->{$docomo} }->{kddi}     = get_unicode($kddi);
            $map{docomo}{ $no2uni->{$docomo} }->{softbank} = get_unicode($softbank);
        };
        
        $file eq 'emoji_e2is.txt' && do {
            my ($kddi, undef, $docomo, $softbank) = split "\t", $line;
            $map{kddi}{ $no2uni->{$kddi} }->{docomo}   = get_unicode($docomo);
            $map{kddi}{ $no2uni->{$kddi} }->{softbank} = get_unicode($softbank);
        };
        
        $file eq 'emoji_s2ie.txt' && do {
            my ($softbank, undef, $docomo, $kddi) = split "\t", $line;
            $map{softbank}{ $no2uni->{$softbank} }->{docomo} = get_unicode($docomo);
            $map{softbank}{ $no2uni->{$softbank} }->{kddi}   = get_unicode($kddi);
        };
    }
}

sub get_unicode($) {
    my $key = shift;
    if ($key =~ /^%/) {
        $key =~ s/(%[^%]+%)/$no2uni->{$1}/ge;
        return +{ type => 'pictogram', unicode => $key };
    } else {
        return +{ type => 'name', unicode => $key };
    }
}

binmode STDOUT, ":utf8";
print YAML::Dump(\%map);
