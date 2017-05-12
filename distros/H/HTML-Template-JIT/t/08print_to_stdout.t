my $debug = 0;

# fork to test printing to STDOUT
unless (open(TEST, '-|')) {
  require HTML::Template::JIT;
  $template = HTML::Template::JIT->new(filename => 'loop.tmpl',
                                       path => ['t/templates'],
                                       jit_path => 't/jit_path',
                                       jit_debug => $debug,
                                       print_to_stdout => 1,
                                      );
  $template->param(foo => "FOO");
  $template->param(bar => [ { val => 'foo' }, { val => 'bar' } ]);
  $template->output();
  exit;
}

eval "use Test::More tests => 2";
my $result = join('', <TEST>);
like($result, qr/foo: FOO/);
like($result, qr/bar: foo,bar,/);
