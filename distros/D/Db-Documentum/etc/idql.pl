#! /usr/local/bin/perl -w
# idql.pl
# (c) 2000 MS Roth

# ver 1.0 - July 2000
#           * Initially released with 'An Introduction to Db::Documentum'
# ver 1.1 - October 2000
#           * Updated slightly for and released with Db::documentum 1.4
# ver 1.2 - November 2000
#           * Minor updates to fix results formatting problem
#           + TODO: use Term::ANSIColor?
#           + TODO: return results as hash?
#           + TODO: make results columns only as wide as largest result returned

use Db::Documentum qw(:all);
use Db::Documentum::Tools qw (:all);
use Term::ReadKey;
$VERSION = "1.2";

logon();

# ===== main loop =====
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

sub logon {
    print "\n" x 10;
    print "(c) 2000 MS Roth. Distributed as part of Db::Documentum\n";
    print "Db::Documentum Interactive Document Query Language Editor $VERSION\n";
    print "----------------------------------------------------------------\n";
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
    $SESSION = dm_Connect($DOCBASE,$USERNAME,$PASSWD);
    die dm_LastError() unless $SESSION;

    my $host = dm_LocateServer($DOCBASE);
    print "\nLogon to $DOCBASE\@$host successful. Type 'quit' to quit.\n\n";
}

sub do_DQL {
    my $dql = shift;

    print "\n\n";

    # do sql and print results
    $api_stat = dmAPIExec("execquery,$SESSION,F,$dql");

    if ($api_stat) {
        $col_id = dmAPIGet("getlastcoll,$SESSION");

        # get _count
        $attr_count = dmAPIGet("get,$SESSION,$col_id,_count");

        if ($attr_count > 0) {
            # get _names and _lengths
            @attr_names = ();
            @attr_lengths = ();

            for ($i=0; $i<$attr_count; $i++) {
                push(@attr_names,dmAPIGet("get,$SESSION,$col_id,_names[$i]"));
                my $attrlen = dmAPIGet("get,$SESSION,$col_id,_lengths[$i]");
                if ($attrlen < 16) { $attrlen = 16; }
                push(@attr_lengths,$attrlen);
            }

            # print attr names
            for ($i=0; $i<$attr_count; $i++) {
                print $attr_names[$i];
                print " " x ($attr_lengths[$i] - length($attr_names[$i]) . " ");
            }
            print "\n";

            # print underbars for attr names
            for ($i=0; $i<$attr_count; $i++) {
                print "-" x $attr_lengths[$i] . " ";
            }
            print "\n";

            # print attr values
            $row_counter = 0;
            while (dmAPIExec("next,$SESSION,$col_id")) {
                my $attr_counter = 0;
                foreach my $name (@attr_names) {
                    my $value = dmAPIGet("get,$SESSION,$col_id,$name");
                    print $value;
                    print " " x ($attr_lengths[$attr_counter] - length($value)) . " ";
                    $attr_counter++;
                }
                print "\n";
                $row_counter++;
            }
            print "\n[$row_counter row(s) affected]\n\n";
            dmAPIExec("close,$SESSION,$col_id");
        }
    }
    print dm_LastError($SESSION,3,'all');
}


sub do_Quit {
    print "\n\nQuitting!\n\n";
    dmAPIExec("disconnect,$SESSION");
    exit;
}

# __EOF__   