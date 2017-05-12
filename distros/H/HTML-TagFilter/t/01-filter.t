use strict;
use Test::More;

BEGIN {
    plan (tests => 17);
    use_ok('HTML::TagFilter');
}

my $tf = HTML::TagFilter->new(
	log_rejects => 1,
	strip_comments => 0,
	echo => 0,
);
my $tf2 = HTML::TagFilter->new(
	log_rejects => 0,
	strip_comments => 1,
	rubbish => 0,
);
my $tf3 = HTML::TagFilter->new( 
	allow => { 
	    p => { class=> [qw(lurid sombre plain)] },
    },
);
my $tf4 = HTML::TagFilter->new( 
	deny => { 
	    p => { any => [] },
	    a => { all => [] },
	},
);
my $tf5 = HTML::TagFilter->new(
	skip_mailto_entification => 1, 
	skip_ltgt_entification => 1, 
);

ok( $tf, 'tagfilter object configured and constructed' );
is( $tf->filter("<p>testing</p>"), "<p>testing</p>", "default tag allowance" );
is( $tf->filter("<blink>testing</blink>"), "testing", "default tag denial");
is( $tf->filter(qq|<p nonsense="rubbish">testing</p>|), "<p>testing</p>", "default attribute denial");
is( $tf->filter(qq|<p align="rubbish">testing</p>|), "<p>testing</p>", "default value denial");
$tf->clear_rules();
is( $tf->filter(qq|<p>testing</p>|), "testing", "rules cleared: everything stripped");
my $report = $tf->report;
ok( $report =~ /&lt;p&gt;/, "removal logging");
my $error = $tf2->error;
ok( $error =~ /rubbish/, "error report" );
is( $tf->filter("<p>testing</p><!--hey-->"), "testing&lt;!--hey--&gt;", "comment permitted, < > escaped");
is( $tf2->filter("<p>testing</p><!--hey-->"), "<p>testing</p>", "comment deleted" );
is( $tf2->report, undef, "report properly empty");
is( $tf3->filter(qq|<p class="lurid"><p class="rubbish">testing</p></p>|), qq|<p class="lurid"><p>testing</p></p>|, "manually permitted attribute remains: others removed.");
is( $tf4->filter(qq|<a class="lurid"><b>testing</b></a>|), qq|<b>testing</b>|, "manually forbidden tag removed: others permitted" );
is( $tf4->filter(qq|<p class="lurid"><b>testing</b></p>|), qq|<p><b>testing</b></p>|, "manually forbidden attribute removed: others permitted" );
is( $tf2->filter(qq|<img src="1" height="2" width="3" alt="4" align="5">|), qq|<img src="1" height="2" width="3" alt="4" align="5">|, "attribute order preserved" );
is( $tf2->filter(qq|<h1 none="javascript:alert(1)">oops</h1>|), qq|<h1>oops</h1>|, "none is magic" );


