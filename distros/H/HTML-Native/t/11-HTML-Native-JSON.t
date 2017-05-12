#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON;

BEGIN {
    use_ok ( "HTML::Native" );
    use_ok ( "HTML::Native::JSON" );
}

{
  my $data = {
    boolean => JSON::true,
    scalar => "string",
    array => [ qw ( first second ) ],
    hash => {
      up => "down",
      left => "right",
    }
  };
  my $json = HTML::Native::JSON->new ( $data );
  isa_ok ( $json, "HTML::Native::JSON" );
  is ( $$json, "script" );
  is ( $json->{type}, "application/json" );
  my $decoded;
  lives_ok ( sub { $decoded = decode_json ( join ( "", @$json ) ) } );
  is_deeply ( $decoded, $data );
}

done_testing();
