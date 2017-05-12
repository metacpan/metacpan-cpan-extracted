use Test::More tests => 3;
use HTML::Template::JIT;

my $debug = 0;

# make sure case is being ignored by default
my $template = HTML::Template::JIT->new(filename => 'basic.tmpl',
					path => ['t/templates'],
					jit_path => 't/jit_path',
					jit_debug => $debug,
				       );
$template->param(FoO => 'foo!');
my $output = $template->output();
like($output, qr/I say foo!/);

# make sure case is sensitive when I say it should be
$template = HTML::Template::JIT->new(filename => 'case.tmpl',
                                     path => ['t/templates'],
                                     jit_path => 't/jit_path',
                                     jit_debug => $debug,
                                     case_sensitive => 1
                                    );
$template->param(FOO => 'FOO!');
$template->param(foO => 'foO!');
$output = $template->output();
like($output, qr/I say FOO!/);
like($output, qr/I say foO!/);

