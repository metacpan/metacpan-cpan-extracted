package t::lib::bar;

our $VERSION = 1;

use base 't::lib::foo';

use Method::Signatures::WithDocumentation;

method mbar :
    Purpose(
        mfoo_purpose
    )
{
    ...
}

1;
