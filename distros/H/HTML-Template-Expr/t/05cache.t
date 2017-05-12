use Test::More tests => 15;
use HTML::Template::Expr;
use strict;

my ($template, $output);

# first load
$template = HTML::Template::Expr->new(path => ['t/templates'],
                                      filename => 'numerics.tmpl',
				      cache => 1,
				      cache_debug => 0,
                                     );
$template->param(float => 5.1,
                 four => 4);
$output = $template->output;
like($output, qr/INT: 5/, "int()");
like($output, qr/SQRT: 2/, "sqrt()");
like($output, qr/SQRT2: 4/, "sqrt() 2");
like($output, qr/SUM: 14/, "int(4 + 10.1)");
like($output, qr/SPRINTF: 14.1000/, "sprintf('%0.4f', (10.1 + 4))");

# load from cache
$template = HTML::Template::Expr->new(path => ['t/templates'],
                                      filename => 'numerics.tmpl',
				      cache => 1,
				      cache_debug => 0,
                                     );
$template->param(float => 5.1,
                 four => 4);
$output = $template->output;
like($output, qr/INT: 5/, "int()");
like($output, qr/SQRT: 2/, "sqrt()");
like($output, qr/SQRT2: 4/, "sqrt() 2");
like($output, qr/SUM: 14/, "int(4 + 10.1)");
like($output, qr/SPRINTF: 14.1000/, "sprintf('%0.4f', (10.1 + 4))");

# one more time...
$template = HTML::Template::Expr->new(path => ['t/templates'],
                                      filename => 'numerics.tmpl',
				      cache => 1,
				      cache_debug => 0,
                                     );
$template->param(float => 5.1,
                 four => 4);
$output = $template->output;
like($output, qr/INT: 5/, "int()");
like($output, qr/SQRT: 2/, "sqrt()");
like($output, qr/SQRT2: 4/, "sqrt() 2");
like($output, qr/SUM: 14/, "int(4 + 10.1)");
like($output, qr/SPRINTF: 14.1000/, "sprintf('%0.4f', (10.1 + 4))");
