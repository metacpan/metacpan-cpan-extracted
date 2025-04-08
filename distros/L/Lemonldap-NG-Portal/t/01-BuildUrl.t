use warnings;
use Test::More;
use Lemonldap::NG::Portal::Main::Request;
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
    [ 'https://foo/bar', 'baz', { p => 1 } ] => 'https://foo/bar/baz?p=1',
    [ 'https://foo/bar/', 'baz', 'qux', { p => 1 } ] =>
      'https://foo/bar/baz/qux?p=1',
);

{
    no warnings;
    $Data::Dumper::Indent = 0;
    $Data::Dumper::Terse  = 1;
}

for ( my $i = 0 ; $i < @tests ; $i += 2 ) {
    my @args     = @{ $tests[$i] };
    my $expected = $tests[ $i + 1 ];
    is( $app->buildUrl(@args),
        $expected, Dumper( \@args ) . "\t=>\t" . $tests[ $i + 1 ] );
    count(1);
}

# Test relative URL building
@tests = (
    [ 'http://auth.example.com', "foo" ]                    => "/foo",
    [ 'http://auth.example.com', "foo", "bar", { p => 1 } ] => "/foo/bar?p=1",
    [ 'http://auth.example.com/test/', "foo" ]              => "/test/foo",
    [ 'http://auth.example.com/test/', "foo", "bar", { p => 1 } ] =>
      "/test/foo/bar?p=1",

);

my $req = Lemonldap::NG::Portal::Main::Request->new(
    { PATH_INFO => "", REQUEST_URI => "" } );
for ( my $i = 0 ; $i < @tests ; $i += 2 ) {
    my @args     = @{ $tests[$i] };
    my $expected = $tests[ $i + 1 ];
    $req->portal( shift @args );
    is( $app->relativeUrl( $req, @args ),
        $expected,
        Dumper( [ $req->portal, @args ] ) . "\t=>\t" . $tests[ $i + 1 ] );
    count(1);
}

# Test template variables
@tests = (
    'http://auth.example.com/test/' => '/test/',
    'http://auth.example.com/'      => '/',
);
for ( my $i = 0 ; $i < @tests ; $i += 2 ) {
    my $input    = $tests[$i];
    my $expected = $tests[ $i + 1 ];
    $req->portal($input);
    my %prms = $app->tplParams($req);
    is( $prms{PORTAL_BASE}, $expected, "PORTAL_BASE for $input is $expected" );
    count(1);
}

done_testing( count() );
