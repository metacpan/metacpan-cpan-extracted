# Recursively list all folders and sub-folders in the Inbox.

use strict;
use warnings;
use Test::More;

use_ok( 'Mail::Outlook' ) || die;

my $outlook = Mail::Outlook->new;
isa_ok( $outlook, 'Mail::Outlook', "Got a Mail::Outlook object" );

my $inbox = $outlook->folder('Inbox');
ok( $inbox, "Got the Inbox" );

test_all_folders( $outlook, "Inbox", [$inbox->all_folders] );

# Test empty folder.
test_all_folders( $outlook, "Inbox", [] );

# Test nox-existent folder
# test_all_folders( $outlook, "Inboxx", [1] );

done_testing;

sub test_all_folders {
  my ($outlook, $name, $folder_names ) = @_;
  ok( $name, "Testing $name" );
  foreach my $n ( @$folder_names ) {
    my $fn = "$name/$n";
    ok( $fn, "folder_name $n" );
    my $f = $outlook->folder( $fn );
    ok( $f, "Got folder $fn" )||next;
    test_all_folders( $outlook, $fn, [ $f->all_folders ] );
    $outlook->folder($fn);
  }
  return 1;
}
