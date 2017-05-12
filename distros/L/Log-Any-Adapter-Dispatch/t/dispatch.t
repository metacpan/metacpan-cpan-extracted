#!perl
use File::Temp qw(tempdir);
use Log::Any::Adapter;
use Log::Any::Adapter::Util qw(read_file);
use Log::Dispatch::File;
use Log::Dispatch;
use Test::More;
use strict;
use warnings;

my $test_count =
  ( Log::Any->logging_methods +
      Log::Any->logging_aliases +
      Log::Any->detection_methods +
      Log::Any->detection_aliases ) * 2;
plan tests => $test_count;

my $log = Log::Any->get_logger();

my $dir = tempdir( 'log-any-dispatch-XXXX', TMPDIR => 1, CLEANUP => 1 );
my $filename = "$dir/test.log";
my @output_params = (
    'File',
    min_level => 'notice',
    filename  => $filename,
    mode      => 'append',
    newline   => 1,
);

sub test_dispatch {
    foreach my $method ( Log::Any->logging_methods, Log::Any->logging_aliases )
    {
        $log->$method("logging with $method");
    }
    my $contents = read_file($filename);
    foreach my $method ( Log::Any->logging_methods, Log::Any->logging_aliases )
    {
        if ( $method !~ /trace|debug|info/ ) {
            like( $contents, qr/logging with $method\n/, "found $method" );
        }
        else {
            unlike(
                $contents,
                qr/logging with $method/,
                "did not find $method"
            );
        }
    }

    foreach
      my $method ( Log::Any->detection_methods, Log::Any->detection_aliases )
    {
        if ( $method !~ /trace|debug|info/ ) {
            ok( $log->$method, "$method" );
        }
        else {
            ok( !$log->$method, "!$method" );
        }
    }
}

Log::Any::Adapter->set( 'Dispatch', outputs => [ [@output_params] ] );
test_dispatch();

unlink($filename);
Log::Any::Adapter->set( 'Dispatch',
    dispatcher => Log::Dispatch->new( outputs => [ [@output_params] ] ) );
test_dispatch();
