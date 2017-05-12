use Evo 'Test::More';
plan skip_all => "w_eval is under deprecation trial";

my $e;
my $catch = sub { $e = shift; };

# validate

# die
$e = '';
ws_fn(w_eval_run($catch))->(sub { die "foo\n" })->();
is $e, "foo\n";

# live
$e = '';
my @res = ws_fn(w_eval_run($catch))->(sub { ok wantarray })->();
ok !$e;

done_testing;
