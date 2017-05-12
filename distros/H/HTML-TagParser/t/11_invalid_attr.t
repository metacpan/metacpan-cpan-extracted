# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 52;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $SOURCE1 = <<EOT;
<html>
    <br class= "foobar">
    <br class ="foobar">
    <br class = "foobar">
    <br class= 'foobar'>
    <br class ='foobar'>
    <br class = 'foobar'>
    <br class= foobar>
    <br class =foobar>
    <br class = foobar>
</html>
EOT
# ----------------------------------------------------------------
    my $SOURCE2 = <<EOT;
<html>
    <br class= "foobar"clear="all">
    <br class ="foobar" clear= "all" >
    <br class = "foobar"clear ="all">
    <br class= 'foobar'clear='all'>
    <br class ='foobar' clear= 'all'>
    <br class = 'foobar'clear ='all'>
    <br class= foobar clear=all>
    <br class =foobar clear= all>
    <br class = foobar clear =all>
</html>
EOT
# ----------------------------------------------------------------
    my $SOURCE3 = <<EOT;
<html>
    <br class= "foobar"nowrap>
    <br class ="foobar"nowrap>
    <br class = "foobar"nowrap>
    <br class= 'foobar'nowrap>
    <br class ='foobar'nowrap>
    <br class = 'foobar'nowrap>
    <br class= foobar nowrap>
    <br class =foobar nowrap>
    <br class = foobar nowrap>
</html>
EOT
# ----------------------------------------------------------------
    my $html1 = HTML::TagParser->new();
    my $num1 = $html1->parse( $SOURCE1 );
    ok( $num1, "SOURCE1 - parse()" );
    my @list = $html1->getElementsByTagName( 'br' );
    is( scalar(@list), 9, "SOURCE1 - 9 br" );
    foreach my $elem ( @list ) {
        my $class = $elem->getAttribute( 'class' );
        is( $class, 'foobar', "SOURCE1 - class=foobar" );
    }
# ----------------------------------------------------------------
    my $html2 = HTML::TagParser->new();
    my $num2 = $html2->parse( $SOURCE2 );
    ok( $num2, "SOURCE2 - parse()" );
    my @list2 = $html2->getElementsByTagName( 'br' );
    is( scalar(@list2), 9, "SOURCE2 - 9 br" );
    foreach my $elem ( @list2 ) {
        my $class = $elem->getAttribute( 'class' );
        is( $class, 'foobar', "SOURCE2 - class=foobar" );
        my $clear = $elem->getAttribute( 'clear' );
        is( $clear, 'all', "SOURCE2 - clear=all" );
    }
# ----------------------------------------------------------------
    my $html3 = HTML::TagParser->new();
    my $num3 = $html3->parse( $SOURCE3 );
    ok( $num3, "SOURCE3 - parse()" );
    my @list3 = $html3->getElementsByTagName( 'br' );
    is( scalar(@list3), 9, "SOURCE3 - 9 br" );
    foreach my $elem ( @list3 ) {
        my $class = $elem->getAttribute( 'class' );
        is( $class, 'foobar', "SOURCE3 - class=foobar" );
        my $nowrap = $elem->getAttribute( 'nowrap' );
        is( $nowrap, 'nowrap', "SOURCE3 - nowrap" );
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
