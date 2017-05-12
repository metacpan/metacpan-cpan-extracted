use Test::More qw(no_plan);
use HTML::Template::Expr;

my $template = HTML::Template::Expr->new(path => ['t/templates'],
                                      filename => 'extra_attributes.tmpl',
                                     );
$template->param(who  => 'me & you',
                 xss  => '<SCRIPT SRC="MALICIOUS.JS" />',
                 back => 'http://google.com',
                 js_string => "This is\n'me'",);
my $output = $template->output();
like($output, qr/ME &amp; YOU/);
like($output, qr/&lt;script src=&quot;malicious\.js&quot; \/&gt;/);
like($output, qr/Http%3A%2F%2Fgoogle\.com/);
like($output, qr/this is\\n\\'me\\'/);

