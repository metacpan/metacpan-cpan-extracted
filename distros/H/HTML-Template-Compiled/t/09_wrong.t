# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Template-Compiled.t'

use Test::More tests => 11;
BEGIN { use_ok('HTML::Template::Compiled') };
eval {
	my $htc = HTML::Template::Compiled->new(
		scalarref => \<<'EOM',
		<tmpl_if foo>bar</tmpl_if>
		<%if foo %>bar<%/if%>
		<%if foo %>bar
EOM
		debug => $ENV{HARNESS_ACTIVE} ? 0 : 1,
		line_numbers => 1,
	);
};
print "err: $@\n" unless $ENV{HARNESS_ACTIVE};
ok($@ =~ m/Missing closing tag for 'IF'/, "premature end of template");
# test wrong balanced tag
my $wrong;
eval {
	$wrong = HTML::Template::Compiled->new(
		path => 't/templates',
		line_numbers => 1,
		filename => 'wrong.html',
		debug => $ENV{HARNESS_ACTIVE} ? 0 : 1,
	); 
};
print "err: $@\n" unless $ENV{HARNESS_ACTIVE};
ok($@ =~ m/does not match opening tag/ , "wrong template");

eval {
	my $htc = HTML::Template::Compiled->new(
		path => 't/templates',
		filename => 'notexist.htc',
		debug => $ENV{HARNESS_ACTIVE} ? 0 : 1,
	);
};
print "err: $@\n" unless $ENV{HARNESS_ACTIVE};
ok($@ =~ m/not found/ , "template not found");

eval {
	my $str = <<'EOM';
<tmpl_include name="notexist.htc">
EOM
	my $htc = HTML::Template::Compiled->new(
		path => 't/templates',
		scalarref => \$str,
		debug => $ENV{HARNESS_ACTIVE} ? 0 : 1,
	);
};
print "err: $@\n" unless $ENV{HARNESS_ACTIVE};
ok($@ =~ m/not found/ , "template from include not found");


{
    my @wrong = (
        "<TMPL_VA foo>",
        "<TMPL_VAR foo oops>",
        "<TMPL_IF blah escape=html>",
        "foo<TMPL_IF >",
    );
    for my $wrong (@wrong) {
        eval {
            my $htc = HTML::Template::Compiled->new(
                scalarref => \$wrong,
                debug => 0,
            );
        };
        print STDERR "Error? $@\n" unless $ENV{HARNESS_ACTIVE};;
        cmp_ok($@, "=~", qr{\Q: Syntax error in <TMPL_*> tag at }, "die when syntax is wrong");
    }
}

{
    my $tmpl = <<"EOM";
<tmpl_var foo>
<tmpl_foo
<tmpl_var foo>
end
EOM
    for my $strict (0, 1) {
        my $out = '';
        eval {
            my $htc = HTML::Template::Compiled->new(
                scalarref => \$tmpl,
                strict => $strict,
            );
            $htc->param(foo => 23);
            $out = $htc->output;
        };
        my $err = $@;
        if ($strict) {
            cmp_ok($err, '=~', qr{\Q Syntax error in <TMPL_*> tag at }, "unknown tag strict");
        }
        else {
            $out =~ s/\s+/ /g;
            my $exp = '23 <tmpl_foo 23 end ';
            cmp_ok($out, 'eq', $exp, "unknown tag no strict");
        }
    }

}
