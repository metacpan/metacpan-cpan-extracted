# ----------------------------------------------------------------
    use strict;
    use Test::More qw(no_plan);
# ----------------------------------------------------------------
    my $FILE = 't/sample.utf8';
# ----------------------------------------------------------------
{
    use_ok('Lingua::KO::Romanize::Hangul');
    my $roman = Lingua::KO::Romanize::Hangul->new();
    &test_ko( $roman );
}
# ----------------------------------------------------------------
sub read_data {
    ok( -r $FILE, $FILE );
    open( SAMPLE, $FILE ) or exit;
    local $/ = undef;
    my $all = <SAMPLE>;
    close( SAMPLE );
    my $list = [ split( /\s+/, $all ) ];
    $list;
}
# ----------------------------------------------------------------
sub test_ko {
    my $roman = shift;
    ok( ref $roman, "new" );
    my $t = &read_data();

    for( my $i=0; $i<$#$t; $i+=2 ) {
        my $hangul = $t->[$i];
        my $ascii  = $t->[$i+1];
        my $copy   = $ascii;
        $copy =~ tr/A-Z/a-z/;
        $copy =~ s/[^a-z]+//g;
        
        my $gen = $roman->chars( $hangul );
        $gen =~ s/\W+//g;
        is( $gen, $copy, "chars: [$hangul] $ascii" );
    }
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
