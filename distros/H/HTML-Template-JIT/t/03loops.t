use Test::More tests => 9;
use HTML::Template::JIT;

my $debug = 0;

# try some looping
$template = HTML::Template::JIT->new(filename => 'loop.tmpl',
				     path => ['t/templates'],
				     jit_path => 't/jit_path',
				     jit_debug => $debug,
				    );
$template->param(foo => "FOO");
$template->param(bar => [ { val => 'foo' }, { val => 'bar' } ]);
$output = $template->output();
like($output, qr/foo: FOO/);
like($output, qr/bar: foo,bar,/);

# loops within loops
$template = HTML::Template::JIT->new(filename => 'loop2.tmpl',
				     path => ['t/templates'],
				     jit_path => 't/jit_path',
				     jit_debug => $debug,
				    );
$template->param(outer => [
			   { 
			    outer_var => 10,
			    inner => [
				      { inner_var => 1 }, 
				      { inner_var => 1 },
				      { inner_var => 1 },
				      { inner_var => 1 },
				     ],
			   },
			   {
			    outer_var => 1,
			    inner => [
				      { inner_var => 10},
				      { inner_var => 10},
				      { inner_var => 10},
				      { inner_var => 10},
				     ],
			   }
			  ]);	


$output = $template->output();
like($output, qr/OUTER: 10/);
like($output, qr/OUTER: 1/);
like($output, qr/INNER: 10/);
like($output, qr/INNER: 1/);

# test a template using loop_context_vars
$template = HTML::Template::JIT->new(
				     filename => 't/templates/context.tmpl',
				     loop_context_vars => 1,
				     jit_path => 't/jit_path',
				     jit_debug => $debug,
				    );
$template->param(FRUIT => [
                           {KIND => 'Apples'},
                           {KIND => 'Oranges'},
                           {KIND => 'Brains'},
                           {KIND => 'Toes'},
                           {KIND => 'Kiwi'}
                          ]);
$template->param(PINGPONG => [ {}, {}, {}, {}, {}, {} ]);

$output =  $template->output;
like($output, qr/Apples, Oranges, Brains, Toes, and Kiwi./);
like($output, qr/pingpongpingpongpingpong/);

$template = HTML::Template::JIT->new(filename => 'loop.tmpl',
				     path => ['t/templates'],
 				     jit_path => 't/jit_path',
 				     jit_debug => $debug,
 				    );
$template->param(foo => "FOO");
$template->param(bar => [ bless({ val => 'foo' }, 'barfoo'),
                          bless({ val => 'bar' }, 'barbar') ]);
$output = $template->output();
like($output, qr/bar: foo,bar,/);
