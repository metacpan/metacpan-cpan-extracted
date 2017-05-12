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
   my @connection_details;
   lives_ok {
      my $env = DotCloud::Environment->new(environment_string => $json);
      @connection_details = $env->subservice_vars(
         subservice => 'mysql',
         list    => [qw< host port login password >],
      );
   } ## end lives_ok
   "constructor and subservice_vars live";
   is_deeply(
      \@connection_details,
      [
         'whatever-polettix.dotcloud.com', '13747',
         'root',                           'mysql-password-here',
      ],
      'grabbed data is correct with list'
   ) or diag(Dumper(\@connection_details));

   my %service_vars;
   lives_ok {
      my $env = DotCloud::Environment->new(environment_string => $json);
      %service_vars = $env->subservice_vars(subservice => 'mysql',);
   }
   "constructor and subservice_vars live";
   is_deeply(
      \%service_vars,
      {
         'password' => 'mysql-password-here',
         'url' =>
'mysql://root:mysql-password-here@whatever-polettix.dotcloud.com:13747',
         'port'  => '13747',
         'login' => 'root',
         'host'  => 'whatever-polettix.dotcloud.com',
      },
      'grabbed data is correct for whole vars'
   ) or diag(Dumper(\%service_vars));

}

{
   my %service_vars;
   lives_ok {
      my $env = DotCloud::Environment->new(environment_string => $json);
      %service_vars = $env->subservice_vars('mysql');
   }
   "constructor and subservice_vars with subservice name live";
   is_deeply(
      \%service_vars,
      {
         'password' => 'mysql-password-here',
         'url' =>
'mysql://root:mysql-password-here@whatever-polettix.dotcloud.com:13747',
         'port'  => '13747',
         'login' => 'root',
         'host'  => 'whatever-polettix.dotcloud.com',
      },
      'grabbed data is correct for whole vars'
   ) or diag(Dumper(\%service_vars));

}

{
   my %service_vars;
   lives_ok {
      my $env = DotCloud::Environment->new(environment_string => $json);
      %service_vars = $env->subservice_vars('sqldb.mysql');
   }
   "constructor and subservice_vars with service.subservice name live";
   is_deeply(
      \%service_vars,
      {
         'password' => 'mysql-password-here',
         'url' =>
'mysql://root:mysql-password-here@whatever-polettix.dotcloud.com:13747',
         'port'  => '13747',
         'login' => 'root',
         'host'  => 'whatever-polettix.dotcloud.com',
      },
      'grabbed data is correct for whole vars'
   ) or diag(Dumper(\%service_vars));

}

{
   throws_ok {
      DotCloud::Environment->new(environment_string => $json)->subservice_vars('sqldb.whatever');
   } qr/cannot.*find.*subservice/mxs, 'subservice not found';
}
