#!/usr/local/bin/perl
# tickler.pl
# © 2000 MS Roth

use Db::Documentum qw (:all);
use Db::Documentum::Tools qw (dm_Connect dm_LastError);

print "\nDb::Documentum Inbox Tickler\n";
print "----------------------------\n";

# define $DOCBASE, $USER, $PASSWD here

# logon or die
$SESSION_ID = dm_Connect($DOCBASE,$USER,$PASSWD);
die "No session ID obtained.\nDocumentum Error was: " .
dm_LastError("","3","all") unless $SESSION_ID;

# define SQL for counting
$DQL = "SELECT COUNT(*) AS cnt FROM dmi_queue_item WHERE name = user";

# do duery
$col_id = dmAPIGet("query,$SESSION_ID,$DQL");

# if query successful
if ($col_id) {
   # loop thorugh collection (of 1) and print count
   while (dmAPIExec("next,$SESSION_ID,$col_id")) {
    $count = dmAPIGet("get,$SESSION_ID,$col_id,cnt");
   }
   dmAPIExec("close,$SESSION_ID,$col_id");
   print "You have $count items in your inbox.\n";
}
# if no collection, error
else {
   print "\nNo collection ID obtained.\n";
   print "Documentum Error was: " . dm_LastError($SESSION_ID,"3","all");
}

dmAPIExec("disconnect,$SESSION_ID");

# __EOF__
