use strict;
use Test::More;

BEGIN {
    eval "use Encode qw( _utf8_on is_utf8 );";
    if ($@) {
        plan skip_all => "Encode module not available";
    }
    else {
        plan tests => 5;
    }
    use_ok('Lingua::StopWords');
}

my $stoplist = Lingua::StopWords::getStopWords( 'fr', 'UTF-8' );
my $utf8_ete = "Ã©tÃ©";
_utf8_on($utf8_ete);
ok( $stoplist->{$utf8_ete}, "UTF-8 encoded version present in stoplist" );
for ( keys %$stoplist ) {
    ok( is_utf8($_), "the stoplist keys are flagged as UTF-8" );
    last;
}

$stoplist = Lingua::StopWords::getStopWords('fr');
ok( $stoplist->{"été"}, "Non-utf8-flagged version present" );
for ( keys %$stoplist ) {
    ok( !is_utf8($_), "the stoplist keys are not flagged as UTF-8" );
    last;
}

