use Test::More tests => 2;
use HTML::Template::JIT;

my $debug = 0;

my $template = HTML::Template::JIT->new(                                
					path => ['t/templates'],
					filename => 'escaping.tmpl',
					jit_path => 't/jit_path',
					jit_debug => $debug,
				       );
my $result = $template->output();
like($result, qr/email: petr\.smejkal\@tesco-europe.com/);
like($result, qr/funky: \$\@\%\&\*'"\\n\\t/);

