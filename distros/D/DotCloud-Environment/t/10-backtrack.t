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
$DotCloud::Environment::main_file_path = '';
$DotCloud::Environment::main_dotcloud_code_dir = '';
chdir dirname(__FILE__);

{
   my $env;
   lives_ok {
      $env = DotCloud::Environment->new();
   }
   "constructor with no backtrack, expecting default = 1";
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
   "load with no backtrack, expecting default = 1";
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

{
   my $env;
   lives_ok {
      $env = DotCloud::Environment->new(backtrack => 1);
   }
   "constructor with backtrack";
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
      $env = DotCloud::Environment->new(no_load => 1, backtrack => 1);
      $env->load();
   }
   "load with backtrack";
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

{
   throws_ok {
      my $env = DotCloud::Environment->new(backtrack => 0);
   } qr{no suitable environment found},
   'constructor with backtrack set to 0, failure as expected';

   throws_ok {
      my $env = DotCloud::Environment->new(no_load => 1, backtrack => 0);
      $env->load();
   } qr{no suitable environment found},
   'load with backtrack set to 0, failure as expected';
} ## end for my $params ([environment_string...
