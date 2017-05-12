
use Test::More tests => 3;
BEGIN { use_ok('HTML::Template::Compiled') };
use lib 't';
use
HTC_Utils qw($cache $tdir &cdir);

{
	my $htc = HTML::Template::Compiled->new(
		scalarref => \<<'EOM',
<%set_var FOO value=.root.foo %>
<%= FOO %>
<%include var_include.html %>
EOM
		debug => 0,
        loop_context_vars => 1,
        path => $tdir,
	);
	$htc->param(
        root => {
            foo => 23,
        },
    );
	my $out = $htc->output;
	$out =~ s/\s+//g;
	cmp_ok($out, "eq", "2323", "set_var, use_vars");
	#print "out: $out\n";
}
{
    eval {
        my $htc = HTML::Template::Compiled->new(
            scalarref => \<<'EOM',
<%set_var name="foo bar" value=.root %>
EOM
            debug => 0,
            loop_context_vars => 1,
            path => $tdir,
        );
    };
    my $error = $@;
#    warn __PACKAGE__.':'.__LINE__.": $error\n";
	cmp_ok($error, "=~", ".*Syntax error in <TMPL_\\*>.*", "invalid set_var");
}

