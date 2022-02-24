use Test::More;
use strict;

require 't/test-lib.pm';

my $app = LLNG::Manager::Test->new( {
        ini => {
            logLevel => 'error',
        }
    }
)->p;

my @tests = (
    []                                   => 'http://auth.example.com/',
    ['foo']                              => 'http://auth.example.com/foo',
    [ 'foo', 'bar' ]                     => 'http://auth.example.com/foo/bar',
    [ { p => 1 } ]                       => 'http://auth.example.com/?p=1',
    ['https://foo']                      => 'https://foo',
    [ 'https://foo', 'bar' ]             => 'https://foo/bar',
    [ 'https://foo', 'bar', 'baz' ]      => 'https://foo/bar/baz',
    [ 'https://foo', { p => 1 } ]        => 'https://foo?p=1',
    [ 'https://foo', 'bar', { p => 1 } ] => 'https://foo/bar?p=1',
);

{
    no warnings;
    $Data::Dumper::Indent = 0;
    $Data::Dumper::Terse  = 1;
}

for ( my $i = 0 ; $i < @tests ; $i += 2 ) {
    my @args     = @{ $tests[$i] };
    my $expected = $tests[ $i + 1 ];
    ok( $app->buildUrl(@args) eq $expected,
        Dumper( \@args ) . "\t=>\t" . $tests[ $i + 1 ] )
      or explain( $app->buildUrl(@args) . '', $expected );
    count(1);
}

done_testing( count() );
