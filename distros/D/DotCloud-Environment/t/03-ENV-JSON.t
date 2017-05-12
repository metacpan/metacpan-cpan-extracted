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

$ENV{DOTCLOUD_ENVIRONMENT_FILE} = json_path();
{
   my $env;
   lives_ok {
      $env = DotCloud::Environment->new(
         fallback_file => '/path/to/nowhere',
      );
   }
   "constructor with environment variable";
   if ($env) {
      is_deeply(scalar($env->application_names()),
         ['whatever'], 'applicaton_names()');
      is_deeply(scalar($env->applications()),
         { whatever => default_data_structure() }, 'applications()')
        or diag(Dumper(scalar $env->application('whatever')));
      is_deeply(scalar($env->application('whatever')),
         default_data_structure(), 'application()')
        or diag(Dumper(scalar $env->application('whatever')));
   } ## end if ($env)
   else {
      fail "no object, no test" for 1 .. 3;
   }
}

{
   my $env;
   lives_ok {
      $env = DotCloud::Environment->new(
         no_load => 1,
         fallback_file => '/path/to/nowhere',
      );
      $env->load();
   }
   "load with environment variable";
   if ($env) {
      is_deeply(scalar($env->application_names()),
         ['whatever'], 'applicaton_names()');
      is_deeply(scalar($env->applications()),
         { whatever => default_data_structure() }, 'applications()')
        or diag(Dumper(scalar $env->application('whatever')));
      is_deeply(scalar($env->application('whatever')),
         default_data_structure(), 'application()')
        or diag(Dumper(scalar $env->application('whatever')));
   } ## end if ($env)
   else {
      fail "no object, no test" for 1 .. 3;
   }
} ## end for my $params ([environment_string...
