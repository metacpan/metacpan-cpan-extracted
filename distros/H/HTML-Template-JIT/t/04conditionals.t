use Test::More tests => 11;
use HTML::Template::JIT;

my $debug = 0;

# try some looping
$template = HTML::Template::JIT->new(filename => 'cond.tmpl',
				     path => ['t/templates'],
				     jit_path => 't/jit_path',
				     jit_debug => $debug,
				    );
$template->param(true => 1);
$template->param(false => 0);
$template->param(true_loop => [ { var => 'foo' } ]);
$template->param(false_loop => [] );
$template->param(values => [ { value => 2, even => 1 },
			     { value => 3, even => 0 },
			     { value => 10, even => 1 },
			   ]);
$output = $template->output();

like($output, qr/foo: foo\./); 
like($output, qr/bar: bar\./);
like($output, qr/black: dark\./); 
like($output, qr/white: light\./); 
like($output, qr/bing: bong\./);
ok($output !~ qr/bing: boom\./);
like($output, qr/sam was here\./);
like($output, qr/sam wuz here\./);
like($output, qr/2 is even/);
like($output, qr/3 is odd/);
like($output, qr/10 is even/);
print $output;
