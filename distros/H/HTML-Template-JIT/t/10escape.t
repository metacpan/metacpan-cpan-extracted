use Test::More tests => 5;
use HTML::Template::JIT;
my $debug = 0;

# test URL escapeing
$template = HTML::Template::JIT->new(
                                     filename => 'escape.tmpl',
                                     path => ['t/templates'],
                                     jit_path => 't/jit_path',
                                     jit_debug => $debug,
                                    );
$template->param(STUFF => '<>"\''); #"
$output = $template->output;
# print STDERR "-"x70, "\n", $output, "\n", "-"x70, "\n";
ok($output !~ /[<>"']/); #"

# test URL escapeing
$template = HTML::Template::JIT->new(
                                     filename => 'urlescape.tmpl',
                                     path => ['t/templates'],
                                     jit_path => 't/jit_path',
                                     jit_debug => $debug,
                                    );
$template->param(STUFF => '<>"; %FA'); #"
$output = $template->output;
ok($output !~ /[<>"]/); #"

# test non-filled escaped var
$template = HTML::Template::JIT->new(
                                     filename => 'urlescape.tmpl',
                                     path => ['t/templates'],
                                     jit_path => 't/jit_path',
                                     jit_debug => $debug,
                                    );
$output = $template->output;
like($output, qr/Some URL escaped stuff:/); 

# test js-escaped var
$template = HTML::Template::JIT->new(
                                     filename => 'jsescape.tmpl',
                                     path => ['t/templates'],
                                     jit_path => 't/jit_path',
                                     jit_debug => $debug,
                                    );
$template->param(STUFF => qq{1st line w/ "quotes"\n2nd line with 'apostrophes'\n\r3rd line \\s\\i\\mple});
$output = $template->output;
my $res = q{1st line w/ \\"quotes\\"\\n2nd line with \\'apostrophes\\'\\n\\r3rd line \\\\s\\\\i\\\\mple};
like($output, qr/\Q$res/); 

# test 8bit char in urlescaped var
$template = HTML::Template::JIT->new(
                                     filename => 'urlescape.tmpl',
                                     path => ['t/templates'],
                                     jit_path => 't/jit_path',
                                     jit_debug => $debug,
                                    );
$template->param(STUFF => "\xf4"); #"
$output = $template->output;
like($output, qr/%F4/); #"
