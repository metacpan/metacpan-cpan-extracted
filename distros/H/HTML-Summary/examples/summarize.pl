eval 'exec perl -w -S $0 ${1+"$@"}' if 0; # not running under some shell

use HTML::Summary;
use HTML::TreeBuilder;

sub cat( $ ) {
    local $/ = undef;
    open( FH, shift ) or return '';
    my $text = <FH>;
    close( FH );
    return $text;
}

my $tree = new HTML::TreeBuilder;
$tree->parse( cat shift );
my $summary = ( new HTML::Summary USE_META => 1 )->generate( $tree );
print $summary;
