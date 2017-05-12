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

my $env;
lives_ok {
   $env = DotCloud::Environment->new(no_load => 1);
}
'constructor with no_load works';

is_deeply(scalar($env->application_names()),
   [], 'nothing loaded by default');
is_deeply(scalar($env->applications()), {}, 'nothing loaded by default');

throws_ok {
   $env->application('non-existent');
}
qr{no\ application}mxs, 'request for non-existent application';

my $json = load_json();
my $yaml = load_yaml();

for my $params (
   [environment_string => $json],
   [fallback_string    => $json],
   [environment_string => $yaml],
   [fallback_string    => $yaml],
  )
{
   my ($name, $text) = @$params;
   my $env;
   lives_ok {
      $env = DotCloud::Environment->new(
         fallback_file => '/path/to/nowhere',
         $name => $text,
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
   [environment_string => $json],
   [fallback_string    => $json],
   [environment_string => $yaml],
   [fallback_string    => $yaml],
  )
{
   my ($name, $text) = @$params;
   my $env;
   lives_ok {
      $env = DotCloud::Environment->new(
         no_load => 1,
         fallback_file => '/path/to/nowhere',
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
