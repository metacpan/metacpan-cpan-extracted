#!perl -T

use Test::More tests => 184;

use HTML::DTD;
ok( my $html_dtd = HTML::DTD->new(),
    "new()" );

my @dtd = sort qw(
             html-0.dtd
             html-1.dtd
             html-1s.dtd
             html-2-strict.dtd
             html-2.dtd
             html-3-2.dtd
             html-3-strict.dtd
             html-3.dtd
             html-4-0-1-frameset.dtd
             html-4-0-1-loose.dtd
             html-4-0-1-strict.dtd
             html-4-frameset.dtd
             html-4-loose.dtd
             html-4.strict.dtd
             html-cougar.dtd
             html.dtd
             xhtml1-frameset.dtd
             xhtml1-strict.dtd
             xhtml1-transitional.dtd
             xhtml11.dtd
           );

is_deeply( [ $html_dtd->dtds ], \@dtd,
           "Expected DTDs are available from object method dtds()" );

is_deeply( [ HTML::DTD->dtds ], \@dtd,
           "Expected DTDs are available from class method dtds()" );

is_deeply( [ HTML::DTD->dtds ], \@dtd,
           "Expected DTDs are available from function dtds()" );

for my $share ( @dtd )
{
    ok( $html_dtd->get_dtd($share),
        qq{Object method get_dtd("$share")} );
    ok( $html_dtd->get_dtd_fh($share),
        qq{Object method get_dtd_fh("$share")} );
    ok( $html_dtd->get_dtd_path($share),
        qq{Object method get_dtd_path("$share")} );
    ok( HTML::DTD->get_dtd($share),
        qq{Class method get_dtd("$share")} );
    ok( HTML::DTD->get_dtd_fh($share),
        qq{Class method get_dtd_fh("$share")} );
    ok( HTML::DTD->get_dtd_path($share),
        qq{Class method get_dtd_path("$share")} );
    ok( HTML::DTD::get_dtd($share),
        qq{Function get_dtd("$share")} );
    ok( HTML::DTD::get_dtd_fh($share),
        qq{Function get_dtd_fh("$share")} );
    ok( HTML::DTD::get_dtd_path($share),
        qq{Function get_dtd_path("$share")} );
}




__END__

