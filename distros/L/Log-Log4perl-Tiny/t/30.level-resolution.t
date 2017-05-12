# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 17;    # last test to print
use Log::Log4perl::Tiny qw( LEVELID_FOR LEVELNAME_FOR LOGLEVEL );

my $level = LOGLEVEL();
ok defined($level), 'initial level is defined';

my $level_name = LEVELNAME_FOR($level);
ok defined($level_name), 'name of initial level is defined';
is $level_name, 'INFO', 'default level is INFO';

my $resolved_level = LEVELID_FOR('INFO');
is $resolved_level, $level, 'back-resolution yields same value';

{
   no strict 'refs';
   Log::Log4perl::Tiny->import(':levels');
   is $resolved_level, ${__PACKAGE__ . '::INFO'}, 'level is $INFO indeed';

   for my $name (qw< TRACE DEBUG INFO WARN ERROR FATAL >) {
      my $id = ${__PACKAGE__ . '::' . $name};
      is LEVELNAME_FOR($id), $name, "LEVELNAME_FOR() gives $name";
      is LEVELID_FOR($name), $id,, "LEVELID_FOR('$name')";
   }
}

done_testing();
