use strict;
use warnings;
use Test::More tests => 87;
use Log::Any qw($log);

my @logs;
push( @logs, $log );
push( @logs, Log::Any->get_logger() );
push( @logs, Log::Any->get_logger( category => 'Foo' ) );

my $logging_method_count   = scalar( Log::Any->logging_methods() );
my $detection_method_count = scalar( Log::Any->logging_methods() );

foreach my $log (@logs) {
    foreach my $method ( Log::Any->detection_methods() ) {
        ok( !$log->$method, "!$method" );
    }
    ok(
        scalar( map { $log->$_ } Log::Any->detection_methods() ) ==
          Log::Any->detection_methods() );
    foreach my $method ( Log::Any->logging_methods() ) {
        ok( $log->$method("") || 1, "$method runs" );
        my $methodf = $method . "f";
        ok( $log->$methodf("") || 1, "$methodf runs" );
    }
    eval { $log->bad_method() };
    ok( $@ =~ qr{Can\'t locate object method "bad_method"}, "bad method" );
}
