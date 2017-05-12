use strict;
use Test::More;
use HTML::TagFilter;

BEGIN {
    plan (tests => 7);
}

my $tf = HTML::TagFilter->new(
	log_rejects => 0,
	strip_comments => 1,
);

my $tf2 = HTML::TagFilter->new(
	skip_mailto_entification => 1, 
	skip_ltgt_entification => 1, 
);

is( $tf->filter(qq|<a name="&quot;></a><script>alert(1)</script><i foo=&quot;">hello</i>|), qq|<a name="&quot;&gt;&lt;/a&gt;&lt;script&gt;alert(1)&lt;/script&gt;&lt;i foo=&quot;">hello</i>|, "quote unquote loophole closed");
is( $tf->filter(qq|<img src="javascript:alert(1)">|), qq|<img>|, "malicious src attribute stripped out");
is( $tf->filter(qq|<a href="javascript:alert(1)">hello</a>|), qq|<a>hello</a>|, "malicious href attribute stripped out");
is( $tf->filter(qq|<a href="mailto:wross\@cpan.org">will</a>|), qq|<a href="mailto:%77%72%6F%73%73%40%63%70%61%6E%2E%6F%72%67">will</a>|, "mailto obfuscated");
is( $tf2->filter(qq|<a href="mailto:wross\@cpan.org">will</a>|), qq|<a href="mailto:wross\@cpan.org">will</a>|, "mailto obfuscation switched off");
is( $tf->filter(qq|<p>What's this --></p>|), qq|<p>What&#39;s this --&gt;</p>|, "angle and ' entified");
is( $tf2->filter(qq|<p>What's this --></p>|), qq|<p>What's this --></p>|, "entification switched off");
