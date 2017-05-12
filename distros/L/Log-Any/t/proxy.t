use strict;
use warnings;
use Test::More;
use Log::Any::Test;
use Log::Any::Adapter 'Test';

plan tests => 18;

my ( $log, $out );

$log = Log::Any->get_logger( prefix => 'Foo: ' );
$out = $log->info("test");
$log->contains_ok(qr/^Foo: test$/, 'prefix added');
is $out, 'Foo: test', 'log message built is returned';
$log->clear;

$log = Log::Any->get_logger;
$out = $log->info(qw/one two three four/);
$log->contains_ok(qr/^one two three four$/, 'arguments concatenated');
is $out, 'one two three four', 'log message built is returned';
$log->clear;

$log = Log::Any->get_logger;
$out = $log->infof(sub { "ran sub" } );
$log->contains_ok(qr/^ran sub$/, 'default formatter expands coderefs');
is $out, 'ran sub', 'log message built is returned';
$log->clear;

$log = Log::Any->get_logger;
$out = $log->infof("got %s %s", "coderef", sub { "expanded" } );
$log->contains_ok(qr/DUMMY/, 'default formatter does not expand coderefs as sprintf args');
like $out, qr/DUMMY/, 'log message built is returned';
$log->clear;

{
    # check that redundant parameters don't issue warnings (only on 5.22+)
    my $w = '';
    local $SIG{__WARN__} = sub { $w = shift };
    $log = Log::Any->get_logger;
    $log->infof("got %s", qw/Einstein Feynman/ );
    $log->contains_ok(qr/Einstein/);
    is( $w, '', 'no warning' );
    $log->clear;
}

$log = Log::Any->get_logger( filter => sub { "@_"} );
$out = $log->emergency("test");
$log->contains_ok(qr/^main 0 test$/, 'filter has category and numeric level');
is $out, 'main 0 test', 'log message run through filter is returned';
$log->clear;

$log = Log::Any->get_logger( formatter => sub { "@_"} );
$out = $log->tracef("test foo");
$log->contains_ok(qr/^main 8 test foo$/, 'formatter has category and numeric level');
is $out, 'main 8 test foo', 'log message run through formatter is returned';
$log->clear;

$log = Log::Any->get_logger( category => 'Foo', filter => sub { "@_"}  );
$out = $log->info("test");
$log->contains_ok(qr/^Foo 6 test$/, 'category override');
is $out, 'Foo 6 test', 'log message with category and run through filter is returned';
$log->clear;

$log = Log::Any->get_logger( category => 'Foo', prefix => 'foo', formatter => sub { "@_" } );
$log = $log->clone( prefix => 'bar ' );
$out = $log->tracef( 'test' );
$log->contains_ok( qr/^bar Foo 8 test$/, 'clone keeps existing properties and allows override' );
is $out, 'bar Foo 8 test', 'log message is returned';
$log->clear;

