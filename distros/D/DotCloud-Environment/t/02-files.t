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

throws_ok {
   my $env = DotCloud::Environment->new(fallback_file => '/path/to/nowhere');
} qr{/path/to/nowhere}mxs, 'complains when file is wrong';

for my $params (
   [environment_file => json_path()],
   [fallback_file    => json_path()],
   [environment_file => yaml_path()],
   [fallback_file    => yaml_path()],
  )
{
   my ($name, $text) = @$params;
   my $env;
   lives_ok {
      $env = DotCloud::Environment->new(
         fallback_file => '/path/to/nowhere', # precedence!
         $name => $text
      );
   }
   "constructor with $name";
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

for my $params (
   [environment_file => json_path()],
   [fallback_file    => json_path()],
   [environment_file => yaml_path()],
   [fallback_file    => yaml_path()],
  )
{
   my ($name, $text) = @$params;
   my $env;
   lives_ok {
      $env = DotCloud::Environment->new(
         no_load => 1,
         fallback_file => '/path/to/nowhere', # precedence!
      );
      $env->load($name => $text);
   }
   "load with $name";
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
