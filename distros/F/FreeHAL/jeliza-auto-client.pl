#!/usr/bin/perl -w
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#

$SIG{'QUIT'} = 'IGNORE';
$SIG{'INT'}  = 'IGNORE';
$SIG{'USR1'} = 'IGNORE';

#$SIG{'TERM'}  = 'IGNORE';

$SIG{ALRM} = sub { exit 0; };
alarm(110);

$| = 1;

use strict;
use warnings;
use AI::FreeHAL::Config;
use Data::Dumper;

use CGI;
use CGI::Carp qw(fatalsToBrowser);

my $port = 5100;

my $localhost = '127.0.0.1';
if ( -f 'override_localhost' ) {
    open my $file, '<', 'override_localhost';
    chomp($localhost = <$file>);
    close $file;
}

sub all_servers {
    my $sock = new IO::Socket::INET(
        PeerAddr => $localhost,
        PeerPort => '' . $port,
        Proto     => 'tcp',
        Blocking  => 1,
        Timeout => 5,
    );
    
    my @offers = ();
    
    eval {
        local $SIG{__DIE__};
        local $SIG{ALRM} = sub { die @_; } ;
        alarm(3);
        if ( $sock ) {
            print $sock "GET:OFFERS\n";
            <$sock>;
            my $res = <$sock>;
            # print $res;
            (my $offers_str = $res) =~ s/[\r\n]//gm;
            $offers_str =~ s/OFFERS[:]//gm;
            @offers = split /[,]/, $offers_str;
            $sock->shutdown(2);
            # print Dumper \@offers;
            return ('addr_of_random', grep { ! /OFFER/} @offers);
        }
        alarm(0);
    };
    $sock->shutdown(2) if $sock;
    return ('addr_of_random', grep { ! /OFFER/} @offers);
}

sub random_server {
    #open my $serverfile, '<', 'servers.txt';
    #my @servers = <$serverfile>;
    #map { s/[\r\n]//gm } @servers;
    #@servers = map { (split /[,]/, $_)[0] } @servers;
    #close $serverfile;
    #return $servers[ rand(@servers) ];
    
    my @offers = all_servers();
    
    return $offers[rand(@offers)];
}


our $cgi = new CGI;

my $p_ask = $cgi->param('ask');
$p_ask =~ s/\%([A-Fa-f0-9]{4})/pack('C', hex($1))/seg;
$p_ask =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
my $use_speech = $cgi->param('speech');
my $default_server = $localhost; # official freehal server
my ($p_server) = $cgi->param('server') || random_server() || $default_server;
my $user  = $ENV{'REMOTE_ADDR'} . '/' . ($p_ask ? 1 : 0);


print "ask:$p_ask\n";

my $speech_on = 'Sprachausgabe ein';
my $speech_off = 'Sprachausgabe aus';

use IO::Socket;

print "Expires: Mon, 26 Jul 1997 05:00:00 GMT\n";
print "Cache-Control: no-cache, must-revalidate\n";
print "Content-Type: text/html; charset=ISO-8859-1\r\n\r\n";

print qq{

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de" lang="de">
<head>
	<title>FreeHAL - JEliza - Die Opensource KI - Online Demo</title>
	<link rel="stylesheet" type="text/css" media="screen" href="http://www.freehal.org/styles.css" />
	
	<style type="text/css">
	#everything {
	    position: absolute !important;
	    top: 10px !important;
	    left: 10px !important;
	    right: 10px !important;
	    color: #222222 !important;
	    padding: 0px !important;
	    margin: 0px !important;
	    z-index: 4 !important;
    }
    
    html, body {
		margin:0;
		padding:0;
		height:100%;
		overflow:hidden;
	}

	</style>
</head>
<body style="background-color: white !important;" onload="document.getElementById('a').focus();">

<form method="get" width="100%" action="jeliza-auto-client.pl">

<div style="position: fixed; left: 0; top: 0; width: 100%; height: 1.5em; background-color: #fff4b6 !important;
		vertical-align: middle !important; text-align: left; padding-left: 10px; padding-right: 10px !important;
		border-bottom: 1px solid #fbeb94;
		">
<div style="float: right; display: inline; padding-right: 20px !important;">

You are connected to 
	<select name="server">
		};
	#open my $serverfile, '<', 'servers.txt';
	#while (defined( my $line = <$serverfile> )) {
    for my $line (all_servers()) {
		chomp $line;
		my ($ip, $server) = ($line, $line); # = split /[,]/, $line;
		
		print '	<option value="'.$server.'" '
			. ( $p_server eq $ip ? 'selected="selected"' : '' )
			. ">  $server  </option>";
	}
    print qq{
	</select>&nbsp;&nbsp;&nbsp;&nbsp;

You are User $user</div>
<a href="http://www.freehal.org">FreeHAL</a> Online Demo
</div>

<div style="position: absolute; left: 0; bottom: 0; width: 100%; height: 50px; background-color: #fff4b6 !important;
		vertical-align: middle !important; text-align: left; padding-left: 10px;
		border-top: 1px solid #fbeb94;
		">
<table style="border-collapse: collapse; width: 100%;">
	<tr style="width: 100%;">
		<td style="width: 280px;">
			Bitte geben Sie einen Satz ein:
		</td>
		
		<td rowspan="2" valign="center">
			<div width="100%">
			<input name="ask" value="" style="width: 70%;" id="a" />
	<select name="speech">
		};
    print '	<option value="1" '
        . ( $use_speech ? 'selected="selected"' : '' )
        . ">  $speech_on  </option>";
    print '	<option value="0" '
        . ( !$use_speech ? 'selected="selected"' : '' )
        . ">  $speech_off  </option>";
    print qq{
	</select>&nbsp;&nbsp;&nbsp;&nbsp;


			
		</td>
	</tr>
	<tr>
		<td>
			Please enter a sentence here:
		</td>
	</tr>
</table>
</div>

};


my $sock;

print qq{

<div style="width: 98%; background-color: white; margin-top: 30px; padding: 10px;
	position: absolute; left: 0; bottom: 51px; top: 0px;
	overflow: auto; "
	
	class="c_content">
	
	<small>

<style type="text/css">
	* html .c_content {
		
		position:absolute;
		top:0; bottom:0; left:0; right:0;
		height:80%;
		width:98%;
		overflow:auto;
	}
</style>
};

sub handle_request {
    my ($sock_ref, $prefix) = @_;
    my $sock = $$sock_ref;

	#print { $sock } $user, "\n";
	#print { $sock } $user, "\n";
	#print { $sock } $user, "\n";

	if ( $p_ask ) {
        # print $prefix . 'QUESTION:', $p_ask, "\n";;
		print { $sock } 'QUESTION:', $p_ask, "\n";
        print "FreeHAL hat ihre Eingabe erhalten. Bitte warten Sie einige Sekunden. <br /><br />";
        close $sock;
	}

	if ( $p_ask ) {
		my $content = '';
        
        for (my $g = 0; $g < 900; $g ) {
            
            $sock = new IO::Socket::INET(
                PeerAddr => $localhost,
                PeerPort => '' . $port,
                Proto     => 'tcp',
                Blocking  => 1,
                Timeout => 50,
            );
            <$sock> if $sock;
            
            next if !$sock;
            print { $sock } "GET:LINES\n";

            
            eval {
                local $SIG{ALRM} = sub { close $sock; };
                local $SIG{__DIE__} = sub { close $sock; };
                my $alarm = 2;
                alarm($alarm);
                LINE:
                while ( defined ( my $line = <$sock> ) ) {
                    $| = 1;

                    #print "&nbsp;&nbsp;";
                    #print "noch ", $alarm, " Sekunden ";
                    #print "&nbsp;&nbsp;";
                    
                    if ( $line =~ /BYE/ ) {
                        #last;
                    }

                    if ( $line =~ /DISPLAY/ ) {
                        ( $content = $line ) =~ s/DISPLAY://igm;
                        #alarm(do { $alarm /= 1.3; $alarm ||= 1; $alarm = int($alarm); $alarm});
                        #last LINE;

                        # send to browser
                        $content =~ s/[;]+[-]*[)]+/<img src="wink.png" \/>/igm;
                        $content =~ s/[:]+[-]*[)]+/<img src="grin.png" \/>/igm;
                        
                        if ( $content ) {
                            my $old_alarm = $alarm;
                            $alarm -= 1;

                            print '<div class="c'.$alarm.'">'.$content.'</div>';
                            print '<style type="text/css">.c'.$old_alarm.' { display: none; }</style>', "\n";
                        }
                    }
                    if ( $line =~ /SPEAK:/ ) {
                        if ( !$content ) {
                            ( $content = $line ) =~ s/SPEAK://igm;
                        }
                        #alarm(do { $alarm /= 1.5; $alarm ||= 1; $alarm});
                    }
                    last;
                }
                alarm(0);
                
            };
        }
        die $@ if $@;
        $sock->shutdown(2);
        alarm(30);
        print "<br><br>";
		
		my $dialog = '<b>Mensch</b>:: ' . (split(/[<]b[>]Mensch[<]\/b[>][:][:]/, $content))[-1] || $content;
		
		open my $dialog_file, ">>", 'dialog.txt';
        chomp $dialog;
        $dialog =~ s/[<]br[>]/\n/igm;
        chomp $dialog;
        $dialog =~ s/[<](.*?)[>]//igm;
        $dialog =~ s/\s*$//igm;
        $dialog =~ s/^\s*//igm;
        my $time      = scalar localtime;
        my $sentences = '';

        foreach my $line ( split /\n/, $dialog ) {
            chomp $line;

            print $dialog_file $time . "\t"
                . $ENV{'REMOTE_ADDR'} . "\t"
                . $line . "\n";
            if ( $line =~ /^FreeHAL[:]/i ) {
                $line =~ s/[:]+//;
                $line =~ s/^jeliza//igm;
                $sentences .= ' ' . $line;
            }
        }
        close $dialog_file;

        # send a mail

        # please edit this!
        my $send_mail_to_1 = 'dialog@freehal.org';
        my $send_mail_to_2 = 'tobias.schulz0@gmail.com';

        my $temp_ip = $ENV{'REMOTE_ADDR'};
        my $text    = << "ENDE";
To: $send_mail_to_1
BCC: $send_mail_to_2
Subject: $temp_ip: $time

$dialog

ENDE

        until ( open( MAIL, "|/usr/sbin/sendmail -t" ) ) {
            print "error.\n";
            print "Error starting sendmail: $!\n";
            select undef, undef, undef, 2;
        }
	

		#	print MAIL "From: me\@mydom.com\n";
		print MAIL $text;
		close(MAIL) || print "Error closing mail: $!\n";

#		print "Mail sent.\n";
        
        $sentences =~ s/\s+/%20/igm;
        print << "	EOT" if $use_speech;
	<embed src="http://tobias-schulz.info/jeliza/online/now.au.pl?text=$sentences" autostart="true" style="float: right; width: 150px; height: 20px; border: none;"s></embed>
<iframe src="http://tobias-schulz.info/jeliza/online/now.au.pl?text=$sentences" autostart="true" style="float: right; width: 150px; height: 20px; border: none;"s></iframe>
<!--	<iframe src="" style="width: 0; height: 0; border: none;"></iframe>-->
	EOT


        if ( '127.0.0.1' eq $p_server && 0 ) {
            my $ps_output = `ps aux | grep 'jeliza-auto-server.pl' | grep -v grep`;
            #print $ps_output;
            chomp $ps_output;
            if ( !$ps_output ) {
                $content .= qq{
                    </small>
                    <br /><br />
                    FreeHAL ist leider eingeschlafen, w&auml;hrend oder nachdem es ihre Eingabe h&auml;tte beantworten sollen.
                    Wenn Sie keine Antwort bekommen haben, probieren Sie es bitte noch einmal.
                    <small>
                }
            }
        }
        
        if ( -f 'message.txt' ) {
            print "<br /><div style='padding: 10px; margin: 10px; border: 1px solid red;'>";
            open my $file, '<', 'message.txt';
            print <$file>;
            close $file;
            print "</div><br />";
        }
        
	}

	close $sock;
}

my %already_tested = ();

if ( !grep { $_ && $_ !~ /^\s*?$/ } all_servers() ) {
    print qq{
                Leider schlafen momentan alle FreeHALs auf dieser Welt, oder diese Software hier enth&auml;lt einen Fehler. Melden Sie das bitte an ''info\@freehal.org''.<br />
            };
}

else {
    my $prefix = '';

    my $i = 0;
    while ( !$sock && $i < 10 ) {
        $i += 1;
        
        next if $already_tested{ $p_server } >= 2;
        
        $sock = new IO::Socket::INET(
    #        PeerAddr => $default_server eq $p_server ? '127.0.0.1'
    #                                                 : $p_server,
            PeerAddr => $localhost,
            PeerPort => '' . $port,
            Proto     => 'tcp',
            Blocking  => 1,
            Timeout => 50,
        );
        <$sock> if $sock;
        
        next if !$sock;
        
        #print $sock "REQUEST:", $p_server, "\n";
        #my $partner = (split /[:]/, scalar <$sock>)[1] || '';
        #$partner =~ s/[\r\n]//gm;
        #if ( !$partner ) {
        #    $partner = 'rand';
        #}
        # select undef, undef, undef, 0.1 while !$sock;
        
        $prefix = "REDIRECT:" . $p_server . ":";
        
        $already_tested{ $p_server } = 1;

        if ( $i >= 2 && $already_tested{ $p_server } == 2 ) {
            print qq{
                Leider schl&auml;ft das FreeHAL unter $p_server gerade.<br />
            };
        }
        #if ( !$partner || $partner =~ /x/ ) {
        #    $p_server = random_server();
        #}
    }

    if ( $sock ) {
        handle_request(\$sock, $prefix);
    }
    if ( $i == 5 ) {
        print qq{
            <br />
            Bitte haben Sie einem Moment Geduld und laden Sie nach 2-3 Minuten diese Seite neu.
        };
    }
}

print qq{

</small>
</div>

</form>
</body>
</html>

};
