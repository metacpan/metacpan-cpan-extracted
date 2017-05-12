use Test;
BEGIN { $| = 1; plan(tests => 10); chdir 't' if -d 't'; }
use blib;

use Mail::Procmailrc;

## constructor
ok( my $l1 = new Mail::Procmailrc::Literal("## this is a comment") );
ok( $l1->stringify(), "## this is a comment");

ok( my $l2 = new Mail::Procmailrc::Literal("## this is another comment") );
ok( $l2->stringify(), "## this is another comment");

ok( my $l3 = new Mail::Procmailrc::Literal("## yet another comment") );
ok( $l3->stringify(), "## yet another comment");

ok( $l3->literal("## foo fu yoo!") );
ok( $l3->stringify(), "## foo fu yoo!");

ok( $l3 = new Mail::Procmailrc::Literal("## yet another comment", {'level' => 2} ) );
ok( $l3->dump(), "    ## yet another comment\n" );

exit;
