#!/usr/bin/perl -w
#use CGI::Carp qw(fatalsToBrowser);
use strict;
use HTML::CalendarMonthDB;
use HTML::Template;
require URI::Escape;

main();

sub main {
	my(%param, $qs, $queryString);
	$queryString="";
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
	
	if ($param{'change'}) {
		changeCal(%param);
	}
	elsif ($param{'default'}) {
		my $p;
		foreach $p (keys %param) {
			$param{$p} = "000000" if (($p =~ "bordercolor") || ($p =~ "contentcolor"));
			$param{$p} = "ffffff" if ($p =~ "headercolor");
			$param{$p} = "ffffff" if ($p =~ "weekendcolor");
			$param{$p} = "ffffff" if ($p =~ "weekdaycolor");
			$param{$p} = "ffffff" if ($p =~ "bgcolor");
			$param{$p} = "ffffff" if ($p =~ "todaycolor");
		}	
		$param{'border'}=5;
		$param{'width'}='100%';
		$param{'cellalignment'}='left';
		changeCal(%param);
	}
	getCal(%param);
}

#####################################################
sub changeCal {
	my(%param)=@_;
	my ($cal);
	my $dbname = $ENV{'DB_NAME'};
	my $dbuser = $ENV{'DB_USER'};
	my $dbpass = $ENV{'DB_PASS'};
	my $dbclient = $ENV{'DB_CLIENT'};
	my $dbcalendar = $ENV{'DB_CALENDAR'};	
	my $dbhost = $ENV{'DB_HOST'};
	
	$cal = new HTML::CalendarMonthDB('dbname'=>$dbname, 'dbuser'=>$dbuser, 'dbcalendar'=>$dbcalendar, 'dbclient'=>$dbclient, 'dbhost'=>$dbhost);		
	$cal->editdbcalendar(border=>$param{'border'}, width=>$param{'width'}, bgcolor=>$param{'bgcolor'}, weekdaycolor=>$param{'weekdaycolor'}, weekendcolor=>$param{'weekendcolor'}, todaycolor=>$param{'todaycolor'}, bordercolor=>$param{'bordercolor'}, weekdaybordercolor=>$param{'weekdaybordercolor'}, weekendbordercolor=>$param{'weekendbordercolor'}, todaybordercolor=>$param{'todaybordercolor'}, contentcolor=>$param{'contentcolor'}, weekdaycontentcolor=>$param{'weekdaycontentcolor'}, weekendcontentcolor=>$param{'weekendcontentcolor'}, todaycontentcolor=>$param{'todaycontentcolor'}, headercolor=>$param{'headercolor'}, weekdayheadercolor=>$param{'weekdayheadercolor'}, weekendheadercolor=>$param{'weekendheadercolor'}, cellalignment=>$param{'cellalignment'});	

}
##############
sub getCal {
	my(%param)=@_;
	my $template = HTML::Template->new(filename => 'caladmin.tmpl');

	my $dbname = $ENV{'DB_NAME'};
	my $dbuser = $ENV{'DB_USER'};
	my $dbpass = $ENV{'DB_PASS'};
	my $dbclient = $ENV{'DB_CLIENT'};
	my $dbcalendar = $ENV{'DB_CALENDAR'};
	my $dbhost = $ENV{'DB_HOST'};
	my $htmlOut;
	my($cal,$type,$month,$year);

$htmlOut .= '<form name="calform1" method="post" action="calendar.cgi">';
$param{'view'} = '' if !$param{'view'};
$htmlOut .= '<input type="radio" name="view" value="standard"';
if (($param{'view'} eq 'standard') || !$param{'view'}) {
	$htmlOut .= ' checked onclick="document.calform1.submit()">Standard&nbsp;&nbsp;<input type="radio" name="view" value="list" onclick="document.calform1.submit()">List View<br>';
}
else {
	$htmlOut .= ' onclick="document.calform1.submit()">Standard&nbsp;&nbsp;<input type="radio" name="view" value="list" checked onclick="document.calform1.submit()">List View<br>';
	$type=1;
}

if (!$param{'month'}) {
	$cal = new HTML::CalendarMonthDB('dbname'=>$dbname, 'dbuser'=>$dbuser, 'dbcalendar'=>$dbcalendar, 'dbclient'=>$dbclient, 'dbhost'=>$dbhost);
	$month=$cal->month();
	$year=$cal->year();
}
else {
	if ($param{'date'} eq '<<') {
		$month=$param{'lmonth'};
		$year=$param{'lyear'};
	}
	elsif ($param{'date'} eq '>>') {
		$month=$param{'nmonth'};
                $year=$param{'nyear'};
        }
	else {
		$month=$param{'month'};
		$year=$param{'year'};
	}
		 
	$cal = new HTML::CalendarMonthDB('month'=>$month, 'year'=>$year, 'dbname'=>$dbname, 'dbuser'=>$dbuser, 'dbcalendar'=>$dbcalendar, 'dbclient'=>$dbclient, 'dbhost'=>$dbhost);
        }

$htmlOut .= calNav($cal->month(), $cal->year());
$htmlOut .= '</form>';
$cal->getdbcalendar();
$cal->getdbcontent();

if (!$type) {
	$htmlOut .= $cal->as_HTML(editurl=>'editcal.cgi', addurl=>'addcal.cgi');
	if ($param{'publish'}) {
		my $pubdir=$ENV{'CAL_PUB_DIR'};
		my $pubfile= '>'.$pubdir.'/'.$month."_".$year.'.txt';	
		open(FILE, $pubfile) || print "Cannot open $pubfile for writing.";
		print FILE $cal->as_HTML();	
		close(FILE);	
	}
}
else {
	$htmlOut .= $cal->as_HTML_list(editurl=>'editcal.cgi', addurl=>'addcal.cgi');
	if ($param{'publish'}) {
                my $pubdir=$ENV{'CAL_PUB_DIR'};
		my $pubfile= '>'.$pubdir.'/'.$month."_".$year.'.cal';
                open(FILE, $pubfile) || print "Cannot open $pubfile for writing."; 
                print FILE $cal->as_HTML_list();
		close(FILE);
        }
}

$htmlOut .= '<br><br><form name="calchange" method="post" action="calendar.cgi">';
$htmlOut .= "<input type=\"hidden\" name=\"month\" value=\"$month\" override=\"1\">";
$htmlOut .= "<input type=\"hidden\" name=\"year\" value=\"$year\" override=\"1\">";
$htmlOut .= "<input type=\"hidden\" name=\"view\" value=\"".$param{'view'}."\" override=\"1\">"; 
$htmlOut .= "<input type=\"submit\" name=\"publish\" value=\"Publish this Month\">";

$htmlOut .= '<table border="1" cellpadding="3"><tr bgcolor="red"><td colspan="2"><b><font color="ffffff" size="4"><center>Modify Calendar Attributes</center></b></font></td></tr>';

#$htmlOut .= '<tr bgcolor="ddddff"><td></td><td><input type="text" name="" value="'.$cal->().'"></td></tr>'; #template
$htmlOut .= '<tr bgcolor="ddddff"><td>Border Size</td><td><input type="text" name="border" value="'.$cal->border().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Width</td><td><input type="text" name="width" value="'.$cal->width().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Calendar Background Color</td><td><input type="text" name="bgcolor" value="'.$cal->bgcolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Weekday Color</td><td><input type="text" name="weekdaycolor" value="'.$cal->weekdaycolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Weekend Color</td><td><input type="text" name="weekendcolor" value="'.$cal->weekendcolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Current Day Color</td><td><input type="text" name="todaycolor" value="'.$cal->todaycolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Border Color</td><td><input type="text" name="bordercolor" value="'.$cal->bordercolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Weekday Border Color</td><td><input type="text" name="weekdaybordercolor" value="'.$cal->weekdaybordercolor().'"></td></tr>';$htmlOut .= '<tr bgcolor="ddddff"><td>Weekend Border Color</td><td><input type="text" name="weekendbordercolor" value="'.$cal->weekendbordercolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Current Day Border Color</td><td><input type="text" name="todaybordercolor" value="'.$cal->todaybordercolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Content Color</td><td><input type="text" name="contentcolor" value="'.$cal->contentcolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Weekday Content Color</td><td><input type="text" name="weekdaycontentcolor" value="'.$cal->weekdaycontentcolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Weekend Content Color</td><td><input type="text" name="weekendcontentcolor" value="'.$cal->weekendcontentcolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Current Day Content Color</td><td><input type="text" name="todaycontentcolor" value="'.$cal->todaycontentcolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Header Color</td><td><input type="text" name="headercolor" value="'.$cal->headercolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Weekday Header Color</td><td><input type="text" name="weekdayheadercolor" value="'.$cal->weekdayheadercolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Weekend Header Color</td><td><input type="text" name="weekendheadercolor" value="'.$cal->weekendheadercolor().'"></td></tr>';
$htmlOut .= '<tr bgcolor="ddddff"><td>Cell Alignment</td><td><input type="text" name="cellalignment" value="'.$cal->cellalignment().'"></td></tr>';


$htmlOut .= '<tr><td colspan="2"><center><input type="submit" name="change" value="Commit Changes"><input type="reset" value="Reset Form"><input type="submit" name="default" value="Default Settings"></center></td></tr></table>';

$htmlOut .= '</form>';

$template->param(
	CALENDAR => $htmlOut
);

# print the template
print $template->output;
}

###################################################################

sub calNav {
 	my($count,$month, $year, $lmonth, $lyear, $nmonth, $nyear, $html);
	$month=shift;
	$year=shift;	
	
	if ($month eq 1) {
		$nmonth=2;
		$nyear=$year;
		$lmonth=12;
		$lyear=$year-1;
	}
	elsif ($month eq 12) {
		$nmonth=1;
		$nyear=$year+1;
		$lmonth=11;
		$lyear=$year;
	}
	else {
		$nmonth=$month+1;
		$nyear=$year;
		$lmonth=$month-1;
		$lyear=$year;
	}
	$html .= '<font size=2><select name="month">';
	for ($count=1; $count<=12; $count++) {
		$html .= "<option value=\"$count\" ";
		if ($count == $month) {
			$html .= "SELECTED";
		}
		$html .= ">$count";
	}
	$html .= '</select> / <select name="year">';
	$html .= '<option value="'.($year-2).'">'.($year-2);
	$html .= '<option value="'.($year-1).'">'.($year-1);
	$html .= "<option value=\"$year\" SELECTED>$year";	
	$html .= '<option value="'.($year+1).'">'.($year+1);
	$html .= '<option value="'.($year+2).'">'.($year+2);
	$html .= '</select><input type="submit" name="date" value="Go"><br>';
	$html .= '<font size=1><input type="submit" name="date" value="<<">';
	$html .= '<input type="submit" name="date" value=">>"></font>';
	$html .= "<input type=\"hidden\" name=\"lmonth\" value=\"$lmonth\" override=\"1\">";
        $html .= "<input type=\"hidden\" name=\"lyear\" value=\"$lyear\" override=\"1\">";
        $html .= "<input type=\"hidden\" name=\"nmonth\" value=\"$nmonth\" override=\"1\">";
        $html .= "<input type=\"hidden\" name=\"nyear\" value=\"$nyear\" override=\"1\">";

	return $html;
}

