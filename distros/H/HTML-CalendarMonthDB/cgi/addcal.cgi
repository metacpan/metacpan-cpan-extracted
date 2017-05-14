#!/usr/bin/perl -w

use strict;
use HTML::CalendarMonthDB;
use HTML::Template;
require URI::Escape;

main();

sub main {
	#my $env;
	#foreach $env (keys %ENV) {
	#	print $env." ".$ENV{$env}."<br>";	
	#}

        my(%param, $qs, $queryString);
	if ($ENV{'CONTENT_LENGTH'}) {
        	read STDIN, $queryString, $ENV{'CONTENT_LENGTH'};
       	}
	if ($ENV{'QUERY_STRING'}) {
		$queryString .= "&".$ENV{'QUERY_STRING'};
	}
	my(@splitQS)=split('&' ,$queryString);
        foreach $qs(@splitQS) {
		$qs =~ s/\+/ /g;
                my(@pair)=split('=', $qs);
                $pair[0]=URI::Escape::uri_unescape($pair[0]);
                $pair[1]=URI::Escape::uri_unescape($pair[1]);
                $param{$pair[0]} = $pair[1];
        }

	if ($param{'add'}) {
		addEvent(%param);
		$param{'added'} =1;	
	}

	addForm(%param);	

}

sub addEvent {
	my(%param)=@_;
        my ($cal);
        my $dbname = $ENV{'DB_NAME'};
        my $dbuser = $ENV{'DB_USER'};
        my $dbpass = $ENV{'DB_PASS'};
        my $dbclient = $ENV{'DB_CLIENT'};
        my $dbcalendar = $ENV{'DB_CALENDAR'};
	my $dbhost = $ENV{'DB_HOST'};
        my($month,$day,$year) = split('_', $param{'date'});
        my($calid)=$param{'calid'};

        $cal = new HTML::CalendarMonthDB('month'=>$month, 'year'=>$year, 'dbname'=>$dbname, 'dbuser'=>$dbuser, 'dbcalendar'=>$dbcalendar, 'dbclient'=>$dbclient, 'dbhost'=>$dbhost);
	$cal->adddbevent('date'=>$day, 'eventname'=>$param{'eventName'}, 'eventdesc'=>$param{'eventDesc'}, 'eventlink'=>$param{'eventLink'});

}

sub addForm {
	my(%param)=@_;
        my ($htmlOut);
	my($month,$day,$year) = split('_', $param{'date'});
	my $view = $param{'view'};
	my $template = HTML::Template->new(filename => 'addcal.tmpl');

	if ($param{'added'}) {
		$htmlOut .= 'Event Added.  You may add another for this date if you wish.<br><br>';
	}
	
	$htmlOut .= '<form name="addform" method="post"><table border="0" cellpadding="3" bgcolor="ccccff"><tr bgcolor="red"><td colspan="2">';
	$htmlOut .= "<center><b>Add Event for $month/$day/$year</b><font size=1> <a href=\"editcal.cgi?date=".$param{'date'}."&calid=".$param{'calid'}."&view=$view\">[Edit events for $month/$day/$year]</a></font></center>";
	$htmlOut .= '</td></tr><tr><td>Event Name</td><td><input type="text" name="eventName"></td></tr>';
	$htmlOut .= '<tr><td>Event Description</td><td><textarea name="eventDesc" rows=8 cols=30 wrap=virtual></textarea></td></tr>';
	$htmlOut .= '<tr><td>Event Link</td><td><input type="text" name="eventLink"></td></tr>';
	$htmlOut .= '<tr><td colspan="2"><center><input type="submit" name="add" value="Add This Event"></center></td></tr>';	
	$htmlOut .= '</table><input type="hidden" name="date" value="'.$param{'date'}.'" override="1"><input type="hidden" name="calid" value="'.$param{'calid'}.'" override="1">';
	$htmlOut .= '</form>'; 	


	$template->param(
        	ADD_CAL => $htmlOut,
		BODY_INCLUDE => "onload='self.opener.window.location=\"calendar.cgi?date=1&month=$month&year=$year&view=$view\"'"
	);

	# print the template
	print $template->output;
		

}
