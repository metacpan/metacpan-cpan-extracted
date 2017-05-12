use Test::More tests => 4;
use HTML::Template::JIT;

my $debug = 0;

my $template = HTML::Template::JIT->new(                                
					path => ['t/templates'],
					filename => 'globals.tmpl',
					global_vars => 1,
					jit_path => 't/jit_path',
					jit_debug => $debug,
				       );
$template->param(outer_loop => [{loop => [{'LOCAL' => 'foo'}]}]);
$template->param(global => 'bar');
$template->param(hidden_global => 'foo');
my $result = $template->output();
like($result, qr/Some local data foobar/);
like($result, qr/Something global, but hidden Hidden!/);


# test global_vars for loops within loops
$template = HTML::Template::JIT->new(path => ['t/templates'],
				     filename => 'global-loops.tmpl',
				     global_vars => 1,
				     jit_path => 't/jit_path',
				     jit_debug => $debug);
$template->param(global => "global val");
$template->param(outer_loop => [
				{ 
				 foo => 'foo val 1',
				 inner_loop => [
						{ bar => 'bar val 1' },
						{ bar => 'bar val 2' },
					       ],
				},
				{
				 foo => 'foo val 2',
				 inner_loop => [
						{ bar => 'bar val 3' },
						{ bar => 'bar val 4' },
					       ],
				}
			       ]);
my $output = $template->output;
like($output, qr/inner loop foo:    foo val 1/);
like($output, qr/inner loop foo:    foo val 2/);
