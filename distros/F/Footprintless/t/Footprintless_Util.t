use strict;
use warnings;

use lib 't/lib';

use File::Spec;
use File::Temp;
use Footprintless::CommandRunner::Mock;
use Test::More tests => 5;

BEGIN { use_ok('Footprintless::Util') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout',
        log_level => Log::Any::Adapter::Util::numeric_level($level) );
};

my $logger = Log::Any->get_logger();

my $temp_dir = File::Temp->newdir();
$logger->trace( 'temp_dir [%s]', $temp_dir );

my $spurt_file = File::Spec->catfile( $temp_dir, 'spurt' );
$logger->trace( 'writing to [%s]', $spurt_file );
Footprintless::Util::spurt( 'foo', $spurt_file );
is( do { local ( @ARGV, $/ ) = $spurt_file; <> }, 'foo', 'spurt' );

my $slurp_file = File::Spec->catfile( $temp_dir, 'slurp' );
$logger->trace( 'writing to [%s]', $slurp_file );
open( my $handle, '>', $slurp_file ) || croak("cant open $slurp_file");
print( $handle 'bar' );
close($handle);
is( Footprintless::Util::slurp($slurp_file), 'bar', 'slurp' );

like( Footprintless::Util::dumper( { foo => 'bar' } ),
    qr/^\s*\$VAR1\s+=\s+\{\s+'foo'\s+=>\s+'bar'\s+\};\s*$/s, 'dumper' );

$logger->debug('test clean');
my @call_stack = ();
my $command_runner =
    Footprintless::CommandRunner::Mock->new( sub { push( @call_stack, \@_ ); return 0; } );
Footprintless::Util::clean( [ 'foo', 'bar/' ], command_runner => $command_runner );
is( pop(@call_stack)->[0],
    'bash -c "rm -rf \"bar/\";rm -f \"foo\"";mkdir -p "bar/"',
    'clean one file one dir'
);
