# vim: filetype=perl :
use strict;
use warnings;

#use Test::More tests => 1; # last test to print
use Test::More 'no_plan';    # substitute with previous line when done

use File::Basename qw( dirname );
use lib dirname(__FILE__) . '/lib';
use Test::DotCloud::Environment;
use Test::Exception;
use Data::Dumper;

use DotCloud::Environment;
use JSON;

my $json = load_json();

{
   my $rejson;
   lives_ok {
      my $env = DotCloud::Environment->new(environment_string => $json);
      $rejson = $env->as_json();
   }
   "constructor and as_json live";
   ok($rejson, 'as_json() gave something');
   isa_ok($rejson, 'HASH');
   $rejson = $rejson->{whatever};
   ok(defined($rejson) && length($rejson), 'as_json returned whatever');

   my $expected = utf8::is_utf8($json)
      ? from_json($json)
      : decode_json($json);
   my $got = utf8::is_utf8($rejson)
      ? from_json($rejson)
      : decode_json($rejson);
   is_deeply($got, $expected, 'JSON representations are equivalent');
}
