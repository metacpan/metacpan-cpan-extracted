use strict;
use warnings;

use Test::More tests => 7;

# ABSTRACT: Test ->get with a dummy class

use HTTP::Tiny::Mech;
use HTTP::Tiny 0.022;
use lib 't/get';
use FakeUA;

my $instance = HTTP::Tiny::Mech->new( mechua => FakeUA->new(), );
isa_ok( $instance,         'HTTP::Tiny' );
isa_ok( $instance,         'HTTP::Tiny::Mech' );
isa_ok( $instance->mechua, 'FakeUA' );

{
  local $instance->mechua->{calls} = [];
  my $result = $instance->get('http://www.example.org:80/');
  is( ref $result, 'HASH', "get url: Got a hash back" );
  note explain $instance;
}

{
  local $instance->mechua->{calls} = [];
  my $result = $instance->get( 'http://www.example.org:80/', { args => {} } );
  is( ref $result, 'HASH', "get url + opts: Got a hash back" );
  note explain $instance;
}
{
  local $instance->mechua->{calls} = [];
  my $result = $instance->request( 'HEAD', 'http://www.example.org:80/' );
  is( ref $result, 'HASH', "request url: Got a hash back" );
  note explain $instance;
}
{
  local $instance->mechua->{calls} = [];
  my $result = $instance->request( 'POST', 'http://www.example.org:80/', { headers => {}, content => "CONTENT" } );
  is( ref $result, 'HASH', "request url + opts: Got a hash back" );
  note explain $instance;
}
