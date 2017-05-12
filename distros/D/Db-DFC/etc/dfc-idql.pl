#! /usr/local/bin/perl 
# dfc-idql.pl
# (c) 2000 MS Roth -- michael.s.roth@saic.com

use DFC;
use Term::ReadKey;

logon();

# main loop
$cmd_counter = 1;
while (1) {
    print "$cmd_counter> ";
    chomp($cmd = <STDIN>);
    if ($cmd =~ /go$/i) {
        do_DQL($DQL);
        $DQL = "";
        $cmd_counter = 0;
    } elsif ($cmd =~ /quit$/i) {
        do_Quit();
    } else {
        $DQL .= " $cmd";
    }
    $cmd_counter++;
}

sub dfcErrors {
        return $session->getMessage(3);
}

sub logon {
    print "\n" x 10;
    print "(c) 2000 MS Roth. Distributed as part of Db::DFC\n";
    print "DFC-Interactive Document Query Language Editor\n";
    print "---------------------------------------------------------\n";
    print "Enter Docbase Name: ";
    chomp ($DOCBASE = <STDIN>);
    print "Enter User Name: ";
    chomp ($USERNAME = <STDIN>);
    print "Enter Password: ";
    # turn off display
    ReadMode 'noecho';
    chomp ($PASSWD = <STDIN>);
    # turn display back on
    ReadMode 'normal';

    # login
    $dfclient = DfClient->new();
    $client = $dfclient->getLocalClient();
    $logininfo = DfLoginInfo->new();
    $logininfo->setUser($USERNAME);
    $logininfo->setPassword($PASSWD);
    $session = $client->newSession($DOCBASE,$logininfo);
    die dfcErrors() unless $session;

    print "\nLogon to $DOCBASE successful. Type 'quit' to quit.\n\n";
}

sub do_DQL {
    my $dql = shift;

    print "\n\n";

    # do sql and print results
    $query = DfQuery->new();
    $query->setDQL($dql);
    $col = $query->execute($session,DF_EXEC_QUERY);  #DF_EXEC_QUERY = 3

    if ($col) {

        # get _count
        $attr_count = $col->getAttrCount();

        if ($attr_count > 0) {
            # get _names and _lengths
            @attr_names = ();
            @attr_lengths = ();

            for ($i=0; $i<$attr_count; $i++) {
                push(@attr_names,$col->getAttr($i)->getName());
                push(@attr_lengths,$col->getAttr($i)->getLength());
            }

            # print attr names
            for ($i=0; $i<$attr_count; $i++) {
                print $attr_names[$i];
                print " " x ($attr_lengths[$i] - length($attr_names[$i]) . " ");
            }
            print "\n";

            # print underbars for attr names
            for ($i=0; $i<$attr_count; $i++) {
                if ($attr_lengths[$i] == 0)
                    { $attr_lengths[$i] = 16; }
                print "-" x $attr_lengths[$i] . "  ";
            }
            print "\n";

            # print attr values
            $row_counter = 0;
            while ($col->next()) {
                my $attr_counter = 0;
                foreach my $name (@attr_names) {
                    my $row = $col->getTypedObject();
                    my $value = $row->getString($name);
                    print $value;
                    print " " x ($attr_lengths[$attr_counter] - length($value)) . " ";
                    $attr_counter++;
                }
                print "\n";
                $row_counter++;
            }
            print "\n[$row_counter row(s) affected]\n\n";
            $col->close();
        }
    }
    print dfcErrors() . "\n";
}


sub do_Quit {
    print "\n\nQuitting!\n\n";
    $session->disconnect();
    exit;
}

# __EOF__   