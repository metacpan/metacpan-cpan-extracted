use Test::More tests => 3;
BEGIN { use_ok('HTML::Template::Compiled') };

use File::Spec;
my $cache = File::Spec->catfile('t', 'cache');
HTML::Template::Compiled->clear_filecache($cache);

test_defined();
test_double_else();
sub test_defined {
	my ($type, $clearcache) = @_;
	my $str = <<'EOM';
<tmpl_if_defined undef>WRONG<tmpl_elsif undef>WRONG<tmpl_else>RIGHT</tmpl_if>
<tmpl_if_defined zero>RIGHT<tmpl_elsif zero>WRONG<tmpl_else>RIGHT</tmpl_if>
<tmpl_if_defined true>RIGHT<tmpl_elsif true>RIGHT<tmpl_else>WRONG</tmpl_if_defined>
<tmpl_if_defined true>RIGHT</tmpl_if_defined>
EOM
	my $htc = HTML::Template::Compiled->new(
		path => 't/templates',
		scalarref => \$str,
		#debug => 1,
	);
	$htc->param(
		'undef' => undef,
		'zero' => 0,
		'true' => 'a true value',
	);
	my $out = $htc->output;
    #print $out;
	my @right = $out =~ m/RIGHT/g;
	my @wrong = $out =~ m/WRONG/g;
	ok(@right == 4 && @wrong == 0, "if defined");
}

sub test_double_else {
    my $text = qq{Before.  <TMPL_IF NAME="TEST">
    1.  <TMPL_ELSE>
    2.  <TMPL_ELSE>
    3.  </TMPL_IF> After.};

    eval {
        my $template = HTML::Template::Compiled->new(
            debug => 1,
            scalarref => \$text,
        );
    };
    #print $@, $/;
    like($@, qr/\Q'TMPL_ELSE' does not match opening tag (ELSE)/,
        "including 2 <tmpl_else> tags for one tmpl_if should throw an error");
}


