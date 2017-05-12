use Test::More tests => 2;

use HTML::Strip;

subtest "reset off" => sub {
    plan tests => 2;

    my $hs = HTML::Strip->new; # auto_reset off by default
    my $o = $hs->parse( "<html>\nTitle\n<script>a+b\n" );
    is( $o, "\nTitle\n" );
    my $o2 = $hs->parse( "c+d\n</script>\nEnd\n</html>" );
    is( $o2, "\nEnd\n" );
};

subtest "reset on" => sub {
    plan tests => 2;

    my $hs = HTML::Strip->new( auto_reset => 1 ); # auto_reset on
    my $o = $hs->parse( "<html>\nTitle\n<script>a+b\n" );
    is( $o, "\nTitle\n" );
    my $o2 = $hs->parse( "c+d\n</script>\nEnd\n</html>" );
    is( $o2, "c+d\n\nEnd\n" );
};
