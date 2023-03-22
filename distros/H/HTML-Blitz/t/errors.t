use Test2::V0;
use HTML::Blitz ();

my $template = HTML::Blitz->new([ 'main' => [replace_inner_var => 'tiny_dancer'] ])->apply_to_html('hermetic/koala.html', '<main>hello</main>')->compile_to_sub;

my $e = dies { $template->() };
like $e, qr/\buninitialized value \$\w*tiny_dancer/, 'unset template variable is an error';
like $e, qr{\bhermetic/koala.html line \d+\.\n}a, 'error location mentions template name';

done_testing;
