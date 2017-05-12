#!perl

use strict;
use warnings;

use Digest::HMAC_MD6 qw( hmac_md6 hmac_md6_base64 hmac_md6_hex );
use Test::More;

my @cases = (
  {
    data => 'abc',
    key  => 'xyz',
    bs   => 64,
    hb   => 256,
    exphex =>
     '5d86d50e9f8bf314589f13641e8b156162158f42bb0cb112b5c5364f80dadcc1',
  },
  {
    data => 'abc',
    key  => 'xyz',
    bs   => 64,
    hb   => 512,
    exphex =>
     'b8678d032de24270499bf470748af9c7ab673c18911157b8bf7468531bd1f58b'
     . 'fa8f4c776eaf69671627d75b549912fb4116185f0bc5c34fcec09743e9f0a0a5',
  },
);

plan tests => @cases * 2;

for my $case ( @cases ) {
  my ( $data, @args ) = @{$case}{qw( data key bs hb )};
  my $name = join '/', $data, @args;

  {
    my $hmac = Digest::HMAC_MD6->new( @args );
    $hmac->add( $data );
    is $hmac->hexdigest, $case->{exphex}, "$name: oo";
  }

  {
    is hmac_md6_hex( $data, @args ), $case->{exphex}, "$name: function";
  }
}

# vim:ts=2:sw=2:et:ft=perl
