use Test::More tests => 18-2;
use HTML::Template::Pro;

my $template = HTML::Template::Expr->new(path => ['t/templates'],
                                      filename => 'complex.tmpl',
                                     );
#is($template->query(name => 'unused'), 'VAR', "query(name => unused)");
#my %params = map { $_ => 1 } $template->param();
#ok(exists $params{unused}, "param(unused)");

$template->param(foo => 11,
                 bar => 0,
                 fname => 'president',
                 lname => 'clinton',
                 unused => 0);
my $output = $template->output();
like($output, qr/Foo is greater than 10/i, "greater than");
ok($output !~ qr/Bar and Foo/i, "and");
like($output, qr/Bar or Foo/i, "or");
like($output, qr/Bar - Foo = -11/i, "subtraction");
like($output, qr/Math Works, Alright/i, "math");
like($output, qr/My name is President Clinton/, "string op 1");
like($output, qr/Resident Alien is phat/, "string op 2");
like($output, qr/Resident has 8 letters, which is less than 10 and greater than 5/, "string length");

$template = HTML::Template::Expr->new(path => ['t/templates'],
                                      filename => 'loop.tmpl',
		global_vars => 1,

                                     );
$template->param(simple => [
                            { foo => 10 },
                            { foo => 100 },
                            { foo => 1000 }
                           ]);
$template->param(color => 'blue');
$template->param(complex => [ 
                             { 
                              fname => 'Yasunari',
                              lname => 'Kawabata',
                              inner => [
                                        { stat_name => 'style', 
                                          stat_value => 100 ,
                                        },
                                        { stat_name => 'shock',
                                          stat_value => 1,
                                        },
                                        { stat_name => 'poetry',
                                          stat_value => 100
                                        },
                                        { stat_name => 'machismo',
                                          stat_value => 50
                                        },
                                       ],
                             },
                             { 
                              fname => 'Yukio',
                              lname => 'Mishima',
                              inner => [
                                        { stat_name => 'style', 
                                          stat_value => 50,
                                        },
                                        { stat_name => 'shock',
                                          stat_value => 100,
                                        },
                                        { stat_name => 'poetry',
                                          stat_value => 1
                                        },
                                        { stat_name => 'machismo',
                                          stat_value => 100
                                        },
                                       ],
                             },
                            ]);

$output = $template->output();
like($output, qr/Foo is less than 10.\s+Foo is greater than 10.\s+Foo is greater than 10./, "math in loops");


# test user-defined functions
my $repeat = sub { $_[0] x $_[1] };

$template = HTML::Template::Expr->new(path => ['t/templates'],
                                      filename => 'func.tmpl',
                                      functions => {
                                                    repeat => $repeat,
                                                   },
                                     );
$template->param(repeat_me => 'foo ');
$output = $template->output();
like($output, qr/foo foo foo foo/, "user defined function");
like($output, qr/FOO FOO FOO FOO/, "user defined function with uc()");


# test numeric functions
$template = HTML::Template::Expr->new(path => ['t/templates'],
                                      filename => 'numerics.tmpl',
                                     );
$template->param(float => 5.1,
                 four => 4);
$output = $template->output;
like($output, qr/INT: 5/, "int()");
like($output, qr/SQRT: 2/, "sqrt()");
like($output, qr/SQRT2: 4/, "sqrt() 2");
like($output, qr/SUM: 14/, "int(4 + 10.1)");
like($output, qr/SPRINTF: 14.1000/, "sprintf('%0.4f', (10.1 + 4))");

