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
$DotCloud::Environment::main_dotcloud_code_dir = '';
use JSON;

my $json = load_json();

{
   my $code_dir;
   lives_ok {
      $code_dir = Test::DotCloud::Environment::call_find_code_dir();
   } ## end lives_ok
   "find_code_dir lives";
   is($code_dir, '../../..', 'code dir as expected');

   lives_ok {
      $code_dir = Test::DotCloud::Environment::othercall_find_code_dir();
   } ## end lives_ok
   "find_code_dir lives";
   is($code_dir, '../..', 'code dir as expected');
}
