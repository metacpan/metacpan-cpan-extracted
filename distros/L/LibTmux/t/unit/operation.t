use v5.44;
use Test2::V1;
my $loaded = eval { require LibTmux::Operation; 1 };
T2->ok($loaded, 'shared operation pipeline is loadable');
unless ($loaded) { T2->diag($@); T2->done_testing; exit }
my $argv = ['first'];
my $op   = LibTmux::Operation->request(argv => $argv)->then(
    sub ($a) {
        LibTmux::Operation->request(argv => ['second', $a])
            ->then(sub ($b) { {value => $b} });
    }
);
$argv->[0] = 'changed';
my (@pending, $value, $error, $cancelled);
my $cancel = $op->run(
    sub ($request, $done, $fail) {
        push @pending, [$request, $done, $fail];
        return sub { $cancelled++ };
    },
    sub ($v) { $value = $v },
    sub ($e) { $error = $e }
);
T2->is($pending[0][0]{argv}, ['first'], 'preparation owns argv');
T2->is($value, undef, 'pending executor does not complete synchronously');
$pending[0][1]->('alpha');
T2->is(
    $pending[1][0]{argv},
    ['second', 'alpha'],
    'continuation prepares dependent request'
);
$pending[1][1]->('omega');
$pending[1][1]->('duplicate');
T2->is(
    $value,
    {value => 'omega'},
    'exactly one result despite duplicate callbacks'
);
T2->is($error, undef, 'successful pipeline has no failure');
my $thrown = bless {}, 'OperationThrown';
my $failure;
LibTmux::Operation->value(1)->then(sub { die $thrown })->run(
    sub { die 'unexpected request' },
    sub { die 'unexpected success' },
    sub ($e) { $failure = $e }
);
T2->is($failure, $thrown, 'transform exceptions retain object identity');
my @later;
$cancel =
    LibTmux::Operation->request(argv => ['pending'])
    ->then(sub { die 'cancelled continuation ran' })
    ->run(
    sub ($req, $ok, $bad) {
        push @later, $ok;
        sub { $cancelled++ }
    },
    sub { die 'cancelled success' },
    sub { die 'cancelled failure' }
    );
$cancel->();
$later[0]->('late');
T2->is($cancelled, 1,
    'cancellation reaches active executor and suppresses continuation');
T2->done_testing;
