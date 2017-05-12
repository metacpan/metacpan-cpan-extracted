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

$DotCloud::Environment::main_file_path = '/path/to/nowhere';
throws_ok {
   my $env = DotCloud::Environment->new(backtrack => 0);
} qr{no\ suitable\ environment}, 'complains when there is no environment';

$DotCloud::Environment::main_file_path = json_path();
{
   my $env;
   lives_ok {
      $env = DotCloud::Environment->new();
   }
   "constructor with main_file_path variable";
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
      $env = DotCloud::Environment->new(no_load => 1);
      $env->load();
   }
   "load with main_file_path variable";
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
