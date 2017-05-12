# ============================================================================
package Mail::Builder::Utils;
# ============================================================================
use strict;
use warnings;
use utf8;

use Encode qw/encode/;

sub encode_mime {
    my ($string) = @_;

    return $string
        if $string !~ m/[^\x00-\x7f]|["']|=\?|\?=/;
    return encode('MIME-Header', $string);
}

1;