#!/usr/bin/perl -w

use strict;
use HTML::CalendarMonthDB;
use HTML::Template;
require URI::Escape;

main();

sub main {
	my(%param);
        my($qs, $queryString);
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
	
		# might as well check for delete requests here	
		if ($pair[0] =~ 'delete_') {
			my ($d,$delid) = split('_', $pair[0]);
			delCal($delid);
			$param{'changed'}=2;
		}
        }

	if ($param{'edit'}) {
		editCal(%param);
		$param{'changed'}=1;
	}

	editForm(%param);	

}

sub delCal {
	my ($delid)=shift;
	my ($cal);
	my $dbname = $ENV{'DB_NAME'};
        my $dbuser = $ENV{'DB_USER'};
        my $dbpass = $ENV{'DB_PASS'};
        my $dbclient = $ENV{'DB_CLIENT'};
        my $dbcalendar = $ENV{'DB_CALENDAR'};
	my $dbhost = $ENV{'DB_HOST'};
	$cal = new HTML::CalendarMonthDB('dbname'=>$dbname, 'dbpass'=>$dbpass, 'dbuser'=>$dbuser, 'dbcalendar'=>$dbcalendar, 'dbclient'=>$dbclient, 'dbhost'=>$dbhost);

	$cal->deldbevent($delid);
}	

sub editCal {
	my(%param)=@_;
        my ($cal, $p);
        my $dbname = $ENV{'DB_NAME'};
        my $dbuser = $ENV{'DB_USER'};
        my $dbpass = $ENV{'DB_PASS'};
        my $dbclient = $ENV{'DB_CLIENT'};
        my $dbcalendar = $ENV{'DB_CALENDAR'};
	my $dbhost = $ENV{'DB_HOST'};
        my($month,$day,$year) = split('_', $param{'date'});
        my($calid)=$param{'calid'};

        $cal = new HTML::CalendarMonthDB('month'=>$month, 'year'=>$year, 'dbname'=>$dbname, 'dbuser'=>$dbuser, 'dbcalendar'=>$dbcalendar, 'dbclient'=>$dbclient, 'dbhost'=>$dbhost);
	foreach	$p (keys %param) {
		if ($p =~ /eventname/ && $param{$p}) {
			$p =~ s/eventname_//;	
			$cal->editdbevent('eventid'=>$p, 'eventday'=>$param{'eventday_'.$p}, 'eventmonth'=>$param{'eventmonth_'.$p}, 'eventyear'=>$param{'eventyear_'.$p}, 'eventname'=>$param{'eventname_'.$p}, 'eventdesc'=>$param{'eventdesc_'.$p}, 'eventlink'=>$param{'eventlink_'.$p});	
		}	
	}

}

sub editForm {
	my(%param)=@_;
        my ($htmlOut);
	my($month,$day,$year) = split('_', $param{'date'});
	my $view = $param{'view'};
	my ($cal);
	my %content;
        my $dbname = $ENV{'DB_NAME'};
        my $dbuser = $ENV{'DB_USER'};
        my $dbpass = $ENV{'DB_PASS'};
        my $dbclient = $ENV{'DB_CLIENT'};
        my $dbcalendar = $ENV{'DB_CALENDAR'};
	my $dbhost = $ENV{'DB_HOST'};

	my $template = HTML::Template->new(filename => 'editcal.tmpl');
	if ($param{'changed'} eq 1) {
		$htmlOut .='<b><font color=blue>Events modified.</font></b><br>';
	}
	elsif ($param{'changed'} eq 2) {
		$htmlOut .='<b><font color=blue>Event deleted.</font></b><br>';
	}	
	$htmlOut .= '<form name="editform" method="post"><table border="0" cellpadding="3" bgcolor="ccccff">';
	$htmlOut .= "<tr bgcolor=\"red\"><td colspan=\"2\"><center><b>Edit Events for $month/$day/$year </b><font size=1> <a href=\"addcal.cgi?date=".$param{'date'}."&calid=".$param{'calid'}."&view=$view\">[Add event for $month/$day/$year]</a></font></center>";
	$htmlOut .= '</td></tr>';

	$cal = new HTML::CalendarMonthDB('month'=>$month, 'year'=>$year, 'dbname'=>$dbname, 'dbuser'=>$dbuser, 'dbcalendar'=>$dbcalendar, 'dbclient'=>$dbclient, 'dbhost'=>$dbhost);
	%content = $cal->getdbevent($day);
	my ($c,$exist);	
	foreach $c(keys %content) {
		 $exist=1;
		 $htmlOut .= '<tr bgcolor="8888ff"><td colspan=2 align="right"><input type="submit" name="delete_'.$c.'" value="Delete Event Below"></td></tr>';
		$htmlOut .= '<tr><td>Event Name</td><td><input type="text" name="eventname_'.$c.'" value="'.$content{$c}{'eventname'}.'"></td></tr>';
		$htmlOut .= '<tr><td>Event Date</td><td><input type="text" size="2" maxlength="2" name="eventmonth_'.$c.'" value="'.$content{$c}{'eventmonth'}.'"><b>/</b><input type="text" size="2" maxlength="2" name="eventday_'.$c.'" value="'.$content{$c}{'eventday'}.'"><b>/</b><input type="text" size="4" maxlength="4" name="eventyear_'.$c.'" value="'.$content{$c}{'eventyear'}.'"></td></tr>';	
		$htmlOut .= '<tr><td>Event Description</td><td><textarea rows=8 cols=30 wrap=virtual name="eventdesc_'.$c.'">'.$content{$c}{'eventdesc'}.'</textarea></td></tr>';
		$htmlOut .= '<tr><td>Event Link</td><td><input type="text" name="eventlink_'.$c.'" value="'.$content{$c}{'eventlink'}.'"></td></tr>';
			
	}
	if (!$exist) {
		$htmlOut .='<tr bgcolor="8888ff"><td colspan=2><center>No Events.</center></td></tr>';
	}
	else {
		$htmlOut .= '<tr><td colspan="2" bgcolor="red"><center><b><input type="submit" name="edit" value="Commit Changes"></b></center></td></tr>';	
	}	
	$htmlOut .= '</table><input type="hidden" name="date" value="'.$param{'date'}.'" override="1"><input type="hidden" name="calid" value="'.$param{'calid'}.'" override="1">';
	$htmlOut .= '</form>'; 	


	$template->param(
        	EDIT_CAL => $htmlOut,
		BODY_INCLUDE => "onload='self.opener.window.location=\"calendar.cgi?date=1&month=$month&year=$year&view=$view\"'"
	);

	# print the template
	print $template->output;
		

}
