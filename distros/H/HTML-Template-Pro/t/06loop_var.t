use Test::More no_plan;
use HTML::Template::Pro;

my $src_name =<<"END;";
<TMPL_IF NAME="foo">
name foo
</TMPL_IF>
END;

my $src_expr_1 =<<"END;";
<TMPL_IF EXPR="foo">
[<TMPL_VAR EXPR="foo">]
name foo
</TMPL_IF>
END;

my $src_expr_2 =<<"END;";
<TMPL_IF EXPR="foo or bar">
name foo
</TMPL_IF>
END;
my $template_name   = HTML::Template::Expr->new(scalarref => \$src_name);
my $template_expr_1 = HTML::Template::Expr->new(scalarref => \$src_expr_1);
my $template_expr_2 = HTML::Template::Expr->new(scalarref => \$src_expr_2);

my $l = [ { x => 1} ];

$template_expr_1->param(foo => 1);
like($template_expr_1->output(), qr/name foo/i, "expr foo with scalar");
$template_expr_1->param(foo => $l);
like($template_expr_1->output(), qr/name foo/i, "expr foo with arrayref");

$template_name->param(foo => 1);
like($template_name->output(), qr/name foo/i, "name foo with scalar");
$template_name->param(foo => [ { x => 1} ]);
like($template_name->output(), qr/name foo/i, "name foo with arrayref");

$template_expr_1->param(foo => 1);
like($template_expr_1->output(), qr/name foo/i, "expr foo with scalar");
$template_expr_1->param(foo => [ { x => 1} ]);
like($template_expr_1->output(), qr/name foo/i, "expr foo with arrayref");

$template_expr_2->param(foo => 1);
like($template_expr_2->output(), qr/name foo/i, "expr foo_or_bar with scalar");
$template_expr_2->param(foo => [ { x => 1} ]);
like($template_expr_2->output(), qr/name foo/i, "expr foo_or_bar with arrayref");

__END__



