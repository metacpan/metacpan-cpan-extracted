use strict;
use warnings;
use utf8;
use Test::More tests => 1;

use Lingua::JA::Gal;

my $kanjionly = sub {
    my ($char, $suggestions, $options) = @_;
    
    if ($char =~ /\p{Han}/) {
        return $suggestions->[ int(rand @$suggestions) ];
    } else {
        return $char;
    }
};

is( Lingua::JA::Gal->gal('WCはお便所！', { callback => $kanjionly }), 'WCはおｲ更戸斤！' );
