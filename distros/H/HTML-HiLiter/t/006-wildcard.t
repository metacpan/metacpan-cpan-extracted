use strict;
use warnings;
use Test::More tests => 13;
use Data::Dump qw( dump );
use_ok('HTML::HiLiter');

my $html
    = qq{<p>a fancy word for <b>detox</b>? <br />demythylation is not.</p>};
for my $str (qw( *mythyl* fancy )) {
    ok( my $hiliter = HTML::HiLiter->new(

            #tty          => 1,
            query        => $str,
            print_stream => 0,
            fh           => \*STDERR,
        ),
        "new hiliter"
    );
    my $html_copy = $html;
    ok( my $hilited = $hiliter->run( \$html_copy ), "light()" );

    #diag($hilited);

    like( $hilited, qr/<span/, "hilited" );
}

for my $str (qw( *mythyl mythyl* )) {
    ok( my $hiliter = HTML::HiLiter->new(

            #tty          => 1,
            query        => $str,
            print_stream => 0,
            fh           => \*STDERR,
        ),
        "new hiliter"
    );
    my $html_copy = $html;
    ok( my $hilited = $hiliter->run( \$html_copy ), "light()" );

    #diag($hilited);

    unlike( $hilited, qr/<span/, "! hilited" );
}

