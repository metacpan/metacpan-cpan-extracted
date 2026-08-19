use v5.010;
use strict;
use warnings;
use FindBin qw($Bin);

my %curlopt_skip= map { $_ => 1 }
# Implemented directly / privately
qw(
    PRIVATE
    WRITEFUNCTION
    WRITEDATA
    ERRORBUFFER
    HEADERDATA
    HEADERFUNCTION
    READDATA
    READFUNCTION
    POSTFIELDSIZE
    POSTFIELDSIZE_LARGE
    COPYPOSTFIELDS
    POSTFIELDS
    MIMEPOST
    DEBUGDATA
    DEBUGFUNCTION
    STDERR
    TRAILERFUNCTION
    TRAILERDATA
),
# Don't want: probably not useful
qw(
    SHARE
    CLOSESOCKETDATA
    CLOSESOCKETFUNCTION
    IOCTLDATA
    IOCTLFUNCTION
    SSL_CTX_DATA
    SSL_CTX_FUNCTION
    INTERLEAVEDATA
    INTERLEAVEFUNCTION
    OPENSOCKETDATA
    OPENSOCKETFUNCTION
    RESOLVER_START_DATA
    RESOLVER_START_FUNCTION
    CONV_FROM_NETWORK_FUNCTION
    CONV_FROM_UTF8_FUNCTION
    CONV_TO_NETWORK_FUNCTION
    SEEKDATA
    SEEKFUNCTION
    SOCKOPTDATA
    SOCKOPTFUNCTION
    OBSOLETE40
    HTTPPOST
),
# Want, just not done yet
qw(
    CURLU
    FNMATCH_DATA
    FNMATCH_FUNCTION
    PROGRESSDATA
    PROGRESSFUNCTION
    SSH_KEYDATA
    SSH_KEYFUNCTION
    STREAM_DEPENDS
    STREAM_DEPENDS_E
    XFERINFOFUNCTION
    XFERINFODATA
    CHUNK_BGN_FUNCTION
    CHUNK_DATA
    CHUNK_END_FUNCTION
    HSTSREADFUNCTION
    HSTSREADDATA
    HSTSWRITEFUNCTION
    HSTSWRITEDATA
    PREREQFUNCTION
    PREREQDATA
    SSH_HOSTKEYFUNCTION
    SSH_HOSTKEYDATA
);

my $curl_h = $ARGV[0] or die "Usage: $0 [curl.h]";
if (!-f $curl_h) {
    die "File not found: $curl_h";
}

open my $fh, '<', $curl_h;
open my $strings, '>', "$Bin/curlopt-str.inc";
open my $longs, '>', "$Bin/curlopt-long.inc";
open my $offt, '>', "$Bin/curlopt-off-t.inc";
open my $slists, '>', "$Bin/curlopt-slist.inc";
open my $blobs, '>', "$Bin/curlopt-blob.inc";

my $curl_h_source = join '', <$fh>;

while ($curl_h_source =~ /
        (?:
            CURLOPT \s* \(
                CURLOPT_(?<option>\S+) \s* , \s*
                CURLOPTTYPE_(?<type>\S+) \s* , \s*
                (?<number>\d+) \s*
            \)
            |
            CURLOPTDEPRECATED \s* \(
                CURLOPT_(?<option>\S+) \s* , \s*
                CURLOPTTYPE_(?<type>\S+) \s* , \s*
                (?<number>\d+) \s*
            ,
            |
            CINIT \s* \(
                (?<option>\S+) \s* , \s*
                (?<type>\S+) \s* , \s*
                (?<number>\d+) \s*
            \)
        )
    /xg) {
    my ($option, $type, $number)= @+{qw/option type number/};
    next unless $option;

    next if $curlopt_skip{$option};

    if ($type eq 'STRINGPOINT') {
        print $strings <<EOC;
#if LIBCURL_HAS(CURLOPT_$option)
    case CURLOPT_$option:
#endif
EOC
    } elsif ($type eq 'LONG' or $type eq 'VALUES') {
        print $longs <<EOC
#if LIBCURL_HAS(CURLOPT_$option)
    case CURLOPT_$option:
#endif
EOC
    } elsif ($type eq 'OFF_T') {
        print $offt <<EOC
#if LIBCURL_HAS(CURLOPT_$option)
    case CURLOPT_$option:
#endif
EOC
    } elsif ($type eq 'SLISTPOINT') {
        print $slists <<EOC
#if LIBCURL_HAS(CURLOPT_$option)
    case CURLOPT_$option:
#endif
EOC
    } elsif ($type eq 'BLOB') {
        print $blobs <<EOC
#if LIBCURL_HAS(CURLOPT_$option)
    case CURLOPT_$option:
#endif
EOC
    } else {
        print STDERR "Ignoring unknown option CURLOPT_$option\n";
    }
}
