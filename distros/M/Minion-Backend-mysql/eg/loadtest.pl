
use strict;
use warnings;
use feature qw( say );
use Test::mysqld;
use Minion;
use Minion::Backend::mysql;
use Getopt::Long qw( GetOptions );
use Time::HiRes qw( time );
use Data::Dumper qw( Dumper );
$|++;

my %opt = (
    jobs => 10,
    parents => 5,
);
GetOptions( \%opt,
    'jobs|j=i',
    'parents|p=i',
    'mysql=s',
    'dsn=s',
);

my ( @dsn, $mysqld );
push @dsn, $opt{dsn} if $opt{dsn};
if ( !@dsn ) {
    my @mysql_args;
    if ( $opt{mysql} ) {
        $ENV{PATH} = "$opt{mysql}/bin:$ENV{PATH}";
        push @mysql_args, map { "$opt{mysql}/bin/$_" } qw( mysqld mysql_install_db );
    }
    $mysqld = Test::mysqld->new(
      @mysql_args,
      my_cnf => {
        'skip-networking' => '', # no TCP socket
        'log-bin-trust-function-creators' => 1, # We're creating unsafe functions
      }
    ) or die $Test::mysqld::errstr;

    chomp( my $mysqld_version_info = qx{$mysqld->{mysqld} --version} );
    say "Minion::Backend::mysql v$Minion::Backend::mysql::VERSION";
    say "Running benchmark with MySQL/MariaDB server version: ";
    say $mysqld_version_info;
    push @dsn, dsn => $mysqld->dsn( dbname => 'test' );
}

my $minion = Minion->new(mysql => @dsn);
$minion->reset;
$minion->add_task( ping => sub { shift->finish( "pong" ) } );

say "Creating up to $opt{jobs} * ( 1 + $opt{parents} ) = " . ( $opt{jobs}*$opt{parents} );
my $queued_parents = 0;
my $start = time;
for my $i ( 1..$opt{jobs} ) {
    my %job_opt;
    if ( $opt{parents} ) {
        my $to_make = int rand $opt{parents};
        push @{ $job_opt{parents} }, $minion->enqueue( ping => [] ) for 0..$to_make;
        $queued_parents += $to_make + 1;
    }
    $minion->enqueue( test => [] => \%job_opt );
}
my $end = time;
say sprintf "Took %0.6f seconds to queue %d jobs", ( $end - $start ), ( $opt{jobs} + $queued_parents );

$start = time;
say Dumper $minion->stats;
$end = time;
say sprintf "Took %0.6f seconds to read stats", ( $end - $start );

$start = time;
$minion->backend->list_jobs(0, 100);
$end = time;
say sprintf "Took %0.6f seconds to list jobs", ( $end - $start );

my $dequeued = 0;
my $worker = $minion->worker->register;
$start = time;
while ( my $job = $worker->dequeue(0) ) {
    $dequeued++;
    if ( $dequeued % 2 ) { $job->finish } else { $job->fail };
    last if time - $start > 300;
}
$end = time;
say sprintf "Took %0.6f seconds to dequeue %d jobs", ( $end - $start ), $dequeued;

