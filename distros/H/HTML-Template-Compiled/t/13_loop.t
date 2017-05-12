use Test::More tests => 10;
BEGIN { use_ok('HTML::Template::Compiled') };
use lib 't';
use HTC_Utils qw($tdir &cdir &create_cache &remove_cache);
my $cache_dir = "cache13";
$cache_dir = create_cache($cache_dir);

for my $new_alias (0,1) {
    local $HTML::Template::Compiled::Compiler::DISABLE_NEW_ALIAS = 1 unless ($new_alias);
	my $htc = HTML::Template::Compiled->new(
		scalarref => \<<"EOM",
<tmpl_loop array alias=iterator>
<tmpl_var iterator>
<tmpl_var \$iterator>
</tmpl_loop>
<tmpl_loop array2 alias=iterator>
<tmpl_var iterator.foo>
<tmpl_var \$iterator.foo>
</tmpl_loop>
EOM
		debug => 0,
        loop_context_vars => 1,
        cache => 0,
	);
    my $array = [];
    my $array2 = [];
    if ($new_alias) {
        $array = [qw(a b c)];
        $array2 = [{ foo => 'a' }, { foo => 'b' }, { foo => 'c' }];
    }
    else {
        $array = [{ '$iterator' => 'a' }, { '$iterator' => 'b' }, { '$iterator' => 'c' }];
        $array2 = [{ '$iterator' => { foo => 'a' } }, { '$iterator' => { foo => 'b' } }, { '$iterator' => { foo => 'c' } }];
    }
	$htc->param(
        array => $array,
        array2 => $array2,
    );
	my $out = $htc->output;
	$out =~ s/\s+//g;
    if ($new_alias) {
        cmp_ok($out, "eq", "aabbccaabbcc", "tmpl_loop array alias=iterator");
    }
    else {
        cmp_ok($out, "=~", qr{HASH\(.*\)aHASH\(.*\)bHASH\(.*\)cabc}, "tmpl_loop array alias=iterator");
    }
	#print "out: $out\n";
}
my $text1 = <<'EOM';
<tmpl_loop array>|
<tmpl_if __outer__>(outer:<tmpl_var __outer__>)</tmpl_if>
<tmpl_if __even__>(even:<tmpl_var __even__>)</tmpl_if>
<tmpl_var __counter__>
<tmpl_var _.x>
</tmpl_loop>
EOM
for (0,1) {
	my $htc = HTML::Template::Compiled->new(
		scalarref => \$text1,
        debug => 0,
        loop_context_vars => $_,
	);
	$htc->param(array => [
        {x=>"a","__counter__"=>"A","__outer__"=>"OUTER"},
        {x=>"b","__counter__"=>"B","__even__"=>"EVEN"},
        {x=>"c","__counter__"=>"C",},
        {x=>"d","__counter__"=>"D",,"__even__"=>"EVEN"},
        {x=>"e","__counter__"=>"E","__outer__"=>"OUTER"},
    ]);
	my $out = $htc->output;
	$out =~ s/\s+//g;
	my $exp;
	if ($_ == 1) {
		$exp = "|(outer:1)1a|(even:1)2b|3c|(even:1)4d|(outer:1)5e";
	}
	else {
		$exp = "|(outer:OUTER)Aa|(even:EVEN)Bb|Cc|(even:EVEN)Dd|(outer:OUTER)Ee";
	}
	#print "($out)($exp)\n";
	cmp_ok($out, "eq", $exp, "loop context");
}

{
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<EOM,
<%loop list join=", " %><%= _ %><%/loop list %>
EOM
        debug => 0,
    );
    $htc->param(
        list => [qw(a b c)]
    );
    my $out = $htc->output;
    $out =~ s/^\s+//;
    $out =~ s/\s+\z//;
    #print $out, $/;
    cmp_ok($out, 'eq','a, b, c', "loop join attribute");
}

{
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<EOM,
<%loop list break="3" %><%= _ %><%if __break__%>.<%/if %><%/loop list %>
EOM
        debug => 0,
        loop_context_vars => 1,
    );
    $htc->param(
        list => [qw(a b c d e f g h)]
    );
    my $out = $htc->output;
    $out =~ s/^\s+//;
    $out =~ s/\s+\z//;
    #print $out, $/;
    cmp_ok($out, 'eq','abc.def.gh', "loop break attribute");
}

{
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<'EOM',
<%loop list %>
<%include loop_included.tmpl %>
<%/loop list %>
EOM
        debug => 0,
        loop_context_vars => 1,
        path => $tdir,
    );
    $htc->param(
        list => [qw(a b c d e f g h)]
    );
    my $out = $htc->output;
    $out =~ s/\s+/ /g;
    #print $out, $/;
    cmp_ok($out, 'eq',' 0 1 2 3 4 5 6 7 h ', "loop context vars in include");
}

for (0, 1) {
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<'EOM',
<%loop foo.list %>
<%= a %>
<%/loop foo.list %>
EOM
        debug => 0,
        loop_context_vars => 1,
        path => $tdir,
        cache => 0,
        file_cache => 1,
        file_cache_dir => $cache_dir,
    );
    $htc->param(
        foo => {
            list => [{a => 1},{a => 2},{a => 3}],
        },
    );
    my $out = $htc->output;
    $out =~ s/\s+/ /g;
    #print $out, $/;
    cmp_ok($out, 'eq',' 1 2 3 ', "loop " . ($_ ? "after" : "before") . " caching");
}

HTML::Template::Compiled->clear_filecache($cache_dir);
remove_cache($cache_dir);
