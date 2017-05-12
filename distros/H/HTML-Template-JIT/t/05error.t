use Test::More tests => 3;
use HTML::Template::JIT;

my $debug = 0;

# try to generate an undef warning
$template = HTML::Template::JIT->new(filename => 'basic.tmpl',
				     path => ['t/templates'],
				     jit_path => 't/jit_path',
				     jit_debug => $debug,
				    );
my $output = $template->output();
my $foo;
$template->param(foo => $foo);
like($output, qr/I say /);

# try to fill a loop badly
eval {
  $template = HTML::Template::JIT->new(filename => 'loop.tmpl',
				       path => ['t/templates'],
				       jit_path => 't/jit_path',
				       jit_debug => $debug,
				      );
  $template->param(bar => [ 'foo', { val => 'bar' } ]);
  $output = $template->output();
};
like($@, qr/non hash-ref/);

eval {
  $template = HTML::Template::JIT->new(filename => 'loop.tmpl',
				       path => ['t/templates'],
				       jit_path => 't/jit_path',
				       jit_debug => $debug,
				      );
  $template->param(bar => 'foo');
  $output = $template->output();
};
like($@, qr/non array-ref/);
