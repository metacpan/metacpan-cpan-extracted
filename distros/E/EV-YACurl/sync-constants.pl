use v5.010;
use strict;
use warnings;
use FindBin qw($Bin);

open my $fh, '<', "$Bin/libcurl-symbols.h" or die $!;
open my $constants, '>', "$Bin/constants.inc" or die $!;

my %words;
while (<$fh>) {
    my ($word, $what)= /\s(CURL\S+)_(FIRST|LAST)\s/;
    next unless $word;
    $words{$what}{$word}= 1;
}

for my $word (sort keys %{$words{FIRST}}) {
    next if $word =~ /\A(?:
        CURL_STRICTER
        | CURL_DID_MEMORY_FUNC_TYPEDEFS
        | CURLOPT
        | CURL_WIN32
        | CURL_VERSION_BITS
        | CURL_PULL_.*
        | CURL_AT_LEAST_VERSION
        | CURL_ISOCPP
        | CURLWARNING
        | CURL_IGNORE_DEPRECATION
        | CURLOPTDEPRECATED
        | CURL_DEPRECATED
        | CURL_HAS_DECLSPEC_ATTRIBUTE
    )\z/x;

    print $constants <<EOC;
#if LIBCURL_HAS($word)
    hv_stores(the_hv, "$word", newSViv($word));
#endif
EOC
}
