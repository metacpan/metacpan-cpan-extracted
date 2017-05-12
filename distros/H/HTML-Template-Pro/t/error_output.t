#!/usr/bin/perl -w
use Test::More no_plan;
use HTML::Template::Pro;

my $src1 =<<"END;";
</TMPL_IF>
<tmpl_var EXPR="(a/(foo&&&">
<TMPL_IF NAME="foo>
<TMPL_FI NAME="foo>
name foo
END;

my $template1   = HTML::Template::Pro->new(scalarref => \$src1, debug=> -1);
$template1->param(foo => 1);
my $out=$template1->output();
#print $out;
ok(1); # not crashed

__END__
