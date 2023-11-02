package EAI::DateUtil 1.5;

use strict; use warnings; use feature 'unicode_strings'; use utf8;
use Exporter qw(import); use Time::Local qw( timelocal_modern timegm_modern ); use Time::localtime; use POSIX qw(mktime);

our @EXPORT = qw(monthsToInt intToMonths addLocaleMonths get_curdate get_curdatetime get_curdate_dot formatDate formatDateFromYYYYMMDD get_curdate_dash get_curdate_gen get_curdate_dash_plus_X_years get_curtime get_curtime_HHMM get_lastdateYYYYMMDD get_lastdateDDMMYYYY is_first_day_of_month is_last_day_of_month get_last_day_of_month weekday is_weekend is_holiday is_easter addCalendar first_week first_weekYYYYMMDD last_week last_weekYYYYMMDD convertDate convertDateFromMMM convertDateToMMM convertToDDMMYYYY addDays addDaysHol addDatePart subtractDays subtractDaysHol convertcomma convertToThousendDecimal get_dateseries parseFromDDMMYYYY parseFromYYYYMMDD convertEpochToYYYYMMDD);

my %monthsToInt = (
	"en" => {"jan" => "01","feb" => "02","mar" => "03","apr" => "04","may" => "05","jun" => "06","jul" => "07","aug" => "08","sep" => "09","oct" => "10","nov" => "11","dec" => "12"},
	"ge" => {"jan" => "01","feb" => "02","mär" => "03","apr" => "04","mai" => "05","jun" => "06","jul" => "07","aug" => "08","sep" => "09","okt" => "10","nov" => "11","dez" => "12"}
);
my %intTomonths = (
	"en" => ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],
	"ge" => ["Jan","Feb","Mär","Apr","Mai","Jun","Jul","Aug","Sep","Okt","Nov","Dez"]
);

sub monthsToInt ($$) {
	my ($m,$locale) = @_;
	return undef if !$m or !$locale;
	if ($intTomonths{lc($locale)} and defined($monthsToInt{lc($locale)}{$m})) {
		return $monthsToInt{lc($locale)}{$m};
	} else {
		return "";
	}
}

sub intToMonths ($$) {
	my ($m,$locale) = @_;
	return undef if !$m or !$locale;
	if ($intTomonths{lc($locale)} and @{$intTomonths{lc($locale)}} >= $m) {
		return $intTomonths{lc($locale)}[$m-1];
	} else {
		return "";
	}
}

sub get_curdate {
	return sprintf("%04d%02d%02d",localtime->year()+ 1900, localtime->mon()+1, localtime->mday());
}

sub get_curdatetime {
	return sprintf("%04d%02d%02d_%02d%02d%02d",localtime->year()+1900,localtime->mon()+1,localtime->mday(),localtime->hour(),localtime->min(),localtime->sec());
}

sub get_curdate_dot {
	return sprintf("%02d.%02d.%04d",localtime->mday(), localtime->mon()+1, localtime->year()+ 1900);
}

sub addLocaleMonths ($$) {
	my ($locale,$monthList) = @_;
	return undef if !$locale or !$monthList;
	$locale = lc($locale);
	if (defined($monthsToInt{$locale})) {
		warn("locale <$locale> already implemented for monthsToInt !");
		return 0;
	}
	if (defined($intTomonths{$locale})) {
		warn("locale <$locale> already implemented for intTomonths !");
		return 0;
	}
	$intTomonths{$locale} = $monthList;
	my $i = 1;
	for (@$monthList) {
		$monthsToInt{$locale}{lc($_)} = sprintf("%02d", $i);
		$i++;
	}
	return 1;
}

sub formatDate ($$$;$) {
	my ($y,$m,$d,$template) = @_;
	return undef if !$y or !$m or !$d;
	$template = "YMD" if !$template;
	my ($locale) = $template =~ /\[(.*?)\]$/;
	my $result = $template;
	$result =~ s/\[$locale\]// if $locale;
	$y = sprintf("%04d", $y);
	$m = sprintf("%02d", $m);
	$d = sprintf("%02d", $d);
	if ($result =~ /MMM/i) {
		$locale = "ge" if $result =~ /mmm/ and !$locale;
		$locale = "en" if !$locale;
		my $mmm = intToMonths($m,$locale);
		$result =~ s/MMM/$mmm/i;
	} else {
		$result =~ s/M/$m/;
	}
	$result =~ s/Y/$y/;
	$result =~ s/D/$d/;
	return $result;
}

sub formatDateFromYYYYMMDD ($;$) {
	return undef if !$_[0];
	my ($year,$mon,$day) = $_[0] =~ /(.{4})(..)(..)/;
	return undef if !$year or !$mon or !$day;
	my ($template) = $_[1] if $_[1];
	return formatDate($year,$mon,$day,$template);
}

sub get_curdate_gen (;$) {
	my ($template) = @_;
	return formatDate(localtime->year()+ 1900,localtime->mon()+1,localtime->mday(),$template);
}

sub get_curdate_dash {
	return sprintf("%02d-%02d-%04d",localtime->mday(), localtime->mon()+1, localtime->year()+ 1900);
}

sub get_curdate_dash_plus_X_years ($;$$) {
	my ($y) = $_[0];
	return undef if !$y;
	my ($year,$mon,$day) = $_[1] =~ /(.{4})(..)(..)/ if $_[1];
	my $daysToSubtract = $_[2] if $_[2];
	if ($year) {
		my $dateval;
		if ($daysToSubtract) {
			$dateval = localtime(timegm_modern(0,0,12,$day,$mon-1,$year)-$daysToSubtract*24*60*60);
		} else {
			$dateval = localtime(timegm_modern(0,0,12,$day,$mon-1,$year));
		}
		return sprintf("%02d-%02d-%04d",$dateval->mday(), $dateval->mon()+1, $dateval->year()+ 1900 + $y);
	} else {
		return sprintf("%02d-%02d-%04d",localtime->mday(), localtime->mon()+1, localtime->year()+ 1900 + $y);
	}
}

sub get_curtime (;$$) {
	my $format = $_[0];
	my $secondsToAdd = $_[1];
	$format = "%02d:%02d:%02d" if !$format;
	if ($secondsToAdd) {
		my $dateval = localtime(time()+$secondsToAdd);
		return sprintf($format,$dateval->hour(),$dateval->min(),$dateval->sec());
	} else {
		return sprintf($format,localtime->hour(),localtime->min(),localtime->sec());
	}
}

sub get_curtime_HHMM {
	return sprintf("%02d%02d",localtime->hour(),localtime->min());
}

sub is_first_day_of_month ($) {
	return undef if !$_[0];
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	((gmtime(timegm_modern(0,0,12,$d,$m-1,$y)-24*60*60))[4] != $m-1 ? 1 : 0);
}

sub is_last_day_of_month ($;$) {
	return undef if !$_[0];
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	my $cal = $_[1];
	# for respecting holidays add 1 day and compare month
	if ($cal) {
		my $shiftedDate = addDaysHol($_[0],1,"YMD",$cal);
		my ($ys,$ms,$ds) = $shiftedDate =~ /(.{4})(..)(..)/;
		($ms ne $m ? 1 : 0); 
	} else {
		((gmtime(timegm_modern(0,0,12,$d,$m-1,$y) + 24*60*60))[4] != $m-1 ? 1 : 0);
	}
}
sub get_last_day_of_month ($) {
	return undef if !$_[0];
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	# first of following month minus 1 day is always last of current month, timegm_modern expects 0 based month, $m is the following month for timegm_modern therefore
	if ($m == 12) {
		# for December -> January next year
		$m = 0; # month 0 based
		$y++;
	}
	my $mon = (gmtime(timegm_modern(0,0,12,1,$m,$y) - 24*60*60))[4]+1;
	my $day = (gmtime(timegm_modern(0,0,12,1,$m,$y) - 24*60*60))[3];
	$y-- if $m == 0; # for December -> reset year again
	return sprintf("%04d%02d%02d",$y, $mon, $day);
}

sub weekday ($) {
	return undef if !$_[0];
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	(gmtime(timegm_modern(0,0,12,$d,$m-1,$y)))[6]+1;
}

sub is_weekend ($) {
	return undef if !$_[0];
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	(gmtime(timegm_modern(0,0,12,$d,$m-1,$y)))[6] =~ /(0|6)/;
}
# makeMD: argument in timegm_modern form (datetime), returns date in format DDMM (for holiday calculation)
sub makeMD ($) {
	return undef if !$_[0];
	sprintf("%02d%02d", (gmtime($_[0]))[3],(gmtime($_[0]))[4] + 1);
}

# British specialties
sub UKspecial {
	return undef if !$_[0];
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	return 1 if (first_week($d,$m,$y,1,5) || last_week($d,$m,$y,1,5) || last_week($d,$m,$y,1,8));
	return 0;
}

# fixed holidays
my %fixedHol = ("BS"=>{"0101"=>1,"0601"=>1,"0105"=>1,"1508"=>1,"2610"=>1,"0111"=>1,"0812"=>1,"2412"=>1,"2512"=>1,"2612"=>1},
				"BF"=>{"0101"=>1,"0601"=>1,"0105"=>1,"1508"=>1,"2610"=>1,"0111"=>1,"0812"=>1,"2412"=>1,"2512"=>1,"2612"=>1},
				"AT"=>{"0101"=>1,"0601"=>1,"0105"=>1,"1508"=>1,"2610"=>1,"0111"=>1,"0812"=>1,"2512"=>1,"2612"=>1},
				"TG"=>{"0101"=>1,"0105"=>1,"2512"=>1,"2612"=>1},
				"UK"=>{"0101"=>1,"2512"=>1,"2612"=>1}
				);

# easter holidays
my %easterHol = ("BS"=>{"EM"=>1,"AS"=>1,"WM"=>1,"CC"=>1,"GF"=>1},
				 "BF"=>{"EM"=>1,"AS"=>1,"WM"=>1,"CC"=>1},
				 "AT"=>{"EM"=>1,"AS"=>1,"WM"=>1,"CC"=>1},
				 "TG"=>{"EM"=>1,"GF"=>1},
				 "UK"=>{"EM"=>1,"GF"=>1}
				);

# reference to functions for special holiday calculations
my %specialHol = ("UK" => \&UKspecial);

# adds calendar to DateUtil, first arg name of $cal, second arg fixed holidays hash, third easter holidays hash and fourth special function for additional calculations
sub addCalendar ($$$$) {
	my ($cal,$fixHol,$eastHol,$specialHolSub) = @_;
	return undef if !$cal or !$fixHol or !$eastHol or !$specialHolSub;
	if (defined($fixedHol{$cal})) {
		warn("calender <$cal> already implemented for fixed holidays !");
		return 0;
	}
	if (defined($easterHol{$cal})) {
		warn("calender <$cal> already implemented for easter holidays !");
		return 0;
	}
	if (defined($specialHol{$cal})) {
		warn("calender <$cal> already implemented for additional calculations !");
		return 0;
	}
	$fixedHol{$cal} = ($fixHol ? $fixHol : "");
	$easterHol{$cal} = ($eastHol ? $eastHol : "");
	$specialHol{$cal} = ($specialHolSub ? $specialHolSub : "");
	return 1;
}

# check whether second arg is easter in passed calendar (first arg).
# requires entry of calendar in %easterHol hash: "$Cal" => {"GF"=>1,"EM"=>1,"ES"=>1,"AS"=>1,"WM"=>1,"CC"=>1}
sub is_easter ($$) {
	my ($cal) = $_[0];
	return undef if !$cal or !$_[1];
	my ($y,$m,$d) = $_[1] =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	# first find easter sunday using year
	my $D = (((255 - 11 * ($y % 19)) - 21) % 30) + 21;
	my $easter = timegm_modern(0,0,12,1,2,$y) + ($D + ($D > 48 ? 1 : 0) + 6 - (($y + int($y / 4) + $D + ($D > 48 ? 1 : 0) + 1) % 7))*86400;
	return 1 if makeMD($easter) eq $d.$m and $easterHol{$cal}->{"EH"}; # easter sunday
	# then the rest
	return 1 if makeMD($easter-2*86400) eq $d.$m and $easterHol{$cal}->{"GF"}; # good friday
	return 1 if makeMD($easter+1*86400) eq $d.$m and $easterHol{$cal}->{"EM"}; # easter monday
	return 1 if makeMD($easter+39*86400) eq $d.$m and $easterHol{$cal}->{"AS"}; # ascension day
	return 1 if makeMD($easter+50*86400) eq $d.$m and $easterHol{$cal}->{"WM"}; # whitmonday
	return 1 if makeMD($easter+60*86400) eq $d.$m and $easterHol{$cal}->{"CC"}; # corpus christi day
	return 0;
}

# check whether second arg is holiday in passed calendar (first arg)
sub is_holiday ($$) {
	my ($cal) = $_[0];
	return undef if !$cal or $cal eq "WE" or !$_[1]; # weekends are checked with "is_weekend", so no holiday passed here! Same for empty dates passed
	my ($y,$m,$d) = $_[1] =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	return 1 if $fixedHol{$cal}->{$d.$m};
	return 1 if is_easter($cal,$_[1]);
	return 1 if $specialHol{$cal} and $specialHol{$cal}->($_[1]);
	unless ($fixedHol{$cal} or $easterHol{$cal} or $specialHol{$cal}) {
		warn("calender <$cal> neither implemented in \$fixedHol{$cal} nor \$easterHol{$cal} nor \$specialHol{$cal} !");
		return 0;
	}
	return 0;
}

sub first_week ($$$$;$) {
	my ($d,$m,$y,$day,$month) = @_;
	return undef if !$y or !$m or !$d or !defined($day);
	$month = $m if !$month;
	unless ((0 <= $day) && ( $day <= 6)) {
		warn("day <$day> is out of range 0 - 6  (sunday==0)");
		return 0;
	}
	my $date = localtime(timelocal_modern(0,0,12,$d,$m-1,$y));
	return 0 unless $m == $month; # return unless the month matches
	return 0 if $d > 7; # can't be the first week of the month if day is after the 7th
	return 0 unless $date->wday() == $day; # return unless the (week)day matches
	return 0 unless (localtime(timelocal_modern(0,0,12,$d,$m-1,$y)-7*24*60*60))->mon() != $m-1; # return unless 1 week earlier we're in a different month
	return 1;
}

sub first_weekYYYYMMDD ($$;$) {
	my ($date,$day,$month) = @_;
	return undef if !$date or !defined($day);
	my ($y,$m,$d) = $date =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	$month = $m if !$month;
	return first_week ($d,$m,$y,$day,$month);
}

sub last_week ($$$$;$) {
	my ($d,$m,$y,$day,$month) = @_;
	return undef if !$y or !$m or !$d or !defined($day);
	$month = $m if !$month;
	unless ((0 <= $day) && ( $day <= 6)) {
		warn("day <$day> is out of range 0 - 6  (sunday==0)");
		return 0;
	}
	my $date = localtime(timelocal_modern(0,0,12,$d,$m-1,$y));
	return 0 unless $m == $month; # return unless the month matches
	return 0 unless $date->wday() == $day; # return unless the (week)day matches
	return 0 unless (localtime(timelocal_modern(0,0,12,$d,$m-1,$y)+7*24*60*60))->mon() != $m-1; # return unless 1 week later we're in a different month
	return 1;
}

sub last_weekYYYYMMDD ($$;$) {
	my ($date,$day,$month) = @_;
	return undef if !$date or !defined($day);
	my ($y,$m,$d) = $date =~ /(.{4})(..)(..)/;
	$month = $m if !$month;
	return last_week ($d,$m,$y,$day,$month);
}

sub convertDate ($) {
	return undef if !$_[0];
	my ($y,$m,$d) = ($_[0] =~ /(\d{4})[.\/](\d\d)[.\/](\d\d)/);
	return sprintf("%04d%02d%02d",$y, $m, $d);
}

sub convertDateFromMMM ($$$$;$) {
	my ($inDate,$day,$mon,$year,$locale) = @_;
	return undef if !$inDate or !$day or !$mon or !$year;
	$locale = "en" if !$locale;
	my ($d,$m,$y) = ($inDate =~ /(\d{2})-(\w{3})-(\d{4})/);
	$$day = $d;
	$$mon = $monthsToInt{lc($locale)}{lc($m)};
	$$year = $y;
	return sprintf("%02d.%02d.%04d",$d, $$mon, $y);
}

sub convertDateToMMM ($$$;$) {
	my ($day,$mon,$year,$locale) = @_;
	return undef if !$day or !$mon or !$year;
	$locale = "en" if !$locale;
	return sprintf("%02d-%03s-%04d",$day, $intTomonths{lc($locale)}[$mon-1], $year);
}

sub convertToDDMMYYYY ($) {
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	return "$d.$m.$y";
}

sub addDays ($$$$;$) {
	my ($day,$mon,$year,$dayDiff,$locale) = @_;
	return undef if !$day or !$mon or !$year or !$dayDiff;
	$locale = "en" if !$locale;
	my $curDateEpoch = timelocal_modern(0,0,0,$$day,$$mon-1,$$year);
	my $diffDate = localtime($curDateEpoch + $dayDiff * 60 * 60 * 25);
	# dereference, so the passed variable is changed
	$$year = $diffDate->year+1900;
	$$mon = $diffDate->mon+1;
	$$day = $diffDate->mday;
	return sprintf("%02d-%03s-%04d",$$day, $intTomonths{lc($locale)}[$$mon-1], $$year);
}

sub subtractDays ($$) {
	my ($date,$days) = @_;
	return undef if !$date;
	my ($y,$m,$d) = $date =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	my $theDate = localtime(timelocal_modern(0,0,12,$d,$m-1,$y) - $days*24*60*60);
	return sprintf("%04d%02d%02d",$theDate->year()+ 1900, $theDate->mon()+1, $theDate->mday());
}

sub addDaysHol ($$;$$) {
	my ($date, $days, $template, $cal) = @_;
	$cal="NO" if !$cal;
	return undef if !$date;
	my ($y,$m,$d) = $date =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	# first add days
	my $refdate = localtime(timelocal_modern(0,0,12,$d,$m-1,$y) + $days*24*60*60);
	# then add further days as long weekend or holidays
	if ($cal ne "NO") {
		while ($refdate->wday() == 0 || $refdate->wday() == 6 || is_holiday($cal,sprintf("%04d%02d%02d", $refdate->year()+1900, $refdate->mon()+1, $refdate->mday()))) {
			$refdate = localtime(timelocal_modern(0,0,12,$refdate->mday(),$refdate->mon(),$refdate->year()+1900) + 24*60*60);
		}
	}
	return formatDate($refdate->year()+1900, $refdate->mon()+1, $refdate->mday(),$template);
}

sub subtractDaysHol ($$;$$) {
	my ($date,$days,$template,$cal) = @_;
	$cal="NO" if !$cal;
	return undef if !$date;
	my ($y,$m,$d) = $date =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	# first subtract days
	my $refdate = localtime(timelocal_modern(0,0,12,$d,$m-1,$y) - $days*24*60*60);
	# then subtract further days as long weekend or holidays
	if ($cal ne "NO") {
		while ($refdate->wday() == 0 || $refdate->wday() == 6 || is_holiday($cal, sprintf("%04d%02d%02d", $refdate->year()+1900, $refdate->mon()+1, $refdate->mday()))) {
			$refdate = localtime(timelocal_modern(0,0,12,$refdate->mday(),$refdate->mon(),$refdate->year()+1900) - 24*60*60);
		}
	}
	return formatDate($refdate->year()+1900, $refdate->mon()+1, $refdate->mday(),$template);
}

sub addDatePart {
	my ($date, $count, $datepart, $template) = @_;
	return if !$date;
	my %datepart = (d=>3,m=>4,y=>5,day=>3,mon=>4,year=>5,D=>3,M=>4,Y=>5,month=>4);
	my ($y,$m,$d) = $date =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	my $parts = localtime(timelocal_modern(0,0,12,$d,$m-1,$y));
	@$parts[$datepart{$datepart}] += $count if $datepart{$datepart};
	my $refdate =localtime(mktime @$parts);
	return formatDate($refdate->year()+1900, $refdate->mon()+1, $refdate->mday(),$template);
}

sub get_lastdateYYYYMMDD {
	my $refdate = time - 24*60*60;
	$refdate = time - 3*24*60*60 if (localtime->wday() == 1);
	return sprintf("%04d%02d%02d",localtime($refdate)->year() + 1900, localtime($refdate)->mon()+1, localtime($refdate)->mday());
}

sub get_lastdateDDMMYYYY {
	my $refdate = time - 24*60*60;
	$refdate = time - 3*24*60*60 if (localtime->wday() == 1);
	return sprintf("%02d.%02d.%04d",localtime($refdate)->mday(), localtime($refdate)->mon()+1, localtime($refdate)->year() + 1900);
}

sub convertcomma ($;$) {
	my ($number, $divideBy) = @_;
	return undef if !defined($number);
	$number = $number / $divideBy if $divideBy;
	$number = "$number";
	$number =~ s/\./,/;
	return $number;
}

sub convertToThousendDecimal ($;$) {
	my ($value,$ignoreDecimal) = @_;
	return undef if !defined($value);
	my ($negSign) = ($value =~ /(-).*?/);
	$negSign = "" if !defined($negSign);
	$value =~ s/-//;
	# get digits before decimal point and after (optionally divided by thousand separator ".")
	my ($intplaces,$decplaces) = $value =~ /(\d*)\.(\d*)/ if $value =~ /\./;
	if ($value !~ /\./) {
		$intplaces = $value;
		$decplaces = "0";
	}
	# converts digits before decimal point to thousand separated number
	my $quantity = reverse join '.', unpack '(A3)*', reverse $intplaces;
	$quantity = $negSign.$quantity.($ignoreDecimal ? "" : ",".$decplaces);
	return $quantity;
}

sub get_dateseries ($$;$) {
	my ($fromDate,$toDate,$cal) = @_;
	return undef if !$fromDate or !$toDate;
	my ($yf,$mf,$df) = $fromDate =~ /(.{4})(..)(..)/;
	my ($yt,$mt,$dt) = $toDate =~ /(.{4})(..)(..)/;
	return undef if !$yf or !$mf or !$df or !$yt or !$mt or !$dt;
	my $from = timelocal_modern(0,0,12,$df,$mf-1,$yf);
	my $to = timelocal_modern(0,0,12,$dt,$mt-1,$yt);
	my @dateseries;
	for ($_= $from; $_<= $to; $_ += 24*60*60) {
		my $date = localtime($_);
		my $datestr = sprintf("%04d%02d%02d",$date->year()+1900,$date->mon()+1,$date->mday());
		if ($cal) {
			push @dateseries, $datestr if $date->wday() != 0 && $date->wday() != 6 && !is_holiday($cal,$datestr);
		} else {
			push @dateseries, $datestr;
		}
	}
	return @dateseries;
}

sub parseFromDDMMYYYY ($) {
	my ($dateStr) = @_;
	return undef if !$dateStr;
	my ($df,$mf,$yf) = $dateStr =~ /(..*)\.(..*)\.(.{4})/;
	return undef if !$yf or !$mf or !$df;
	return undef if !($yf >= 1900) or !($mf >= 1 && $mf <= 12) or !($df >= 1 && $df <= 31);
	return timelocal_modern(0,0,0,$df,$mf-1,$yf);
}

sub parseFromYYYYMMDD ($) {
	my ($dateStr) = @_;
	return undef if !$dateStr;
	my ($yf,$mf,$df) = $dateStr =~ /(.{4})(..)(..)/;
	return undef if !$yf or !$mf or !$df;
	return undef if !$dateStr or !($yf >= 1900) or !($mf >= 1 && $mf <= 12) or !($df >= 1 && $df <= 31);
	return timelocal_modern(0,0,0,$df,$mf-1,$yf);
}

sub convertEpochToYYYYMMDD ($) {
	my ($arg) = @_;
	if (ref($arg) eq 'Time::Piece') {
		return sprintf("%04d%02d%02d",$arg->year(),$arg->mon(),$arg->mday());
	} elsif($arg) {
		my $date = localtime($arg);
		return sprintf("%04d%02d%02d",$date->year()+1900,$date->mon()+1,$date->mday());
	}

}
1;
__END__

=encoding utf8

=head1 NAME

EAI::DateUtil - Date and Time helper functions for L<EAI::Wrap>

=head1 SYNOPSIS

 monthsToInt ($mmm, $locale)
 intToMonths ($m, $locale)
 addLocaleMonths ($locale, $monthsArray)
 get_curdate ()
 get_curdatetime ()
 get_curdate_dot ()
 formatDate ($y, $m, $d, [$template])
 formatDateFromYYYYMMDD ($date, [$template])
 get_curdate_gen ([$template])
 get_curdate_dash ()
 get_curdate_dash_plus_X_years ($years)
 get_curtime ([$format, $secondsToAdd])
 get_curtime_HHMM ()
 is_first_day_of_month ($date YYYYMMDD)
 is_last_day_of_month ($date YYYYMMDD, [$cal])
 get_last_day_of_month ($date YYYYMMDD)
 weekday ($date YYYYMMDD)
 is_weekend ($date YYYYMMDD)
 is_holiday ($cal, $date YYYYMMDD)
 is_easter ($cal, $date YYYYMMDD)
 addCalendar ($cal, $fixedHol hash, $easterHol .. hash, $specialFunction)
 first_week ($d,$m,$y,$day,[$month])
 first_weekYYYYMMDD ($date,$day,[$month])
 last_week ($d,$m,$y,$day,[$month])
 last_weekYYYYMMDD ($date,$day,[$month])
 convertDate ($date YYYY.MM.DD or YYYY/MM/DD)
 convertDateFromMMM ($inDate dd-mmm-yyyy, out $day, out $mon, out $year, [$locale])
 convertDateToMMM ($day, $mon, $year, [$locale])
 convertToDDMMYYYY ($date YYYYMMDD)
 addDays ($day, $mon, $year, $dayDiff, [$locale])
 subtractDays ($date, $days)
 addDaysHol ($date, $days, [$template, $cal])
 subtractDaysHol ($date, $days, [$template, $cal])
 addDatePart ($date, $count, $datepart, [$template])
 get_lastdateYYYYMMDD ()
 get_lastdateDDMMYYYY ()
 convertcomma ($number, $divideBy)
 convertToThousendDecimal($value, $ignoreDecimal)
 get_dateseries ($fromDate, $toDate, $cal)
 parseFromDDMMYYYY ($dateStr)
 parseFromYYYYMMDD ($dateStr)
 convertEpochToYYYYMMDD ($epoch)

=head1 DESCRIPTION

EAI::DateUtil contains all date/time related API-calls.

=head2 API

=over

=item monthsToInt ($$)

convert from english/german/custom locale short months -> numbers, monthsToInt("Oct","en") equals 10, monthsToInt("mär","ge") equals 3. months and locale are case insensitive.

 $mon ..  month in textual format (as defined in locale)
 $locale .. locale as defined in monthsToInt (builtin "en" and "ge", can be added with addLocaleMonths)

=item intToMonths ($$)

convert from int to english/german/custom locale months -> numbers, intToMonths(10,"en") equals "Oct", intToMonths(3,"ge") equals "Mär". locale is case insensitive, month is returned with first letter uppercase resp. as it was added (see below).

 $mon ..  month in textual format (as defined in locale)
 $locale .. locale as defined in monthsToInt (builtin "en" and "ge", can be added with addLocaleMonths)

=item addLocaleMonths ($$)

adds custom locale $locale with ref to array $monthsArray to above conversion functions. locale is case insensitive.

 $locale .. locale to be defined
 $months .. ref to array of months in textual format

Example:

 addLocaleMonths("fr",["Jan","Fév","Mars","Mai","Juin","Juil","Août","Sept","Oct","Nov","Déc"]);

=item get_curdate

gets current date in format YYYYMMDD

=item get_curdatetime

gets current datetime in format YYYYMMDD_HHMMSS

=item get_curdate_dot

gets current date in format DD.MM.YYYY

=item formatDate ($$$;$)

formats passed date (given in arguments $y,$m,$d) into format as defined in $template

 $y .. year part
 $m .. month part
 $d .. day part
 $template .. optional, date template with D for day, M for month and Y for year (e.g. D.M.Y for 01.02.2016),
              D and M is always 2 digit, Y always 4 digit; if empty/nonexistent defaults to "YMD"
              special formats are MMM und mmm als monthpart, here three letter month abbreviations in english (MMM) or german (mmm) are returned as month
              additionally a locale can be passed in brackets with MMM and mmm, resulting in conversion to locale dependent months.
              e.g. formatDate(2002,6,1,"Y-MMM-D[fr]") would yield 2002-Juin-01 for the addLocaleMonths given above.

=item formatDateFromYYYYMMDD ($;$)

returns passed date (argument $date) formatted as defined in $template

 $date .. date in format YYYYMMDD
 $template .. same as in formatDate above

=item get_curdate_gen (;$)

returns current date in format as defined in $template

 $template .. same as in formatDate above

=item get_curdate_dash

returns current date in format DD-MM-YYYY

=item get_curdate_dash_plus_X_years ($;$$)

 $y .. years to be added to the current or given date
 $date .. optional date to which X years should be added (if not given, then current date is taken instead).
 $daysToSubtract .. optional days that should be subtracted from above result

returns (current or given) date + X years in format DD-MM-YYYY

=item get_curtime (;$$)

returns current time in format HH:MM:SS + optional $secondsToAdd (or as given in formatstring $format, however ordering of format is always hour, minute and second)

 $format .. optional sprintf format string (e.g. %02d:%02d:%02d) for hour, minute and second. If less than three tags are passed then a warning is "Redundant argument in sprintf at ..." is thrown here.
 $secondsToAdd .. optional seconds to add to current time before returning

=item get_curtime_HHMM

returns current time in format HHMM

=item is_first_day_of_month ($)

returns 1 if first day of months, 0 else

 $date .. date in format YYYYMMDD

=item is_last_day_of_month ($;$)

returns 1 if last day of month, 0 else

 $date .. date in format YYYYMMDD
 $cal .. optional, calendar for holidays used to get the last of month

=item get_last_day_of_month ($)

returns last day of month of passed date

 $date .. date in format YYYYMMDD

=item weekday ($)

returns 1..sunday to 7..saturday

 $date .. date in format YYYYMMDD

=item is_weekend ($)

returns 1 if saturday or sunday

 $date .. date in format YYYYMMDD

=item is_holiday ($$)

returns 1 if weekend or holiday

 $cal .. holiday calendar; currently supported: AT (Austria), TG (Target), UK (see is_holiday) and WE (for only weekends).
         throws warning if calendar not supported (fixed lookups or additionally added). To add a calendar use addCalendar.
 $date .. date in format YYYYMMDD

=item is_easter ($$)

returns 1 if date is an easter holiday for that calendar

 $cal .. holiday calendar;
 $date .. date in format YYYYMMDD

=item addCalendar ($$$$)

add an additional calendar for calendar holiday dependent calculations

 $cal .. name of holiday calendar to be added, warns if already existing (builtin)
 $fixedHol .. hash of fixed holiday dates for that calendar (e.g. {"0105"=>1,"2512"=>1} for may day and christmas day)
 $easterHol .. hash of easter holidays for that calendar (possible: {"GF"=>1,"EM"=>1,"ES"=>1,"AS"=>1,"WM"=>1,"CC"=>1}) = good friday,easter monday, easter sunday, ascension day, whitmonday, corpus christi day
 $specialFunction .. pass ref to sub used for additional calculations; this sub should receive a date (YYYYMMDD) and return 1 for holiday, 0 otherwise.

Example:

 sub testCalSpecial {
   my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
   return 1 if $y eq "2002" and $m eq "09" and $d eq "08";
   return 0;
 }
 addCalendar("TC",{"0101"=>1,"0105"=>1,"2512"=>1,"2612"=>1},{"EM"=>1,"GF"=>1},\&testCalSpecial);

=item first_week ($$$$;$)

returns 1 if given date ($d,$m,$y) is the first given weekday ($day: 0 - 6, sunday==0) in given month ($month),
 if $month is not passed, then it is taken from passed date.

 $d .. day part
 $m .. month part
 $y .. year part
 $day .. given weekday
 $month .. optional, given month

=item first_weekYYYYMMDD ($$;$)

returns 1 if given date ($date in Format YYYYMMDD) is the first given weekday ($day: 0 - 6, sunday==0) in given month ($month),
 if $month is not passed, then it is taken from passed date.

 $date .. given date
 $day .. given weekday
 $month .. optional, given month

=item last_week ($$$$;$)

returns 1 if given date ($d,$m,$y) is the last given weekday ($day: 0 - 6, sunday==0) in given month ($month),
 if $month is not passed, then it is taken from passed date.

 $d .. day part
 $m .. month part
 $y .. year part
 $day .. given weekday
 $month .. optional, given month

=item last_weekYYYYMMDD ($$;$)

returns 1 if given date ($date in Format YYYYMMDD) is the last given weekday ($day: 0 - 6, sunday==0) in given month ($month),
 if $month is not passed, then it is taken from passed date.
 
 $date .. given date
 $day .. given weekday
 $month .. optional, given month

=item convertDate ($)

converts given date to format YYYYMMDD

 $date .. date in format YYYY.MM.DD or YYYY/MM/DD

=item convertDateFromMMM ($$$$;$)

converts date from format dd-mmm-yyyy (mmm as defined in $locale, defaults to "en"glish), returns date in format DD.MM.YYYY ($day, $mon, $year are returned by ref as well)

 $inDate .. date to be converted
 $day .. ref for day part
 $mon .. ref for month part
 $year ..  ref for year part
 $locale .. optional locale as defined in monthsToInt (builtin "en" and "ge", can be added with addLocaleMonths)

=item convertDateToMMM ($$$;$)

converts date into format dd-mmm-yyyy (mmm as defined in $locale, defaults to "en"glish) from ($day, $mon, $year)

 $day .. day part
 $mon .. month part
 $year .. year part
 $locale .. optional locale as defined in monthsToInt (builtin "en" and "ge", can be added with addLocaleMonths)

=item convertToDDMMYYYY ($)

converts date into $datestring (dd.mm.yyyy) from format YYYYMMDD

 $date .. date in format YYYYMMDD

=item addDays ($$$$;$)

adds $dayDiff to date ($day, $mon, $year) and returns in format dd-mmm-yyyy (mmm as defined in $locale, defaults to "en"glish),
                arguments $day, $mon, $year are returned by ref as well if not passed as literal

 $day .. day part
 $mon .. month part
 $year .. year part
 $dayDiff .. days to be added
 $locale .. optional locale as defined in monthsToInt (builtin "en" and "ge", can be added with addLocaleMonths)

=item subtractDays ($$)

subtracts $days actual calendar days from $date

 $date .. date in format YYYYMMDD
 $days .. calendar days to subtract

=item addDaysHol ($$;$$)

adds $days days to $date and regards weekends and holidays of passed calendar

 $date .. date in format YYYYMMDD
 $days .. calendar days to add
 $template .. as in formatDate
 $cal .. holiday calendar; currently supported: NO (no holidays = default if not given), rest as in is_holiday

=item subtractDaysHol ($$;$$)

subtracts $days days from $date and regards weekends and holidays of passed calendar

 $date .. date in format YYYYMMDD
 $days .. calendar days to subtract
 $template .. as in formatDate
 $cal .. holiday calendar; currently supported: NO (no holidays  = default if not given), rest as in is_holiday

=item addDatePart ($$$;$)

adds $count dateparts to $date. when adding to months ends (>28 in february, >29 or >30 else), if the month end is not available in the target month, then date is moved into following month

 $date .. date in format YYYYMMDD
 $count .. count of dateparts to add
 $datepart .. can be "d" or "day" for days, "m"/"mon"/"month" for months and "y" or "year" for years
 $template .. as in formatDate

=item get_lastdateYYYYMMDD

returns the last business day (only weekends, no holiday here !) in format YYYYMMDD

=item get_lastdateDDMMYYYY

returns the last business day (only weekends, no holiday here !) in format DDMMYYYY

=item convertcomma ($$)

converts decimal point in $number to comma, also dividing by $divideBy before if $divideBy is set

 $number ..  number to be converted
 $divideBy .. number to be divided by

=item convertToThousendDecimal ($$)

converts $value into thousand separated decimal (german format) ignoring decimal places if wanted
 
 $value .. number to be converted
 $ignoreDecimal .. return number without decimal places (truncate)

=item get_dateseries ($$$)

returns date values (format YYYYMMMDD) starting at $fromDate until $toDate, if a holiday calendar is set in $cal (optional), these holidays (incl. weekends) are regarded as well.
 
 $fromDate .. start date
 $toDate .. end date
 $cal .. holiday calendar

=item parseFromDDMMYYYY ($)

returns time epoch from given datestring (dd.mm.yyyy)

 $dateStr .. datestring

=item parseFromYYYYMMDD ($)

returns time epoch from given datestring (yyyymmdd)

 $dateStr .. datestring

=item convertEpochToYYYYMMDD ($)

returns datestring (yyyymmdd) from epoch/Time::piece

 $arg .. date either as epoch (seconds since 1.1.1970) or as Time::piece object

=back

=head1 COPYRIGHT

Copyright (c) 2023 Roland Kapl

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut