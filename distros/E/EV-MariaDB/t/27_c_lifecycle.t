use strict;
use warnings;
use Test::More;
use File::Temp 'tempdir';
use File::Spec;
use ExtUtils::CBuilder;
use DynaLoader;
use Config;
use IO::Socket::INET;
use Alien::MariaDB;
use EV::MakeMaker;
use EV;
use EV::MariaDB;

plan skip_all => 'generated XS source unavailable' unless -f 'MariaDB.c';

my $dir = tempdir(CLEANUP => 1);
my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 1)
    or die $!;
my $closed_port = $listener->sockport;
close $listener;
my %ev = EV::MakeMaker::ev_args();
my $builder = ExtUtils::CBuilder->new(quiet => 1);
my $object = $builder->compile(
    source => 't/lib/ReviewProbe.c',
    object_file => "$dir/probe.o",
    extra_compiler_flags => $ev{INC} . ' ' . Alien::MariaDB->cflags,
    include_dirs => [File::Spec->rel2abs('.')],
);
my $library = $builder->link(
    objects => $object,
    lib_file => "$dir/probe.$Config{dlext}",
    module_name => 'ReviewProbe',
    extra_linker_flags => Alien::MariaDB->libs . ' ' . ($ev{LIBS} || ''),
);
my $handle = DynaLoader::dl_load_file($library, 0) or die DynaLoader::dl_error();
my $symbol = DynaLoader::dl_find_symbol($handle, 'boot_ReviewProbe')
    or die DynaLoader::dl_error();
DynaLoader::dl_install_xsub('ReviewProbe::bootstrap', $symbol)->();

for my $active (0, 1) {
    my $m = EV::MariaDB->new;
    ReviewProbe::socket_state($m, $active);
    is ReviewProbe::cleanup($m), $active,
        $active ? 'unfinished connection is shut down before close'
                : 'idle connection closes without shutting down COM_QUIT';
}

{
    my $m = EV::MariaDB->new(on_error => undef);
    ReviewProbe::retired_connection($m);
    is(ReviewProbe::cleanup($m), 0, 'cleanup never shuts down a retired descriptor');
}

for my $method (qw(finish skip_pending reset send_failure)) {
    my $m = EV::MariaDB->new(on_error => undef);
    $m->connect('127.0.0.1', 'root', '', '', $closed_port);
    my (@order, @errors);
    for my $i (1..4) {
        $m->query('SELECT 1', sub { push @order, $i; push @errors, $_[1] });
    }
    ReviewProbe::mark_sent($m);
    ReviewProbe::mark_sent($m);
    $method eq 'send_failure' ? ReviewProbe::send_failure($m) : $m->$method();
    is_deeply(\@order, [1..4], "$method cancels sent and unsent queries in FIFO order");
    ok(!grep({ !defined $_ } @errors), "$method supplies every callback an error");
    is($m->pending_count, 0, "$method leaves no pending callbacks");
    $m->finish;
}

subtest 'prepared execution drains secondary results before delivery' => sub {
    for my $failed (0, 1) {
        my $m = EV::MariaDB->new(on_error => undef);
        my @results;
        my $cb = sub { push @results, [@_] };
        ReviewProbe::execute_with_extra($m, $cb, $failed);
        is(scalar @results, 0, 'callback waits for secondary result');
        is($m->pending_count, 1, 'execution stays pending during drain');
        $cb = sub { fail('replacement callback invoked') };
        is(ReviewProbe::resume_stmt($m), 1, 'secondary result read asynchronously');
        is_deeply(\@results, $failed ? [[undef, 'secondary result failed']] : [[42]],
            $failed ? 'secondary error reaches original callback' : 'first result reaches original callback');
        is($m->pending_count, 0, 'execution completed');
        $m->finish;
    }
};

subtest 'prepared drain can be cancelled' => sub {
    my $m = EV::MariaDB->new(on_error => undef);
    my @results;
    ReviewProbe::execute_with_extra($m, sub { push @results, [@_] }, 0);
    $m->finish;
    is_deeply(\@results, [[undef, 'connection finished']], 'cancellation fires once with an error');
    is($m->pending_count, 0, 'cancelled execution is removed');
};

subtest 'prepared rows survive synchronous and asynchronous drains' => sub {
    for my $mode (2..6) {
        my $m = EV::MariaDB->new(on_error => undef);
        my @results;
        ReviewProbe::execute_with_extra($m, sub { push @results, [@_] }, $mode);
        for (1..3) {
            last unless $m->pending_count;
            ReviewProbe::resume_stmt($m);
        }
        is_deeply(\@results, $mode == 3
            ? [[undef, 'secondary store failed']]
            : [[[['first']], undef, ['value']]], "mode $mode preserves rows, fields, or error");
        is(ReviewProbe::store_calls(), 1, "mode $mode consumes secondary rows");
        is($m->pending_count, 0, "mode $mode completes");
        $m->finish;
    }
};

subtest 'execution chained from a callback drains once' => sub {
    my $m = EV::MariaDB->new(on_error => undef);
    my @results;
    ReviewProbe::execute_with_extra($m, sub {
        ReviewProbe::execute_with_extra($m, sub { push @results, [@_] }, 0);
    }, -1);
    is(ReviewProbe::resume_stmt($m), 1, 'nested execution starts one drain');
    is_deeply(\@results, [[42]], 'nested execution delivers one result');
    $m->finish;
};

done_testing;
