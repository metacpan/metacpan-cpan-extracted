package Judy::SL;

use strict;
use warnings;

require Judy;

use Config ();
use constant ptrsize => $Config::Config{ptrsize};

sub dump {
    return $_[0]->dumpSL( $_[0]->ptr );
}

sub dumpSL {
    if ( $_[1] & Judy::JLAP_INVALID() ) {
        return $_[0]->dumpPscl( $_[0] & ~Judy::JLAP_INVALID() );
    }
    else {
        $_[0]->dumpL( $_[1] );
    }
}
sub dumpPscl {
    my $val = Judy::Mem::Peek( $_[1] );
    return sprintf qq{(Pscl_t 0x%x 0x%x "%s")},
        $_[1],
        $val,
        cstring( Judy::Mem::Ptr2String( ptrsize() + $_[1] ) );
}
sub dumpL {
    my $dump = sprintf '(JudyL 0x%x', $_[1];
    
    my ( $pval, $val, $key ) = Judy::L::First( $_[1], 0 );
    while ( $pval ) {
        $dump .= sprintf ' :%d (0x%x %d', $key, $pval, $val;
        $dump .= $_[0]->dumpSL( $val );
        ( $pval, $val, $key ) = Judy::L::Next( $_[1], $key );
    }

    return "$dump)";
}

1;
