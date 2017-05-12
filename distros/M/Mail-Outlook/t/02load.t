# Test that the various ol constants can be found. olInbox is mentioned in
# the documentation, but doesn't seem to be needed. The string 'Inbox' will do.

use strict;
use warnings;
use Test::More;

# This doesn't work because Win32::OLE::Const returns true even
# if the library is not found.
use_ok( 'Win32::OLE::Const', 'Microsoft Outlook' )||do{
  use_ok( 'Win32::OLE::Const', '.*Outlook' );
};

my $hr = Win32::OLE::Const->Load( 'Microsoft Outlook' );
ok( keys(%$hr), "Got some constants for 'Microsoft Outlook'" ) || do {
  $hr = Win32::OLE::Const->Load( '.*Outlook' ); };
ok( keys(%$hr), "Got some constants for '.*Outlook'" );

test_constants( $hr );

sub test_constants {
  my ( $hr ) = shift;
  # olMailItem is 0, so test for defined.
  foreach my $k ( qw/ olFolderInbox
  olFolderOutbox
  olFolderSentMail
  olFolderDrafts
  olFolderDeletedItems
  olMailItem
 / ) {
    ok( defined($hr->{$k}), "OLE constant $k found" );
  }
}

done_testing;