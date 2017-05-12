#!/usr/bin/perl -w
use strict;
use Test::More;
use Log::Log4perl;
use File::Spec;
use Gearman::Worker;
use Cwd 'abs_path';

my $port = 10073;

my $conf = qq(
log4perl.category.test          = DEBUG, GM

log4perl.appender.GM          = Log::Log4perl::Appender::Gearman
log4perl.appender.GM.job_servers = 127.0.0.1:$port
log4perl.appender.GM.jobname = logme
log4perl.appender.GM.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.GM.layout.ConversionPattern=%m

);

my @received;
start_gearmand($port);
ok(Log::Log4perl::init( \$conf ));

my $worker = Gearman::Worker->new;
$worker->job_servers("127.0.0.1:$port");
$worker->register_function('logme' => sub { push @received, $_[0]->arg });

my $logger = Log::Log4perl->get_logger('test');
$logger->warn("hate 1");
$logger->warn("hate 2");
$logger->debug('mmmm');

diag "waiting for worker";
$worker->work( stop_if => sub { return $_[0] } );

is_deeply(\@received, ["WARN|test|hate 1",
                       "WARN|test|hate 2",
                       "DEBUG|test|mmmm",
                   ]);

my @CLEANUP;

sub start_gearmand {
    my $port = shift;
    my $gearmand_pid;
    my $gearmand = can_run('gearmand')
        or plan skip_all => "Can't find gearmand";

    system($gearmand, -p => $port, '-d', '--pidfile' => abs_path("t/gearmand.pid"));
    die $! if $?;
    sleep 1;
    open my $fh, '<', 't/gearmand.pid' or die $!;
    $gearmand_pid = <$fh>;
    diag $gearmand_pid;
    chomp $gearmand_pid;
    my $pid = $$;
    push @CLEANUP, sub { return unless $$ == $pid;
                         diag 'stopping gearmand'; kill 'TERM', $gearmand_pid if $gearmand_pid };
}

END {
    for (@CLEANUP) {
        $_->();
    }
}

sub can_run {
    my ($_cmd, @path) = @_;

    return $_cmd if -x $_cmd;

    for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), @path, '.') {
        my $abs = File::Spec->catfile($dir, $_[0]);
        next if -d $abs;
        return $abs if -x $abs;
    }

    return;
}

done_testing;
