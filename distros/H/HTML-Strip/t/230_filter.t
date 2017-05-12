use Test::More tests => 2;

use HTML::Strip;

subtest "no filter" => sub {
    plan tests => 1;

    my $hs = HTML::Strip->new( filter => undef );
    ok( $hs->parse( '<html>&nbsp;</html>' ), '&nbsp;' );
    $hs->eof;
};

subtest "whitespace filter" => sub {
    plan tests => 1;

    my $filter = sub { my $s = shift; $s =~ s/\s/ /g;; $s };
    my $hs = HTML::Strip->new( filter => $filter );
    ok( $hs->parse( "<html>title\ntext\ntext</html>" ), 'title text text' );
    $hs->eof;
};
