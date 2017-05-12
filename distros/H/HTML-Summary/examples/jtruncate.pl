eval 'exec perl -w -S $0 ${1+"$@"}' if 0; # not running under some shell

use Lingua::JA::Jtruncate;

sub cat( $ ) {
    local $/ = undef;
    open( FH, shift ) or return '';
    my $text = <FH>;
    close( FH );
    return $text;
}

print jtruncate( cat shift, shift );
