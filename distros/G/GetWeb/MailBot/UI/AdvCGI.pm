package MailBot::UI::AdvCGI;

use Mail::Internet;
use MailBot::UI::CGI;
use MailBot::Util;

@ISA = qw( MailBot::UI::CGI );
use strict;

my $PERL = $^X;
$PERL =~ /\// or $PERL = "/usr/bin/$PERL";

sub getOutHeader
{
    "Content-Type: text/html\n";
}

sub vSendMessage
{
    my $self = shift;
    my $internet = shift;

    $| = 1;

    print "Here is an approximation of the message that would be sent in response:";
    print "<P><PRE>\n";

    open(ESCAPE_BR,"| $PERL -pe '" . 's^\<^&lt;^g; s^\>^&gt;^g;' . "'");
    $internet -> print(\*ESCAPE_BR);
    close(ESCAPE_BR);

    print "</PRE><P>\n";

    my $action = "http://" . $ENV{SERVER_NAME} . ':' . $ENV{SERVER_PORT} .
	$ENV{SCRIPT_NAME};
	
    my $config = MailBot::Config::current;

    my $address = $config -> getBounceAddr;
    my $newSubject = $internet -> head -> get("Subject");
    $newSubject =~ s^\"^\\\"^g;
    chomp($newSubject);

    print <<"EOF";
Reply to this message:<P>
<form method=POST action=\"$action\">
<p>
Subject of message: <input SIZE=40 name=Subject value=\"Re: $newSubject\"><p>
Body:<br><TEXTAREA NAME=Body COLS=70 ROWS=10></TEXTAREA>
<p><input type=submit value=\"Simulate Reply\"> <input type=reset>
</form>
<hr>
EOF

    print <<"EOF2";
Forward this message:<P>
<form method=POST action=\"$action\">
<p>
Subject of message: <input SIZE=40 name=Subject value=\"[fwd: $newSubject]\"><p>
Body:<br><TEXTAREA NAME=Body COLS=70 ROWS=10>
EOF2

    #print '"';
    # change \ to \\, and " to \"
    open(ESCAPE,"| $PERL -pe '" . 's^<^&lt;^g; s^>^&gt;^g; s/^$/ /'. "'");
    #open(ESCAPE,"| $PERL -pe '" . 's^\\\\^\\\\\\\\^g; s^\\"^\\\\"^g' . "'");
    print ESCAPE "  ---forwarded message follows---\n\n";
    $internet -> print(\*ESCAPE);
    print ESCAPE "\n\n  ---end forwarded message---\n\n";
    close(ESCAPE);

    #print '"';
    print <<"EOF3";
</TEXTAREA>
<p><input type=submit value=\"Simulate Forwarding\">  <input type=reset>
</form>
<hr>
<ADDRESS><A HREF=mailto:\"$address\">$address</A></ADDRESS>
EOF3


}
