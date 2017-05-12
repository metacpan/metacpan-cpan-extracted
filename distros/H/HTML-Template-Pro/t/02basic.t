use Test::More tests => 3;
use HTML::Template::Pro;

my $template = HTML::Template::Expr->new(path => ['t/templates'],
                                      filename => 'foo.tmpl');
$template->param(foo => 100);
my $output = $template->output();
like($output, qr/greater than/i, "greater than");

$template->param(foo => 10);
$output = $template->output();
like($output, qr/less than/i, "less than");


$template = HTML::Template::Expr->new(path => ['t/templates'],
                                      filename => 'negative.tmpl');
$template->param(foo => 100);
$output = $template->output();
like($output, qr/Yes/, "negative numbers work");
