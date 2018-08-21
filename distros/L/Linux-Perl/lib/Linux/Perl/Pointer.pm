package Linux::Perl::Pointer;

use constant UNPACK_TMPL => (4 == length pack 'P') ? 'L' : 'Q';

sub get_address {
    return unpack( UNPACK_TMPL(), pack( 'P', $_[0] ) );
}

1;
