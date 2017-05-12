#!/usr/bin/perl

use Config;

open OUTPUT, ">$ARGV[0]" or die "$ARGV[0]: $!\n";
select OUTPUT;

print << "!GROK!THIS!";
$Config{'startperl'}

my \$config_file = '/usr/local/mpopd/mpopd.conf';
!GROK!THIS!
print << '!GROK!THIS!';
my $config_editor = $ENV{EDITOR} || 'vi';

$VERSION = "0.06";
# (c) Mark Tiramani 2001 markjt@fredo.co.uk
#
# Start | stop | restart | re-read/edit config | refresh ... the mpopd daemon
#
########################  CONFIG  #############################

#--- Full path to the mpopd script.
$mpopd = "mpopd";

###############################################################

require "$config_file";

#### Parse the command-line args
$cnt = 0;
foreach (@ARGV) {
        if (/^-p$/i) {
                $port = $ARGV[$cnt + 1];
                ++$cnt;
                next;
        } elsif (/^-f$/) {
                $force = 1;
                ++$cnt;
                next;
        } elsif (/^\d+$/) {
                ++$cnt;
                next;
        } elsif (/^-e$/) {
                $edit_conf = 1;
                ++$cnt;
                next;
        } else {
                $command = $_;
                ++$cnt;
        }
}

#### Display the pod docs and exit
if ($command =~ /^-{0,2}h/i || !$command) {
        @user = getpwnam "mail";
        $> = $user[2];
        $< = $user[2] || die "Sorry, could not run perldoc for you\nPlease run perldoc mpopdctl\n\n";
        system "perldoc mpopdctl";
        exit(0);
}

#### Try and locate the mpopd pid file
sub getPID {

        if (!-f "$mpopd_pid_file") {
                print <<"EOM";

I can't locate the mpopd pid file at: $mpopd_pid_file
Please enter the full path to the mpopd pid file:
EOM

                $| = 1;
                $input = <STDIN>;
                if (!-f "$input") {
                        print <<"EOM";

Sorry, no pid file found. Please check the value of the
\$mpopd_pid_file config item in $config_file

EOM
                        return 2;
                }
                else {
                        print <<"EOM";

OK, attempting to $command mpopd...

EOM
                        open MPOPDPID, "$input";
                        $mpopd_pid = <MPOPDPID>;
                        chomp $mpopd_pid;
                        if ($mpopd_pid =~ /^\d+$/) {
                                return 0;
                        }
                        else {
                                return 2;
                        }
                }

        }
        else {
                open MPOPDPID, "/var/run/mpopd.pid";
                $mpopd_pid = <MPOPDPID>;
                chomp $mpopd_pid;
                $old_port =  <MPOPDPID>;
                chomp $old_port;
                if ($mpopd_pid =~ /^\d+$/) {
                        return 0;
                }
                else {
                        return 2;
                }
        }

}

#### Do the appropriate thing based on the command
if ($command =~ /^start$/i) {
        if ($force == 1) {
                unlink "$mpopd_pid";
        }
        elsif (-f "$mpopd_pid_file") {
                print "\nmpopd may already be running. mpopd NOT started! Try -f ?\n\n";
                exit;
        }
        $ret = system "$mpopd $port&";
        if ($ret == 0) {
                while (!-f $mpopd_pid_file) {
                        ++$cnt;
                        if ($cnt == 100000) {
                                print "\nSorry, mpopd could not be started!\n\n";
                                exit(0);
                        }
                }
                print "\nmpopd started on port $port\n\n";
        }
        else {
                print "\nSorry, mpopd could not be started!\n\n";
        }
}
elsif ($command =~ /^stop$/i) {
        if (&getPID == 0) {
                if (kill "TERM", $mpopd_pid) {
                        print "\nmpopd halted\n\n";
                }
                else {
                        print "\nmpopd could not be halted!\n\n";
                }
        }
        else {
                exit;
        }
}
elsif ($command =~ /^restart$/i) {
        if (&getPID == 0) {
                if (kill "TERM", $mpopd_pid) {
                        print "\nmpopd halted\n\n";
                }
                else {
                        print "\nmpopd could not be halted! May have died?\n\n";
                }
        }
        else {
                exit;
        }
        unlink "$mpopd_pid";
        $ret = system "$mpopd $old_port&";
        if ($ret == 0) {
                print "\nmpopd restarted on port $old_port\n\n";
        }
        else {
                print "\nSorry, mpopd could not be started!\n\n";
        }
}
elsif ($command =~ /^config$/i) {
        if ($edit_conf == 1) {
                system "$config_editor $config_file";
                print "\nShould I signal mpopd to re-read the config file [y|n]? ";
                $| = 1;
                $input = <STDIN>;
                if ($input !~ /^y$|^yes$/i) {
                        print "\nOK, mpopd did NOT re-read its config file, bye\n\n";
                        exit;
                }
        }
        if (&getPID == 0) {
                if (kill "USR1", $mpopd_pid) {
                        print "\nmpopd was signaled to re-read its config file\n\n";
                }
                else {
                        print "\nmpopd could not re-read its config file!\n\n";
                }
        }
        else {
                exit;
        }
}
elsif ($command =~ /^refresh$/i) {
        if (&getPID == 0) {
                if (kill "HUP", $mpopd_pid) {
                        print "\nmpopd refreshed OK\n\n";
                }
                else {
                        print "\nmpopd could not be refreshed!\n\n";
                }
        }
        else {
                exit;
        }
}

__END__

=head1 NAME

mpopdctl - a script to make starting, stopping and sending
signals to mpopd a bit more convenient:

=head1 SYNOPSIS

mpopdctl [B<-f>] [B<-p> port] start | stop | restart | refresh | [B<-e>] config | B<-h>

=head1 DESCRIPTION

=head2 mpopdctl [B<-f>] [B<-p> port] start

Start the mpopd server daemon.

The optional B<-f> flag will cause an existing mpopd.pid
file to be removed before mpopd is started (only required
if mpopd should crash out uncleanly).

The optional B<-p> flag allows a port number to be specified,
which overrides the config file setting. This allows other
instances to be run in parrallel to the standard port 110
for testing.

Example:

mpopdctl B<-p> 8110 B<-f> start

Would remove a stale pid file and start mpopd in daemon mode
on port 8110

=head2 stop

Stop the mpopd server daemon.

=head2 restart

Stops the mpopd server daemon and imediately restarts it.

=head2 refresh

mpopd will send a signal to all currently executing
child servers to close. They will interrupt what they
were doing and restore the user's mailbox, ignoring any
commands to delete messages. mpopd will close its server
socket, reopen it and bind to the port set in $port in
the mpopd config file.

[B<-e>] B<config>

Call a running mpopd server and ask it to re-read the mpopd
configuration file. All subsequent child servers inherit the
new config values, with the exception of the port number
which can only be changed using the 'refresh' flag.

The optional B<-e> flag will open the mpopd config file in an
editor of your choice first. After the editor is closed mpopd
will ask you if it should re-read the modified config file.

=head2 B<-h>

Displays the help text.

=cut

!GROK!THIS!
