# ABSTRACT: Try opening a file, falling back to a failsafe file on error

use strict;
use warnings;

use File::Util qw( NL );

my $ftl = File::Util->new();

my $might_not_work     = '/this/might/not/work.txt';
my $will_work_for_sure = '/tmp/file.txt';
my $used_backup_plan   = 0;

my $file_handle = $ftl->open_handle
(
   $might_not_work =>
   {
      mode   => 'write',
      onfail => sub
      {
         my ( $err, $stack_trace ) = @_;

         warn "Couldn't open first choice, trying a backup plan...";

         $used_backup_plan = 1;

         return $ftl->open_handle( $will_work_for_sure => { mode => 'write' } );
      },
   }
);

print $file_handle 'Hello World!  The time is now ' . scalar localtime;

print $file_handle NL; # portably add a new line to the end of the file

close $file_handle or die $!;

# print out whichever file we were able to successfully write
print $ftl->load_file
(
   $used_backup_plan
      ? $will_work_for_sure
      : $might_not_work
);

exit;

