use strict;
use Test::Base;

use Geo::Google::MyMap::KMLURL;

plan tests => 1 * blocks;

filters {
    input    => [qw/chomp/],
    expected => [qw/chomp/],
};

run {
    my $block = shift;

    my $result;

    eval { $result = mymap2kmlurl($block->input); };

    if ( $@ ) {
        ok ( $block->expected eq 'ERROR' && $@ =~ /^Cannot find msid/ );
    } else {
        is ( $result, $block->expected );
    }
};


__END__
=== url2url
--- input
http://maps.google.co.jp/maps/ms?ie=UTF8&hl=ja&msa=0&output=nl&msid=100703231789736299945.00000111c65c3586665af
--- expected
http://maps.google.co.jp/maps/ms?msa=0&msid=100703231789736299945.00000111c65c3586665af&output=kml&ge_fileext=.kml

=== msid2url
--- input
100703231789736299945.00000111c65c3586665af
--- expected
http://maps.google.co.jp/maps/ms?msa=0&msid=100703231789736299945.00000111c65c3586665af&output=kml&ge_fileext=.kml

=== bad case url
--- input
http://maps.google.co.jp/maps/ms?ie=UTF8&hl=ja&msa=0&output=nl&msids=100703231789736299945.00000111c65c3586665af
--- expected
ERROR

=== bad case msid
--- input
100703231789736299945.00000111c65c3586665a
--- expected
ERROR

