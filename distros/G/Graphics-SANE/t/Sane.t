# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sane.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Graphics::SANE') };


my $fail = 0;
foreach my $constname (qw(
	SANE_ACTION_GET_VALUE SANE_ACTION_SET_AUTO SANE_ACTION_SET_VALUE
	SANE_CAP_ADVANCED SANE_CAP_ALWAYS_SETTABLE SANE_CAP_AUTOMATIC
	SANE_CAP_EMULATED SANE_CAP_HARD_SELECT SANE_CAP_INACTIVE
	SANE_CAP_SOFT_DETECT SANE_CAP_SOFT_SELECT SANE_CONSTRAINT_NONE
	SANE_CONSTRAINT_RANGE SANE_CONSTRAINT_STRING_LIST
	SANE_CONSTRAINT_WORD_LIST SANE_CURRENT_MAJOR SANE_FALSE
	SANE_FIXED_SCALE_SHIFT SANE_FRAME_BLUE SANE_FRAME_GRAY SANE_FRAME_GREEN
	SANE_FRAME_RED SANE_FRAME_RGB SANE_INFO_INEXACT
	SANE_INFO_RELOAD_OPTIONS SANE_INFO_RELOAD_PARAMS SANE_MAX_PASSWORD_LEN
	SANE_MAX_USERNAME_LEN SANE_STATUS_ACCESS_DENIED SANE_STATUS_CANCELLED
	SANE_STATUS_COVER_OPEN SANE_STATUS_DEVICE_BUSY SANE_STATUS_EOF
	SANE_STATUS_GOOD SANE_STATUS_INVAL SANE_STATUS_IO_ERROR
	SANE_STATUS_JAMMED SANE_STATUS_NO_DOCS SANE_STATUS_NO_MEM
	SANE_STATUS_UNSUPPORTED SANE_TRUE SANE_TYPE_BOOL SANE_TYPE_BUTTON
	SANE_TYPE_FIXED SANE_TYPE_GROUP SANE_TYPE_INT SANE_TYPE_STRING
	SANE_UNIT_BIT SANE_UNIT_DPI SANE_UNIT_MICROSECOND SANE_UNIT_MM
	SANE_UNIT_NONE SANE_UNIT_PERCENT SANE_UNIT_PIXEL)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Sane macro $constname/) {
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

