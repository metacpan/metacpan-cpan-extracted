use strict;
use warnings;
use Test::More;
use HTTP::Proxy::GreaseMonkey::Script;
use File::Spec;

my @schedule = (
    {
        src     => 'u1.js',
        include => {
            'http://hexten.net/'                     => 1,
            'http://wiki.hexten.net/'                => 1,
            'http://wiki.hexten.net/cgi-bin/pomspag' => 1,
            'http://example.com'                     => 0,
            'http://hexten.net/index.cgi'            => 0,
            'http://hexten.net/index.pl'             => 0
        },
        name        => 'User One',
        namespace   => 'http://hexten.net/',
        description => 'A test',
    },
    {
        src     => 'u2.js',
        include => {
            'http://hexten.net/'                     => 1,
            'http://wiki.hexten.net/'                => 1,
            'http://wiki.hexten.net/cgi-bin/pomspag' => 1,
            'http://example.com'                     => 1,
            'http://hexten.net/index.cgi'            => 1,
            'http://hexten.net/index.pl'             => 1
        },
        name        => 'User Two',
        namespace   => 'http://hexten.net/',
        description => 'Another test',
    },
);

plan tests => @schedule * 7;

for my $test ( @schedule ) {
    my $name = $test->{src};
    my $src = File::Spec->catfile( 't', 'scripts', $name );
    ok my $script = HTTP::Proxy::GreaseMonkey::Script->new( $src ),
      "$name: created";
    isa_ok $script, 'HTTP::Proxy::GreaseMonkey::Script';
    my $include = $test->{include};
    my $got     = {};
    for my $uri ( sort keys %$include ) {
        $got->{$uri} = $script->match_uri( $uri ) ? 1 : 0;
    }
    unless ( is_deeply $got, $include, "$name: rules" ) {
        use Data::Dumper;
        diag( Dumper( { got => $got, want => $include } ) );
    }
    for ( qw( name namespace description ) ) {
        is $script->$_(), $test->{$_}, "$name: $_";
    }
    is $script->file, $src, "$name: file";
}
