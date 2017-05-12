use strict;
use warnings;
use Test::More tests => 19;
BEGIN { use_ok('HTML::Template::Compiled') };

use lib 't';
use HTC_Utils qw($tdir &cdir &create_cache &remove_cache);
my $cache_dir = "cache06";
$cache_dir = create_cache($cache_dir);
my $htc = HTML::Template::Compiled->new(
	path => 't/templates',
	filename => 'dyn_include.htc',
#	debug => 1,
#    cache_debug => 1,
    file_cache => 1,
    file_cache_dir => $cache_dir,
);
#exit;
for my $ix (1..2,undef) {
    for my $count (1..2) {
	$htc->param(
        file => (defined $ix? "dyn_included$ix.htc" : undef),
		test => 23,
	);
    my $out;
    eval {
        $out = $htc->output;
    };
    if (defined $ix) {
        #print $out;
        $out =~ s/\r\n|\r/\n/g;
        cmp_ok($out, "=~",
            "Dynamic include:", "dynamic include $ix.1");
        cmp_ok($out, "=~", "This is dynamically included file $ix\.", "dynamic include $ix.2");
        cmp_ok($out, "=~", "23", "dynamic include $ix.3");
    }
    else {
        #print "Error: $@\n";
        #print "out: $out\n";
        cmp_ok($out, "=~", 'Dynamic include:\s+$', "undefined filename");
    }
}
}

{
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<'EOM',
inc: <%include_string foo %>
EOM
        debug => 0,
    );
    $htc->param(
        foo => 'included=<%= bar%>',
        bar => 'real',
    );
    my $out = $htc->output;
    #print "out: $out\n";
    my $exp = 'inc: included=real';
    cmp_ok($out, '=~', $exp, "include_string");
}

{
    my $htc;
    eval {
        $htc = HTML::Template::Compiled->new(
            filename => 'user_template.html',
            path => 't/templates',
            no_includes => 1,
        );
    };
    my $error = "$@";
    cmp_ok($error, '=~', 'Syntax error.*near.*include', "no_includes");
}

{
    my $htc = HTML::Template::Compiled->new(
        filename => "wrapped.html",
        path => 't/templates',
#        debug => 1,
        loop_context_vars => 1,
        cache => 0,
    );
    $htc->param(
        foo => 23,
    );
    my $out = $htc->output;
    my $exp = <<"EOM";
wrapper:
<head>
wrapped in wrapper.html: foo: 23
  <head2>wrapped in wrapper2.html: foo2: 23</head2>

    <head>wrapped in wrapper1.html: foo1: 23</head>

</head>
EOM
    #warn __PACKAGE__.':'.__LINE__.": $out\n";
    for ($out, $exp) {
        s/[\r\n]/ /g;
        tr/ / /s;
    }
    cmp_ok($out, 'eq', $exp, "wrapper");
    $out = File::Spec->catfile('t', 'templates', 'out_fh.htc.output06');
	open my $fh, '>', $out or die $!;
    $htc = HTML::Template::Compiled->new(
        filename => "wrapped.html",
        path => 't/templates',
#        debug => 1,
        loop_context_vars => 1,
        cache => 0,
        out_fh => 1,
    );
    $htc->param(
        foo => 23,
    );
	$htc->output($fh);
    close $fh;
    open $fh, "<", $out or die $!;
    my $out2 = do { local $/; <$fh> };
    #warn __PACKAGE__.':'.__LINE__.": $out2\n";
    for ($out2) {
        s/[\r\n]/ /g;
        tr/ / /s;
    }
    cmp_ok($out2, 'eq', $exp, "wrapper out_fh");
    unlink $out;
}

HTML::Template::Compiled->clear_filecache($cache_dir);
remove_cache($cache_dir);
__END__
Dynamic include:
This is dynamically included file 1.
23
