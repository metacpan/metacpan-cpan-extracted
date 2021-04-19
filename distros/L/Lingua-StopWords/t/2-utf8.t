use strict;
use Test::More;

use utf8;

use lib qw(../lib/);

use Test::More;
use Test::More::UTF8;

BEGIN {
    eval "use Encode qw( is_utf8 encode);";
    if ($@) {
        plan skip_all => "Encode module not available";
    }
    use_ok('Lingua::StopWords');
}

my $tests = [
    [qw(da når  iso-8859-1)],
    [qw(de für  iso-8859-1)],
    [qw(en our  iso-8859-1)],
    [qw(es qué  iso-8859-1)],
    [qw(fi minä iso-8859-1)],
    [qw(fr été  iso-8859-1)],
    [qw(hu elő  iso-8859-2)],
    [qw(it più  iso-8859-1)],
    [qw(id dia  iso-8859-1)],
    [qw(nl hij  iso-8859-1)],
    [qw(no på   iso-8859-1)],
    [qw(ro ăla  iso-8859-2)],
    [qw(pt não  iso-8859-1)],
    [qw(ru все  KOI8-R)],
    [qw(sv för  iso-8859-1)],
];


for my $test ( @{$tests} ) {
    my ($language, $word, $encoding) = @$test;
    my $stoplist = Lingua::StopWords::getStopWords( $language, 'UTF-8' );
    ok( $stoplist->{$word}, "UTF-8 encoded version present in stoplist [$language]" );

    for my $key ( keys %$stoplist ) {
        $key .= 'å'; # upgrades pure ASCII to UTF-8
        $key =~ s/å$//;
        ok( is_utf8($key), "the stoplist keys of [$language] are flagged as UTF-8" );
        last;
    }

    $stoplist = Lingua::StopWords::getStopWords($language);
    my $octet = encode($encoding, $word);
    ok( $stoplist->{$octet}, "Non-utf8-flagged version of [$language] present" );

    for ( keys %$stoplist ) {
        ok( !is_utf8($_), "the stoplist keys of [$language] are not flagged as UTF-8" );
        last;
    }
}

done_testing;
