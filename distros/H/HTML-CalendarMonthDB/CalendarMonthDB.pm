# HTML::CalendarMonthDB.pm
# Generate persistant or non-persistant HTML calendars. 
# An alternative to HTML::CalendarMonth and HTML::CalendarMonthSimple
# Herein, the symbol $self is used to refer to the object that's being passed around.

package HTML::CalendarMonthDB;
my $VERSION     = "1.0";
use strict;
use Date::Calc;

# Within the constructor is the only place where values are access directly.
# Methods are provided for accessing/changing values, and those methods
# are used even internally.
# Most of the constructor is assigning default values.
sub new {
   my $class = shift; $class = ref($class) || $class;
   my $self = {}; %$self = @_; # Load ourselves up from the args

   # Set the month and year to either args or today
   ($self->{'month'})  || ($self->{'month'}  = (Date::Calc::Today)[1]);
   ($self->{'year'})   || ($self->{'year'}   = (Date::Calc::Today)[0]);

   # Some defaults
   $self->{'border'}             = 5;
   $self->{'width'}              = '100%';
   $self->{'showdatenumbers'}    = 1;
   $self->{'showweekdayheaders'} = 1;
   $self->{'cellalignment'}      = 'left';
   $self->{'bgcolor'}		 = 'ffffff';

   if ($self->{'dbname'}) {
	use DBI;
   	# det defaults	
   	($self->{'dbuser'}) || ($self->{'dbuser'} = 'nobody');
	($self->{'dbpass'}) || ($self->{'dbpass'} = '');
  	($self->{'dbcalendar'}) || ($self->{'dbcalendar'} = '');
        ($self->{'dbclient'}) || ($self->{'dbclient'} = '');
	($self->{'dbhost'}) || ($self->{'dbhost'} = '');
   }


   # Set the default calendar header
   $self->{'header'} = sprintf("<center><font size=+2>%s %d</font></center>",
                               Date::Calc::Month_to_Text($self->{'month'}),$self->{'year'});

   # Get the monthname now so monthname() is fast and efficient
   $self->{'monthname'} = Date::Calc::Month_to_Text($self->{'month'});

   # Initialize the (empty) cell content so the keys are representative of the month
   map { $self->{'content'}->{$_} = ''; } (1 .. Date::Calc::Days_in_Month($self->{'year'},$self->{'month'}));
   # Initialize the non-standard date buckets: weekdays, etc.
   foreach my $day ('sunday','monday','tuesday','wednesday','thursday','friday','saturday') {
      $self->{'content'}->{$day."s"} = ''; # "Mondays", "Tuesdays", etc.
      foreach my $which (1 .. 5) { $self->{'content'}->{$which.$day} = ''; } # "2Sunday", "3Wednesday", etc.
   }

   # All done!
   bless $self,$class; return $self;
}

sub as_HTML_list {
   my $self = shift;
   my $self1 = {}; %$self1 = @_; # Load ourselves up from the args 
   my $editurl = $self1->{'editurl'} if $self1->{'editurl'};
   my $addurl = $self1->{'addurl'} if $self1->{'addurl'};
   my $html = '';
   my(@days,$weeks,$WEEK,$DAY);

   my $border = $self->border();
   my $tablewidth = $self->width();
   my $header = $self->header();
   my $bgcolor = $self->bgcolor() || '';
   my $cellalignment = $self->cellalignment(); 
   my $weekdaycolor = $self->weekdaycolor() || $self->bgcolor();
   my $weekendcolor = $self->weekendcolor() || $self->bgcolor();
   my $todaycolor = $self->todaycolor() || $self->bgcolor();
   my $contentcolor = $self->contentcolor() || $self->contentcolor();
   my $weekdaycontentcolor = $self->weekdaycontentcolor() || $self->contentcolor(); 
   my $weekendcontentcolor = $self->weekendcontentcolor() || $self->contentcolor(); 
   my $todaycontentcolor = $self->todaycontentcolor() || $self->contentcolor();
   my $bordercolor = $self->bordercolor() || $self->bordercolor();
   my $weekdaybordercolor = $self->weekdaybordercolor() || $self->bordercolor(); 
   my $weekendbordercolor = $self->weekendbordercolor() || $self->bordercolor(); 
   my $todaybordercolor = $self->todaybordercolor() || $self->bordercolor();
   my $weekdayheadercolor = $self->weekdayheadercolor() || $self->bgcolor();
   my $weekendheadercolor = $self->weekendheadercolor() || $self->bgcolor();
   my $headercolor = $self->headercolor() || $self->bgcolor();
   # Get today's date, in case there's a todaycolor()
   my($todayyear,$todaymonth,$todaydate) = Date::Calc::Today();


   # add javascript popup description code
   $html .= $self->jscode();

   @days = (1 .. Date::Calc::Days_in_Month($self->year(),$self->month() ) );
   foreach (1 .. (Date::Calc::Day_of_Week($self->year(),$self->month(),1)%7) ) {
      unshift(@days,0);
   }
   $weeks = int((scalar(@days)+6)/7);

   $html .= "<table width=\"$tablewidth\" border=\"$border\" bgcolor=\"$bgcolor\" bordercolor=\"$bordercolor\"><tr><td colspan=2 bgcolor=\"$headercolor\">$header</td></tr>";
	
foreach $WEEK (0 .. ($weeks-1)) {
    foreach $DAY (0 .. 6) {
    my($content,$thisday,$thisbgcolor,$thisbordercolor,$thiscontentcolor);
    $thisday = $days[((7*$WEEK)+$DAY)];
    if ($thisday) {
    $content=$self->getcontent($thisday);
	if ($self->year == $todayyear && $self->month == $todaymonth && $thisday == $todaydate)
                                           { $thisbgcolor = $todaycolor;
                                             $thisbordercolor = $todaybordercolor;
                                             $thiscontentcolor = $todaycontentcolor;
                                            }
         elsif (($DAY == 0) || ($DAY == 6)){ $thisbgcolor = $weekendcolor;
                                             $thisbordercolor = $weekendbordercolor;
                                             $thiscontentcolor = $weekendcontentcolor;
                                            }
         else                               { $thisbgcolor = $weekdaycolor;
                                                $thisbordercolor = $weekdaybordercolor;
                                                $thiscontentcolor = $weekdaycontentcolor;
                                            }

	
	if (!$content) {
        $content = '&nbsp;'; 
	}
  	$html .= "<tr><td width=\"2%\"><b>$thisday</b>";
	# Add admin links if specified in function call 
        if ($addurl) {
	        my $calid = $self->calendarid();
       		my $mdate = $self->month().'_'.$thisday.'_'.$self->year();
                $html .= "<br><font size=\"1\"><a href=\"#\" onclick=popup(\"$addurl?date=$mdate&calid=$calid&view=list\")>[Add]</a></font>";
                }
        if ($editurl) {
        	my $calid = $self->calendarid();
        	my $mdate = $self->month().'_'.$thisday.'_'.$self->year();
                $html .= "<br><font size=\"1\"><a href=\"#\" onclick=popup(\"$editurl?date=$mdate&calid=$calid&view=list\")>[Edit]</a></font>";
	}
	$html .= "</td><td bgcolor=\"$thisbgcolor\" bordercolor=\"$thisbordercolor\" align=\"$cellalignment\"><font color=\"$thiscontentcolor\">$content</font></td></tr>\n"; 
  	} 
   } 
   }
   $html .= '</table>';
   return $html;
}

sub as_HTML {
   my $self = shift;
   my $self1 = {}; %$self1 = @_; # Load ourselves up from the args
   my $editurl = $self1->{'editurl'} if $self1->{'editurl'};
   my $addurl = $self1->{'addurl'} if $self1->{'addurl'};
   my $html = '';
   my(@days,$weeks,$WEEK,$DAY);
  
   # add javascript popup description code
   $html .= $self->jscode();

   # To make the grid even, pad the start of the series with 0s
   @days = (1 .. Date::Calc::Days_in_Month($self->year(),$self->month() ) );
   foreach (1 .. (Date::Calc::Day_of_Week($self->year(),$self->month(),1)%7) ) {
      unshift(@days,0);
   }
   $weeks = int((scalar(@days)+6)/7);

   # Define some scalars for generating the table
   my $border = $self->border();
   my $tablewidth = $self->width();
   $tablewidth =~ m/^(\d+)(\%?)$/; my $cellwidth = (int($1/7))||'14'; if ($2) { $cellwidth .= '%'; }
   my $header = $self->header();
   my $cellalignment = $self->cellalignment();
   my $bgcolor = $self->bgcolor() || '';
   my $weekdaycolor = $self->weekdaycolor() || $self->bgcolor();
   my $weekendcolor = $self->weekendcolor() || $self->bgcolor();
   my $todaycolor = $self->todaycolor() || $self->bgcolor();
   my $contentcolor = $self->contentcolor() || $self->contentcolor();
   my $weekdaycontentcolor = $self->weekdaycontentcolor() || $self->contentcolor();
   my $weekendcontentcolor = $self->weekendcontentcolor() || $self->contentcolor();
   my $todaycontentcolor = $self->todaycontentcolor() || $self->contentcolor();
   my $bordercolor = $self->bordercolor() || $self->bordercolor();
   my $weekdaybordercolor = $self->weekdaybordercolor() || $self->bordercolor();
   my $weekendbordercolor = $self->weekendbordercolor() || $self->bordercolor();
   my $todaybordercolor = $self->todaybordercolor() || $self->bordercolor();
   my $weekdayheadercolor = $self->weekdayheadercolor() || $self->bgcolor();
   my $weekendheadercolor = $self->weekendheadercolor() || $self->bgcolor();
   my $headercolor = $self->headercolor() || $self->bgcolor();
   # Get today's date, in case there's a todaycolor()
   my($todayyear,$todaymonth,$todaydate) = Date::Calc::Today();

   $html .= "<TABLE BORDER=\"$border\" WIDTH=\"$tablewidth\" BGCOLOR=\"$bgcolor\" BORDERCOLOR=\"$bordercolor\">\n";
   $html .= "<tr><td colspan=7 bgcolor=\"$headercolor\">$header</td></tr>\n" if $header;
   if ($self->showweekdayheaders) {
      # Ultimately, this will display a hashref contents instead of a static week...
      #$html .= "<tr>\n<th>Sunday</th>\n<th>Monday</th>\n<th>Tuesday</th>\n<th>Wednesday</th>\n<th>Thursday</th>\n<th>Friday</th>\n<th>Saturday</th>\n</tr>\n";
      $html .= "<tr>\n<th bgcolor=\"$weekendheadercolor\">Sunday</th>\n<th bgcolor=\"$weekdayheadercolor\">Monday</th>\n<th bgcolor=\"$weekdayheadercolor\">Tuesday</th>\n<th bgcolor=\"$weekdayheadercolor\">Wednesday</th>\n<th bgcolor=\"$weekdayheadercolor\">Thursday</th>\n<th bgcolor=\"$weekdayheadercolor\">Friday</th>\n<th bgcolor=\"$weekendheadercolor\">Saturday</th>\n</tr>\n";
   }
   foreach $WEEK (0 .. ($weeks-1)) {
      $html .= "<TR>\n";
      foreach $DAY (0 .. 6) {
         my($thiscontent,$thisday,$thisbgcolor,$thisbordercolor,$thiscontentcolor);
         $thisday = $days[((7*$WEEK)+$DAY)];
         # Get the cell content
         if (! $thisday) { # If it's a dummy cell, no content
            $thiscontent = '&nbsp;'; }
         else { # A real date cell with potential content
            # Get the content
            if ($self->showdatenumbers()) { 
                $thiscontent = "<p><b>$thisday</b>";
	
		# Add admin links if specified in function call	
		if ($addurl) {
			my $calid = $self->calendarid();
                        my $mdate = $self->month().'_'.$thisday.'_'.$self->year();
                        $thiscontent .= " <font size=\"1\"><a href=\"#\" onclick=popup(\"$addurl?date=$mdate&calid=$calid&view=standard\")>[Add]</a></font>";
                }
		if ($editurl) {
                        my $calid = $self->calendarid();
                        my $mdate = $self->month().'_'.$thisday.'_'.$self->year();                        
			$thiscontent .= " <font size=\"1\"><a href=\"#\" onclick=popup(\"$editurl?date=$mdate&calid=$calid&view=standard\")>[Edit]</a></font>";
                }
		$thiscontent .= "</p>\n";
            }
            # Content for this specific date
            $thiscontent .= $self->getcontent($thisday);
            # Content for "2nd Wednesday", etc.
            $thiscontent .= $self->getcontent(int(1+($thisday/7.1)).('sunday','monday','tuesday','wednesday','thursday','friday','saturday')[$DAY]);
            # Content for "Wednesdays", etc.
            $thiscontent .= $self->getcontent(('sundays','mondays','tuesdays','wednesdays','thursdays','fridays','saturdays')[$DAY]);
            # Normalize if there's no content
            $thiscontent .= '&nbsp;';
         }
         # Get the cell's coloration
         if ($self->year == $todayyear && $self->month == $todaymonth && $thisday == $todaydate)
                                              { $thisbgcolor = $todaycolor;
                                                $thisbordercolor = $todaybordercolor;
                                                $thiscontentcolor = $todaycontentcolor;
                                              }
         elsif (($DAY == 0) || ($DAY == 6))   { $thisbgcolor = $weekendcolor;
                                                $thisbordercolor = $weekendbordercolor;
                                                $thiscontentcolor = $weekendcontentcolor;
                                              }
         else                                 { $thisbgcolor = $weekdaycolor;
                                                $thisbordercolor = $weekdaybordercolor;
                                                $thiscontentcolor = $weekdaycontentcolor;
                                              }
         # Done with this cell - push it into the table
         $html .= "<TD WIDTH=\"$cellwidth\" VALIGN=\"$cellalignment\" ALIGN=\"$cellalignment\" BGCOLOR=\"$thisbgcolor\" BORDERCOLOR=\"$thisbordercolor\"><FONT COLOR=\"$thiscontentcolor\">$thiscontent</FONT></TD>\n";
      }
      $html .= "</TR>\n";
   }
   $html .= "</TABLE>\n";
   return $html;
}

sub jscode {
my $self = shift;
my $jscode = '<div id="object1" style="position:absolute; visibility:show; left:350px; top:-50px; z-index:2">layer hidden off the screen</div><SCRIPT LANGUAGE="JavaScript">
<!-- Begin
window.onLoad=setupDescriptions();
function popup(url) {
window.open(url, "popup", "height=480,width=580,menubar=no,scrollbars=yes,status=no,toolbar=no,screenX=100,screenY=0,left=100,top=100"); 
}
function setupDescriptions() {
var x = navigator.appVersion;
y = x.substring(0,4);
if (y>=4) setVariables();
}
var x,y,a,b;
function setVariables(){
if (navigator.appName == "Netscape") {
h=".left=";
v=".top=";
dS="document.";
sD="";
}
else 
{
h=".pixelLeft=";
v=".pixelTop=";
dS="";
sD=".style";
   }
}
var isNav = (navigator.appName.indexOf("Netscape") !=-1);
function popLayer(a){
var popWidth;
if(isNav) {
	if ((window.innerWidth - x) > (window.innerWidth/2)) {
		popWidth = window.innerWidth/2;
	}
	else {
		popWidth = window.innerWidth - x - 40;
	}
}
else { 
	if ((document.body.clientWidth - x) > (document.body.clientWidth/2)) {
		popWidth =  document.body.clientWidth/2;
	}
	else {
		popWidth = document.body.clientWidth - x - 40;
	}
}
desc = "<table cellpadding=3 border=1 bgcolor=ffff11 width=" + popWidth + "><td align=center>";'.$self->jsDescs.'
desc += "</td></table>";

if(isNav) {
document.object1.document.write(desc);
document.object1.document.close();
document.object1.left=x+5;
document.object1.top=y;
}
else {
object1.innerHTML=desc;
eval(dS+"object1"+sD+h+(x+5));
eval(dS+"object1"+sD+v+y);
   }
}
function hideLayer(a){
if(isNav) {
eval(document.object1.top=a);
}
else object1.innerHTML="";
}
function handlerMM(e){
x = (isNav) ? e.pageX : event.clientX;
y = (isNav) ? e.pageY : event.clientY;
}
if (isNav){
document.captureEvents(Event.MOUSEMOVE);
}
document.onmousemove = handlerMM;
//  End -->
</script>';

$self->{'jscode'} = $jscode;

return $self->{'jscode'}; 
}

sub weekendcolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'weekendcolor'} = $newvalue; }
   return $self->{'weekendcolor'};
}

sub weekendheadercolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'weekendheadercolor'} = $newvalue; }
   return $self->{'weekendheadercolor'};
}

sub weekdayheadercolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'weekdayheadercolor'} = $newvalue; }
   return $self->{'weekdayheadercolor'};
}

sub weekdaycolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'weekdaycolor'} = $newvalue; }
   return $self->{'weekdaycolor'};
}

sub headercolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'headercolor'} = $newvalue; }
   return $self->{'headercolor'};
}

sub bgcolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'bgcolor'} = $newvalue; }
   return $self->{'bgcolor'};
}

sub todaycolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'todaycolor'} = $newvalue; }
   return $self->{'todaycolor'};
}

sub bordercolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'bordercolor'} = $newvalue; }
   return $self->{'bordercolor'};
}

sub weekdaybordercolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'weekdaybordercolor'} = $newvalue; }
   return $self->{'weekdaybordercolor'};
}

sub weekendbordercolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'weekendbordercolor'} = $newvalue; }
   return $self->{'weekendbordercolor'};
}

sub todaybordercolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'todaybordercolor'} = $newvalue; }
   return $self->{'todaybordercolor'};
}

sub contentcolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'contentcolor'} = $newvalue; }
   return $self->{'contentcolor'};
}

sub weekdaycontentcolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'weekdaycontentcolor'} = $newvalue; }
   return $self->{'weekdaycontentcolor'};
}

sub weekendcontentcolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'weekendcontentcolor'} = $newvalue; }
   return $self->{'weekendcontentcolor'};
}

sub todaycontentcolor {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'todaycontentcolor'} = $newvalue; }
   return $self->{'todaycontentcolor'};
}

sub getcontent {
   my $self = shift;
   my $date = lc(shift) || return(); $date = int($date) if $date =~ m/^[\d\.]+$/;
   return $self->{'content'}->{$date};
}

sub getdbevent {
   my $self = shift;
   my $date = shift;
   my $month = $self->month();
   my $year = $self->year();	
   my $calendarid = $self->calendarid();
   my $dbname = $self->dbname();
   my $dbuser = $self->dbuser();
   my $dbpass = $self->dbpass();
   my $dbhost = $self->dbhost();
   $dbhost = ":host=$dbhost" if (!($dbhost eq ''));   
   my $dbclient = $self->dbclient();
   my %content;
   my $dbh = DBI->connect("dbi:Pg:dbname=$dbname$dbhost", $dbuser, $dbpass) || return;
   my($getContent)=$dbh->prepare("select eventid, eventday, eventmonth, eventyear, eventtime, eventname, eventdesc,eventlink from event where eventday= ? and eventmonth=? and eventyear=? and calendarid=? order by eventtime, eventid");

   $getContent->execute($date,$month,$year,$calendarid) || return $dbh->errstr();
   while (my($eventid,$eventday,$eventmonth,$eventyear,$eventtime,$eventname,$eventdesc,$eventlink) = $getContent->fetchrow_array()) {
	$content{$eventid}{'eventtime'} = $eventtime if $eventtime;
	$content{$eventid}{'eventday'} = $eventday if $eventday;
	$content{$eventid}{'eventmonth'} = $eventmonth if $eventmonth;
	$content{$eventid}{'eventyear'} = $eventyear if $eventyear;
	$content{$eventid}{'eventname'} = $eventname if $eventname;
	$content{$eventid}{'eventdesc'} = $eventdesc if $eventdesc;
	$content{$eventid}{'eventlink'} = $eventlink if $eventlink;
   }

   $dbh->disconnect();
   return %content;
}

sub getdbcalendar {
   my $self = shift;
   my $dbname = $self->dbname();
   my $dbuser = $self->dbuser();
   my $dbpass = $self->dbpass();
   my $dbhost = $self->dbhost();
   $dbhost = ":host=$dbhost" if (!($dbhost eq ''));
   my $calendarid = $self->calendarid();
   my $dbclient = $self->dbclient();

   my $dbh = DBI->connect("dbi:Pg:dbname=$dbname$dbhost", $dbuser, $dbpass) || return;

   my($getCalendarInfo)=$dbh->prepare("select border,width,bgcolor,weekdaycolor,weekendcolor,todaycolor,bordercolor,weekdaybordercolor,weekendbordercolor,todaybordercolor,contentcolor,weekdaycontentcolor,weekendcontentcolor,todaycontentcolor,headercolor,weekdayheadercolor,weekendheadercolor,header,cellalignment from calendar where calendarID = ?");

   $getCalendarInfo->execute($calendarid) ||print $dbh->errstr();


   # load calendar formatting data from database and set values.
   while (my($border,$width,$bgcolor,$weekdaycolor,$weekendcolor,$todaycolor, $bordercolor,$weekdaybordercolor,$weekendbordercolor,$todaybordercolor,$contentcolor,$weekdaycontentcolor,$weekendcontentcolor,$todaycontentcolor,$headercolor,$weekdayheadercolor,$weekendheadercolor,$header,$cellalignment) = $getCalendarInfo->fetchrow_array()) {
	$self->border($border) if $border;
	$self->width($width) if $width;
	$self->bgcolor($bgcolor) if $bgcolor;
	$self->weekdaycolor($weekdaycolor) if $weekdaycolor;
	$self->weekendcolor($weekendcolor) if $weekendcolor;
	$self->todaycolor($todaycolor) if $todaycolor;
	$self->bordercolor($bordercolor) if $bordercolor;
	$self->weekdaybordercolor($weekdaybordercolor) if $weekdaybordercolor;
	$self->weekendbordercolor($weekendbordercolor) if $weekendbordercolor;
	$self->todaybordercolor($todaybordercolor) if $todaybordercolor;
	$self->contentcolor($contentcolor) if $contentcolor;
	$self->weekdaycontentcolor($weekdaycontentcolor) if $weekdaycontentcolor;
	$self->weekendcontentcolor($weekendcontentcolor) if $weekendcontentcolor;
	$self->todaycontentcolor($todaycontentcolor) if $todaycontentcolor;
	$self->headercolor($headercolor) if $headercolor;
	$self->weekdayheadercolor($weekdayheadercolor) if $weekdayheadercolor;
	$self->weekendheadercolor($weekendheadercolor) if $weekendheadercolor;
	$self->header($header) if $header;
	$self->cellalignment($cellalignment) if $cellalignment;	
}  

   $dbh->disconnect();
}

sub editdbcalendar {

   my $self = shift;
   my $self1 = {}; %$self1 = @_; # Load ourselves up from the args
   my $dbname = $self->dbname();
   my $dbuser = $self->dbuser();
   my $dbpass = $self->dbpass();
   my $dbhost = $self->dbhost();
   $dbhost = ":host=$dbhost" if (!($dbhost eq ''));
   my $calendarid = $self->calendarid();

   if ($self1->{'border'} && !($self1->{'border'} =~ /\d+/)) {
	$self1->{'border'} =1;
   }

   my $query = "update calendar set calendarid = ?";
   $query .= ", border = '".$self1->{'border'}."'" if $self1->{'border'}; 
   $query .= ", width = '".$self1->{'width'}."'" if $self1->{'width'};    $query .= ", bgcolor = '".$self1->{'bgcolor'}."'" if $self1->{'bgcolor'};
   $query .= ", weekdaycolor = '".$self1->{'weekdaycolor'}."'" if $self1->{'weekdaycolor'};
   $query .= ", weekendcolor = '".$self1->{'weekendcolor'}."'" if $self1->{'weekendcolor'};
   $query .= ", todaycolor = '".$self1->{'todaycolor'}."'" if $self1->{'todaycolor'};
   $query .= ", bordercolor = '".$self1->{'bordercolor'}."'" if $self1->{'bordercolor'};
   $query .= ", weekdaybordercolor = '".$self1->{'weekdaybordercolor'}."'" if $self1->{'weekdaybordercolor'};
   $query .= ", weekendbordercolor = '".$self1->{'weekendbordercolor'}."'" if $self1->{'weekendbordercolor'};
   $query .= ", todaybordercolor = '".$self1->{'todaybordercolor'}."'" if $self1->{'todaybordercolor'};
   $query .= ", contentcolor = '".$self1->{'contentcolor'}."'" if $self1->{'contentcolor'};
   $query .= ", weekdaycontentcolor = '".$self1->{'weekdaycontentcolor'}."'" if $self1->{'weekdaycontentcolor'};
   $query .= ", weekendcontentcolor = '".$self1->{'weekendcontentcolor'}."'" if $self1->{'weekendcontentcolor'};
   $query .= ", todaycontentcolor = '".$self1->{'todaycontentcolor'}."'" if $self1->{'todaycontentcolor'};
   $query .= ", headercolor = '".$self1->{'headercolor'}."'" if $self1->{'headercolor'};
   $query .= ", weekdayheadercolor = '".$self1->{'weekdayheadercolor'}."'" if $self1->{'weekdayheadercolor'};
   $query .= ", weekendheadercolor = '".$self1->{'weekendheadercolor'}."'" if $self1->{'weekendheadercolor'};
   $query .= ", header = '".$self1->{'header'}."'" if $self1->{'header'};
   $query .= ", cellalignment = '".$self1->{'cellalignment'}."'" if $self1->{'cellalignment'};
   $query .= " where calendarID = ?";

   my $dbh = DBI->connect("dbi:Pg:dbname=$dbname$dbhost", $dbuser, $dbpass) || return;

   my $updateCal = $dbh->prepare($query);
   $updateCal->execute($calendarid, $calendarid) ||print $dbh->errstr();
   $dbh->disconnect();
    
   return(1);

}
sub getdbcontent {
   my $self = shift;
   my $dbname = $self->dbname();
   my $dbuser = $self->dbuser();
   my $dbpass = $self->dbpass();
   my $dbhost = $self->dbhost();
   $dbhost = ":host=$dbhost" if (!($dbhost eq ''));   
   my $calendarid = $self->calendarid();
   my $dbclient = $self->dbclient();
   my $month = $self->month();
   my $year = $self->year(); 
   my $jsDescs='';
   my $dbh = DBI->connect("dbi:Pg:dbname=$dbname$dbhost", $dbuser, $dbpass) || return;

   my($getContent)=$dbh->prepare("select eventID, eventTime, eventDay, eventName, eventDesc, eventLink from event where calendarID = ? and eventMonth = ? and eventYear = ? order by eventDay, eventTime");
 
   $getContent->execute($calendarid, $month, $year) ||print $dbh->errstr();

   while (my($eventID, $eventTime, $eventDay, $eventName, $eventDesc, $eventLink) = $getContent->fetchrow_array()) {
	$eventLink = '#' if !$eventLink;	
	$self->{'content'}->{$eventDay} .= "$eventTime:" if $eventTime;
  	$self->{'content'}->{$eventDay} .= "<a href='$eventLink' onMouseOver='popLayer($eventID)' onMouseOut='hideLayer(-50000)'>$eventName</a><br><br>"; 
   
	$jsDescs .="if (a==$eventID) desc += \"$eventDesc\";\n";
   }
   $getContent->finish(); 
   $dbh->disconnect();
   
   $self->jsDescs($jsDescs);

   return(1);
}
sub setcontent {
   my $self = shift;
   my $date = lc(shift) || return(); $date = int($date) if $date =~ m/^[\d\.]+$/;
   my $newcontent = shift || '';
   return() unless defined($self->{'content'}->{$date});
   $self->{'content'}->{$date} = $newcontent;
   return(1);
}

sub addevent {
   my $self = shift;
   my $date = lc(shift) || return(); $date = int($date) if $date =~ m/^[\d+\.]+$/;
   my $newcontent = shift || return();
   return() unless defined($self->{'content'}->{$date});
   $self->{'content'}->{$date} .= $newcontent;
   return(1);
}

sub adddbevent {
   my $self = shift;
   my $self1 = {}; %$self1 = @_; # Load ourselves up from the args
   my $dbname = $self->dbname();
   my $dbuser = $self->dbuser();
   my $dbpass = $self->dbpass();
   my $dbhost = $self->dbhost();
   $dbhost = ":host=$dbhost" if (!($dbhost eq '')); 
   my $dbcalendar = $self->dbcalendar();
   my $month = $self->month();
   my $year = $self->year();
   my $calendarID=$self->calendarid();
   my $date = $self1->{'date'};
   my $eventname = $self1->{'eventname'};
   my $eventdesc = $self1->{'eventdesc'};
   $eventdesc =~ s/\s+/ /g;
   my $eventlink = $self1->{'eventlink'};
   my $eventtime = $self1->{'eventtime'};
   my $dbh = DBI->connect("dbi:Pg:dbname=$dbname$dbhost", $dbuser, $dbpass) || return;
   my $addContent= $dbh->prepare("insert into event (calendarid, eventday, eventmonth, eventyear, eventname, eventdesc, eventlink, eventtime) values(?, ?, ?, ?, ?, ?, ?, ?)");
   $addContent->execute($calendarID, $date, $month, $year, $eventname, $eventdesc, $eventlink, $eventtime)||print $dbh->errstr();
   $dbh->disconnect();
   return(1);
}

sub deldbevent {
my $self = shift;
my $eventid = shift;
my $dbname = $self->dbname();
my $dbuser = $self->dbuser();
my $dbpass = $self->dbpass();
my $dbhost = $self->dbhost();
$dbhost = ":host=$dbhost" if (!($dbhost eq ''));

my $dbh = DBI->connect("dbi:Pg:dbname=$dbname$dbhost", $dbuser, $dbpass) || return;
my $delEvent= $dbh->prepare("delete from event where eventID = ?");
$delEvent->execute($eventid)||print $dbh->errstr();
$dbh->disconnect();
return(1);
}

sub editdbevent {
   my $self = shift;
   my $self1 = {}; %$self1 = @_; # Load ourselves up from the args
   my $dbname = $self->dbname();
   my $dbuser = $self->dbuser();
   my $dbpass = $self->dbpass();
   my $dbhost = $self->dbhost();
   $dbhost = ":host=$dbhost" if (!($dbhost eq '')); 
   my $eventid = $self1->{'eventid'};
   # eventid needed to update specific event 
   $eventid || return;
  
   # create query from specified args
   my $query = "update event set eventid = ?";
   $query .=  ", eventlink = '".$self1->{'eventlink'}."' " if $self1->{'eventlink'};
   if ($self1->{'eventdesc'}) {
	$self1->{'eventdesc'} =~ s/\s+/ /g;
  	$query .=  ", eventdesc = '".$self1->{'eventdesc'}."' ";
   } 
   $query .=  ", eventname = '".$self1->{'eventname'}."' " if $self1->{'eventname'};
   $query .=  ", eventday = '".$self1->{'eventday'}."' " if $self1->{'eventday'};
   $query .=  ", eventmonth = '".$self1->{'eventmonth'}."' " if $self1->{'eventmonth'};
   $query .=  ", eventyear = '".$self1->{'eventyear'}."' " if $self1->{'eventyear'};
   $query .=  ", eventtime = '".$self1->{'eventtime'}."' " if $self1->{'eventtime'};
   $query .=  " where eventid = ?";
   my $dbh = DBI->connect("dbi:Pg:dbname=$dbname$dbhost", $dbuser, $dbpass) || return;
   my $editEvent= $dbh->prepare($query);
   $editEvent->execute($eventid, $eventid) ||print $dbh->errstr();
   $dbh->disconnect();
   return(1);
}

sub calendarid {
my $self = shift;
my $dbname = $self->dbname();
my $dbuser = $self->dbuser();
my $dbpass = $self->dbpass();
my $dbhost = $self->dbhost();
$dbhost = ":host=$dbhost" if (!($dbhost eq ''));
my $dbcalendar = $self->dbcalendar();
my $dbclient = $self->dbclient();

my $dbh = DBI->connect("dbi:Pg:dbname=$dbname$dbhost", $dbuser, $dbpass) || return;
  
my($getCalendarID)=$dbh->prepare("select calendar.calendarID from calendar, client where calendar.name= ? and calendar.clientID=client.clientID and client.clientName= ?");
   
$getCalendarID->execute($dbcalendar, $dbclient) ||print $dbh->errstr();

my $calendarID=$getCalendarID->fetchrow_array();
   
$getCalendarID->finish();

$dbh->disconnect();

$self->{'calendarid'} = $calendarID;

return $self->{'calendarid'};
}

sub border {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'border'} = int($newvalue); }
   return $self->{'border'};
}

sub jsDescs {
my $self = shift;
my $newvalue = shift;
if (defined($newvalue)) { 
	$self->{'jsDescs'} .= $newvalue; 
}
return $self->{'jsDescs'};
}

sub width {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'width'} = $newvalue; }
   return $self->{'width'};
}

sub showdatenumbers {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'showdatenumbers'} = $newvalue; }
   return $self->{'showdatenumbers'};
}
sub showweekdayheaders {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'showweekdayheaders'} = $newvalue; }
   return $self->{'showweekdayheaders'};
}

sub cellalignment {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'cellalignment'} = $newvalue; }
   return $self->{'cellalignment'};
}


sub year {
   my $self = shift;
   return $self->{'year'};
}

sub month {
   my $self = shift;
   return $self->{'month'};
}

sub admin {
   my $self = shift;
   return $self->{'admin'};
}

sub dbname {
   my $self = shift;
   return $self->{'dbname'};
}

sub dbuser {
   my $self = shift;
   return $self->{'dbuser'};
}

sub dbpass {
   my $self = shift;
   return $self->{'dbpass'};
}

sub dbcalendar {
   my $self = shift;
   return $self->{'dbcalendar'};
}

sub dbclient {
   my $self = shift;
   return $self->{'dbclient'};
}

sub dbhost {
   my $self = shift;
   return $self->{'dbhost'};
}

sub monthname {
   my $self = shift;
   return $self->{'monthname'};
}


sub header {
   my $self = shift;
   my $newvalue = shift;
   if (defined($newvalue)) { $self->{'header'} = $newvalue; }
   return $self->{'header'};
}

   


__END__;
#################################################################################

=head1 NAME
    HTML::CalendarMonthDB - Perl Module for Generating Persistant HTML
    Calendars

=head1 SYNOPSIS
       use HTML::CalendarMonthDB;
       $cal = new HTML::CalendarMonthDB('year'=>2001,'month'=>2, 'dbname'=>'test', 'dbuser'=>'postgres', 'dbpass'=>'', 'dbcalendar'=>'testcal', 'dbclient'=>'testClient');
       $cal->width('50%'); # non-persistant
       $cal->border(10);   # non-persistant
       $cal->header('Text at the top of the Grid'); # non-persistant
       $cal->bgcolor('pink');
       $cal->editdbcalendar('width'=>'50%', 'border'=>10, 'header'=>'Text at the top of the Grid', 'bgcolor'=>'pink'); # persistant, stored in DB.
       $cal->setcontent(14,"Don't forget to buy flowers"); # non-persistant
       $cal->addcontent(13,"Guess what's tomorrow?"); # non-persistant
       $cal->adddbevent('date'=>'14', 'eventname'=>'Don't forget to buy flowers'); # persistant, stored in db
       $cal->adddbevent('date'=>'13', 'eventname'=>'Guess what's tomorrow?', 'eventdesc'=>'A big surprise is happening tommorrow.  Click here to see more!!', 'eventlink'=>'http://www.surprise.com'); # persistant, stored in db
       print $cal->as_HTML; # print standard 7 column calendar
       print $cal->as_HTML_list; # print HTML calendar as list

=head1 DESCRIPTION
    HTML::CalendarMonthDB is a Perl module for generating, manipulating, and
    printing a HTML calendar grid for a specified month. It is intended as a
    faster and easier-to-use alternative to HTML::CalendarMonth. It is based
    on HTML::CalendarMonthSimple, but can store persistant data into a
    database, as well as adding features like per-event links, descriptions,
    and times.

    This module requires the Date::Calc module, which is available from
    CPAN.

=head1 INTERFACE METHODS

=head2 new(ARGUMENTS)
    Naturally, new() returns a newly constructed calendar object. Recognized
    arguments include 'year' and 'month', to specify which month's calendar
    will be used. If either is omitted, the current value is used. An
    important note is that the month and the year are NOT the standard C or
    Perl -- use a month in the range 1-12 and a real year, e.g. 2001. If
    this is to be a persistant calendar (you wish to store info in a
    database), there are other arguments:

    * 'dbname' (name of database to use, required if you wish to use a
    database)
    * 'dbuser' (database user, default 'nobody')
    * 'dbpass' (database user password, default '')
    * 'dbcalendar' (database calendar name, default '')
    * 'dbclient' (database calendar client name, default '')
    * 'dbhost' (database host name, default '')
       # Examples:
       # Create a calendar for this month.
       $cal = new HTML::CalendarMonthSimple(); # not persistant
       # One for a specific month/year
       $cal = new HTML::CalendarMonthSimple('month'=>2,'year'=>2000); # not persistant
       # One for "the current month" in 1997
       $cal = new HTML::CalendarMonthSimple('year'=>1997); # not persistant
   
       # One for a specific month/year, to use database specified
       $cal = new HTML::CalendarMonthSimple('month'=>2,'year'=>2000,'dbname'=>'test','dbuser'=>postgres,'dbcalendar'=>'testcal','dbclient'=>'testClient');

=head2 deldbevent (EVENTID)
    Permanently deletes record from database associated with the event id
    passed in.

=head2 adddbevent (ARGUMENTS)
    Add persistant event for date (day) specified within current month and
    year. The following are arguments:

    * 'eventname' (name of event)
    * 'eventdesc' (event description, optional)
    * 'eventlink' (event link, optional)
    * 'eventtime' (event time, optional)
=head2 addevent(DATE,STRING)

=head2 getcontent(DATE)
    These methods are used to control the content of date cells within the
    calendar grid. The DATE argument may be a numeric date or it may be a
    string describing a certain occurrence of a weekday, e.g. "3MONDAY" to
    represent "the third Monday of the month being worked with", or it may
    be the plural of a weekday name, e.g. "wednesdays" to represent all
    occurrences of the given weekday. The weekdays are case-insensitive.

       # Examples:
       # The cell for the 15th of the month will now say something.
       $cal->setcontent(15,"An Important Event!");
       # Later down the program, we want the content to be boldfaced.
       $foo = "<b>" . $cal->getcontent(15) . "</b>";
       $cal->setcontent(15,$foo);
       # Or we could get extra spiffy:
       $cal->setcontent(15,"<b>" . $cal->getcontent(15) . "</b>");

       # addcontent() does not clober existing content.
       # Also, if you setcontent() to '', you've deleted the content.
       $cal->setcontent(16,'');
       $cal->addcontent(16,"<p>Hello World</p>");
       $cal->addcontent(16,"<p>Hello Again</p>");
       print $cal->getcontent(16); # Prints 2 sentences

       # Padded and decimal numbers may be used, as well:
       $cal->setcontent(3.14159,'Third of the month');
       $cal->addcontent('00003.0000','Still the third');
       $cal->getcontent('3'); # Gets the 2 sentences

       # The second Sunday of May is some holiday or another...
       $cal->addcontent('2sunday','Some Special Day') if ($cal->month() == 5);
       # So is the third wednesday of this month
       $cal->setcontent('3WedNEsDaY','Third Wednesday!');
       # What's scheduled for the second Friday?
       $cal->getcontent('2FRIDAY');

       # Every Wednesday and Friday of this month...
       $cal->addcontent('wednesdays','Every Wednesday!');
       $cal->getcontent('Fridays');

=head2 as_HTML(ARGUMENTS)

=head2 as_HTML_list(ARGUMENTS)
    These methods return a string containing the HTML calendar for the
    month. as_HTML() returns a standard 7 column table, while as_HTML_list()
    returns a two-column list format calendar.

       # Examples:
       print $cal->as_HTML();
       print $cal->as_HTML_list('editurl'=>'editcal.cgi', 'addurl'=>'addcal.cgi');

    Two optional arguments may be passed, in order to ease the integration
    of adminitrative front-ends: 'editurl' (Will add a [edit] link in each
    day's cell to specified url like so-
    http://editurl?date=month_day_year&calid=calendarid.) 'addurl' (Will add
    a [add] link in each day's cell to specified url like so-
    http://addurl?date=month_day_year&calid=calendarid.)

=head2 year()

=head2 month()

=head2 monthname()
    These methods simply return the year/month of the calendar. monthname()
    returns the text name of the month, e.g. "December".

=head2 getdbcontent()
    Loads calendar event content from database.

=head2 getdbcalendar()
    Loads calendar formatting data from database.

=head2 editdbcalendar(ARGUMENTS)
    Edits calendar formatting attributes stored in database. Takes any or
    all of the following arguments:

    * 'border' (size of calendar border, integer)
    * 'width' (width of calendar, should be in pixels or %)
    * 'bgcolor' (background color of calendar)
    * 'weekdaycolor' (background color of weekday cells)
    * 'weekendcolor' (background color of weekend cells)
    * 'todaycolor' (background color of today's cell)
    * 'bordercolor' (border color of calendar)
    * 'weekdaybordercolor' (border color of weekday cells)
    * 'weekendbordercolor' (border color of weekend cells)
    * 'todaybordercolor' (border color of today's cell)
    * 'contentcolor' (color of cell content)
    * 'weekdaycontentcolor' (color of weekday cell content)
    * 'weekendcontentcolor' (color of weekend cell content)
    * 'todaycontentcolor' (color of today's cell content)
    * 'headercolor' (background color of header cell)
    * 'weekdayheadercolor' (background color of weekday header cell)
    * 'weekendheadercolor' (background color of weekend header cell)
    * 'header' (header text, defaults to 'Month Year' if not specified or
    '')
    * 'cellalignment' (alignment of text within cells, defaults to left,
    other valid values include right, center)

=head2 editdbevent(ARGUMENTS)
    Edits specific event attributes in database. Arguments:

    * 'eventid' (id of specific event, required)
    * 'eventname' (name of event)
    * 'eventdesc' (event description)
    * 'eventlink' (event link)
    * 'eventtime' (event time)

=head2 getdbevent(DATE)
    Takes an argument of the date(day) and returns a hash of event id's and
    their attributes for the specified day in this form:
    hash{eventid}{eventattribute}

    Useful as a function to be used in admin tools.

=head2 border([INTEGER])
    This specifies the value of the border attribute to the <TABLE>
    declaration for the calendar. As such, this controls the thickness of
    the border around the calendar table. The default value is 5.

    If a value is not specified, the current value is returned. If a value
    is specified, the border value is changed and the new value is returned.

=head2 width([INTEGER][%])
    This sets the value of the width attribute to the <TABLE> declaration
    for the calendar. As such, this controls the horizintal width of the
    calendar.

    The width value can be either an integer (e.g. 600) or a percentage
    string (e.g. "80%"). Most web browsers take an integer to be the table's
    width in pixels and a percentage to be the table width relative to the
    screen's width. The default width is "100%".

    If a value is not specified, the current value is returned. If a value
    is specified, the border value is changed and the new value is returned.

       # Examples:
       $cal->width(600);    # absolute pixel width
       $cal->width("100%"); # percentage of screen size

=head2 showdatenumbers([1 or 0])
    If showdatenumbers() is set to 1, then the as_HTML() method will put
    date labels in each cell (e.g. a 1 on the 1st, a 2 on the 2nd, etc.) If
    set to 0, then the date labels will not be printed. The default is 1.

    If no value is specified, the current value is returned.

    The date numbers are shown in boldface, normal size font. If you want to
    change this, consider setting showdatenumbers() to 0 and using
    setcontent()/addcontent() instead.

=head2 showweekdayheaders([1 or 0])
    If showweekdayheaders() is set to 1 (the default) then calendars
    rendered via as_HTML() will display the names of the days of the week.
    If set to 0, the days' names will not be displayed.

    If no value is specified, the current value is returned.

=head2 cellalignment([STRING])
    This sets the value of the align attribute to the <TD> tag for each
    day's cell. This controls how text will be centered/aligned within the
    cells.

    Any value can be used, if you think the web browser will find it
    interesting. Some useful alignments are: left, right, center, top, and
    bottom,

    By default, cells are aligned to the left.

=head2 header([STRING])
    By default, the current month and year are displayed at the top of the
    calendar grid. This is called the "header".

    The header() method allows you to set the header to whatever you like.
    If no new header is specified, the current header is returned.

    If the header is set to an empty string, then no header will be printed
    at all. (No, you won't be stuck with a big empty cell!)

       # Example:
       # Set the month/year header to something snazzy.
       my($y,$m) = ( $cal->year() , $cal->monthname() );
       $cal->header("<center><font size=+2 color=red>$m $y</font></center>\n\n");

=head2 bgcolor([STRING])

=head2 weekdaycolor([STRING])

=head2 weekendcolor([STRING])

=head2 todaycolor([STRING])

=head2 bordercolor([STRING])

=head2 weekdaybordercolor([STRING])

=head2 weekendbordercolor([STRING])

=head2 todaybordercolor([STRING])

=head2 contentcolor([STRING])

=head2 weekdaycontentcolor([STRING])

=head2 weekendcontentcolor([STRING])

=head2 todaycontentcolor([STRING])

=head2 headercolor([STRING])

=head2 weekdayheadercolor([STRING])

=head2 weekendheadercolor([STRING])
    These define the colors of the cells. If a string (which should be
    either a HTML color-code like '#000000' or a color-word like 'yellow')
    is supplied as an argument, then the color is set to that specified.
    Otherwise, the current value is returned. To un-set a value, try
    assigning the null string as a value.

    The bgcolor defines the color of all cells. The weekdaycolor overrides
    the bgcolor for weekdays (Monday through Friday), the weekendcolor
    overrides the bgcolor for weekend days (Saturday and Sunday), and the
    todaycolor overrides the bgcolor for today's date. (Which may not mean a
    lot if you're looking at a calendar other than the current month.)

    The weekdayheadercolor overrides the bgcolor for the weekday headers
    that appear at the top of the calendar if showweekdayheaders() is true,
    and weekendheadercolor does the same thing for the weekend headers. The
    headercolor overrides the bgcolor for the month/year header at the top
    of the calendar.

    The colors of the cell borders may be set: bordercolor determines the
    color of the calendar grid's outside border, and is the default color of
    the inner border for individual cells. The inner bordercolor may be
    overridden for the various types of cells via weekdaybordercolor,
    weekendbordercolor, and todaybordercolor.

    Finally, the color of the cells' contents may be set with contentcolor,
    weekdaycontentcolor, weekendcontentcolor, and todaycontentcolor. The
    contentcolor is the default color of cell content, and the other methods
    override this for the appropriate days' cells.

       # Example:
       $cal->bgcolor('white');                 # Set the default cell color
       $cal->bordercolor('green');             # Set the default border color
       $cal->contentcolor('black');            # Set the default content color
       $cal->headercolor('yellow');            # Set the color of the Month+Year header
       $cal->weekdayheadercolor('orange');     # Set the color of weekdays' headers
       $cal->weekendheadercolor('pink');       # Set the color of weekends' headers
       $cal->weekendcolor('palegreen');        # Override weekends' cell color
       $cal->weekendcontentcolor('blue');      # Override weekends' content color
       $cal->todaycolor('red');                # Override today's cell color
       $cal->todaycontentcolor('yellow');      # Override today's content color
       print $cal->as_HTML;                    # Print a really ugly calendar!

=head1 BUGS, TODO, CHANGES
    No known bugs, though contributions and improvements are welcome, this
    is currently a first run.

=head1 AUTHORS, CREDITS, COPYRIGHTS
    This Perl module is freeware. It may be copied, derived, used, and
    distributed without limitation.

    HTML::CalendarMonthDB is based on HTML::CalendarMonthSimple by Gregor
    Mosheh <stigmata@blackangel.net>. Many additions and modifications were
    performed by Matt Vella (the_mcv@yahoo.com) for About.com/Primedia.

    HTML::CalendarMonth was written and is copyrighted by Matthew P. Sisk
    <sisk@mojotoad.com> and provided inspiration for the module's interface
    and features. Frankly, the major inspiration was the difficulty and
    unnecessary complexity of the interface. (Laziness is a virtue.)

    HTML::CalendarMonthSimple was written by Gregor Mosheh
    <stigmata@blackangel.net> None of Matt Sisk's code appears herein.

    This would have been extremely difficult if not for Date::Calc. Many
    thanks to Steffen Beyer <sb@engelschall.com> for a very fine set of
    date-related functions!

    Danny J. Sohier <danny@gel.ulaval.ca> provided many of the color
    functions.

    Bernie Ledwick <bl@man.fwltech.com> provided base code for the today*()
    functions, and for the handling of cell borders.

