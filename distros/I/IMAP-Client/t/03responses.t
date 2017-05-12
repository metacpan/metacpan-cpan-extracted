use Test::More;

################## NOTE ###################
# These tests are rather un-kosher, since the *_response functions are 
# not actually methods to be called.  This tests abuses the fact that
# the *_response functions look only at the last line of the response,
# thus ignoring the first-argument-is-an-object problem....

################## NOTE ###################
# This tests all known response types from all known servers.  The
# comments after the $ok variable are set are from what server
# and command the response is from.
#
# This program only uses numeric tags, however it is built to accept
# any alphanumeric tag.  Tags that contain characters like @, $, or #,
# while possibly being valid on the server, are not valid for this module.
#
# Please send examples not represented here to the author!  Thanks!

use IMAP::Client;
my $imap = IMAP::Client->new;

######### Test OK responses
my @ok_r = ("0235 OK Completed", # Cyrus (default)
	    "first OK Completed (0.000 sec)", # Cyrus (fetch)
	    "Tag5 OK [COPYUID 1135117783 1 1] Completed", # Cyrus (uid copy)
	    "0tag OK Success (tls protection)", # Cyrus (starttls)
	    "; OK Completed (0.000 secs 4 calls)", # Cyrus ([r]list|sub)
	    "# OK [READ-WRITE] Completed", # Cyrus (select)
	    );
my @cont_r = ("+ ", # Cyrus
	      "+ go ahead", # (none)
	      );
my @untagged_r = ('* CAPABILITY IMAP4 IMAP4rev1', # Cyrus (capability(truc))
		  '* ID ("name" "Cyrus IMAPD")', # Cyrus (id(truc))
		  '* ACL asdfasdf anyone lrs', # Cyrus (getacl)
		  '* OK rename asdfasdf foobar', # Cyrus (rename)
		  '* FLAGS (\Answered \Flagged \Draft \Deleted \Seen)', # Cyrus examine/select
		  '* OK [PERMANENTFLAGS ()]  ',
		  '* 0 EXISTS',
		  '* 0 RECENT',
		  '* OK [UIDVALIDITY 1135120246]  ',
		  '* OK [UIDNEXT 1]  ',
		  '* LISTRIGHTS user.janedoe johndoe p l r s w i c d a 0 1 2 3 4 5 6 7 8 9', # Cyrus (listrights)
		  '* MYRIGHTS user.postmaster la', # Cyrus (myrights)
		  '* LIST (\HasChildren) "." "user.johndoe', # Cyrus (list)
		  '* LSUB () "." "foobar"', # Cyrus (lsub)
		  '* STATUS foobar (MESSAGES 0 RECENT 0 UIDNEXT 1 UIDVALIDITY 1135120246 UNSEEN 0)', # Cyrus status
		  );
#my @untagged_ok_r - ('* OK mail.rpi.edu Cyrus IMAP4 v2.2.10-Invoca-RPM-2.2.10-11 server ready', # Cyrus (welcome)
#		     );
my @fail_r = ('* BAD Invalid tag', # cyrus
	      '0000 BAD Null command', # cyrus
	      '; BAD Missing required argument to command', # cyrus
	      '9999 NO Mailbox does not exist', #cyrus
	      '@$ BAD Please select a mailbox first', # cyrus
	      );

my $tests = @ok_r + @cont_r + @untagged_r + @fail_r + @untagged_ok_r;
my $sections = 5; # match the number of lists above

plan tests => (@ok_r + @cont_r + @untagged_r + @fail_r)*$sections;

# ok_response matches OKs...
foreach my $r (@ok_r) {
    ok($imap->ok_response($r)) or print "#   $r\n";
}
# ... and nothing else
foreach my $r (@cont_r,@untagged_r,@untagged_ok_r,@fail_r) {
    ok(!$imap->ok_response($r))	or print "#   $r\n";
}


# continue_response matches continue requests...
foreach my $r (@cont_r) {
    ok($imap->continue_response($r)) or print "#   $r\n";
}
# ... and nothing else
foreach my $r (@ok_r,@untagged_r,@untagged_ok_r,@fail_r) {
    ok(!$imap->continue_response($r)) or print "#   $r\n";
}


# Untagged responses matches ALL untagged responses...
foreach my $r (@untagged_r,@untagged_ok_r) {
    ok($imap->untagged_response($r)) or print "#   $r\n";
}
# ... and nothing else
foreach my $r (@ok_r,@cont_r,@fail_r) {
    ok(!$imap->untagged_response($r)) or print "#   $r\n";
}

# Untagged OK responses matches untagged OK responses and some untagged...
foreach my $r (@untagged_ok_r) {
    ok($imap->untagged_ok_response($r)) or print "#   $r\n";
}
foreach my $r (@untagged_r) { # this is more to satisfy the # of tests computed
    ok(($imap->untagged_ok_response($r) || $imap->untagged_response($r)))
	 or print "#   $r\n";
} # end semi-useless testing :P
# ... and nothing else
foreach my $r (@ok_r,@cont_r,@fail_r) {
    ok(!$imap->untagged_ok_response($r)) or print "#   $r\n";
}

# Failure responses matches BAD, NO, for example...
foreach my $r (@fail_r) {
    ok($imap->failure_response($r)) or print "#   $r\n";
}
# ... and nothing else
foreach my $r (@ok_r,@cont_r,@untagged_r,@untagged_ok_r) {
    ok(!$imap->failure_response($r)) or print "#   $r\n";
}

