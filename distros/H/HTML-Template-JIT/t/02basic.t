use Test::More tests => 3;
use HTML::Template::JIT;

my $debug = 0;

# try a simple var
my $template = HTML::Template::JIT->new(filename => 'basic.tmpl',
					path => ['t/templates'],
					jit_path => 't/jit_path',
					jit_debug => $debug,
				       );
$template->param(foo => 'foo!');
my $output = $template->output();
like($output, qr/I say foo!/);

# run it again - suss out caching errors
$template = HTML::Template::JIT->new(filename => 'basic.tmpl',
				     path => ['t/templates'],
				     jit_path => 't/jit_path',
				     jit_debug => $debug,
				    );
$template->param(foo => 'bar!');
$output = $template->output();
like($output, qr/I say bar!/);

# run it again with no params set - make sure its not saving values
$template = HTML::Template::JIT->new(filename => 'basic.tmpl',
				     path => ['t/templates'],
				     jit_path => 't/jit_path',
				     jit_debug => $debug,
				    );
$output = $template->output();
ok($output !~ qr/I say bar!/);

