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
use YAML;

my $yaml = load_yaml();

{
   my $reyaml;
   lives_ok {
      my $env = DotCloud::Environment->new(environment_string => $yaml);
      $reyaml = $env->as_yaml();
   }
   "constructor and as_yaml live";
   ok($reyaml, 'as_yaml() gave something');
   isa_ok($reyaml, 'HASH');
   $reyaml = $reyaml->{whatever};
   ok(defined($reyaml) && length($reyaml), 'as_yaml returned whatever');

   my $expected = Load($yaml);
   my $got = Load($reyaml);
   is_deeply($got, $expected, 'YAML representations are equivalent');
}
