# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl LibTracker-Client.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('LibTracker::Client') };


my $fail = 0;
foreach my $constname (qw(
	DATA_DATE DATA_NUMERIC DATA_STRING DATA_STRING_INDEXABLE
	SERVICE_APPLICATIONS SERVICE_APPOINTMENTS SERVICE_BOOKMARKS
	SERVICE_CONTACTS SERVICE_CONVERSATIONS SERVICE_DEVELOPMENT_FILES
	SERVICE_DOCUMENTS SERVICE_EMAILATTACHMENTS SERVICE_EMAILS SERVICE_FILES
	SERVICE_FOLDERS SERVICE_HISTORY SERVICE_IMAGES SERVICE_MUSIC
	SERVICE_OTHER_FILES SERVICE_PLAYLISTS SERVICE_PROJECTS SERVICE_TASKS
	SERVICE_TEXT_FILES SERVICE_VFS_DEVELOPMENT_FILES SERVICE_VFS_DOCUMENTS
	SERVICE_VFS_FILES SERVICE_VFS_FOLDERS SERVICE_VFS_IMAGES
	SERVICE_VFS_MUSIC SERVICE_VFS_OTHER_FILES SERVICE_VFS_TEXT_FILES
	SERVICE_VFS_VIDEOS SERVICE_VIDEOS)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined LibTracker::Client macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# get an instance and check its type.
# TODO : handle the case when trackerd/dbus isn't running
my $tracker = LibTracker::Client->get_instance();
ok( $tracker, "got tracker intance" );
isa_ok( $tracker, "LibTracker::Client", "instance type check" );

