eval 'exec perl -w -S $0 ${1+"$@"}' if 0; # not running under some shell

use Lingua::JA::Jcode;

sub cat( $ ) {
    local $/ = undef;
    open( FH, shift ) or return '';
    my $text = <FH>;
    close( FH );
    return $text;
}

my $jtext = cat shift;
my $code = shift;

Lingua::JA::Jcode::convert( \$jtext, $code );
print $jtext;
