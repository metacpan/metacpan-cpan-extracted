package EAI::DateUtil 0.3;

use strict;
use Time::Local; use Time::localtime; use Exporter; use POSIX qw(mktime);

our @ISA = qw(Exporter);
our @EXPORT = qw(%months %monate get_curdate get_curdatetime get_curdate_dot formatDate formatDateFromYYYYMMDD get_curdate_dash get_curdate_gen get_curdate_dash_plus_X_years get_curtime get_curtime_HHMM get_lastdateYYYYMMDD get_lastdateDDMMYYYY is_first_day_of_month is_last_day_of_month get_last_day_of_month weekday is_weekend is_holiday first_week first_weekYYYYMMDD last_week last_weekYYYYMMDD convertDate convertDateFromMMM convertDateToMMM convertToDDMMYYYY addDays addDaysHol addDatePart subtractDays subtractDaysHol convertcomma convertToThousendDecimal get_dateseries parseFromDDMMYYYY parseFromYYYYMMDD convertEpochToYYYYMMDD);

our %months = ("Jan" => "01","Feb" => "02","Mar" => "03","Apr" => "04","May" => "05","Jun" => "06","Jul" => "07","Aug" => "08","Sep" => "09","Oct" => "10","Nov" => "11","Dec" => "12");
our %monate = ("Jan" => "01","Feb" => "02","Mär" => "03","Apr" => "04","Mai" => "05","Jun" => "06","Jul" => "07","Aug" => "08","Sep" => "09","Okt" => "10","Nov" => "11","Dez" => "12");

sub get_curdate {
	return sprintf("%04d%02d%02d",localtime->year()+ 1900, localtime->mon()+1, localtime->mday());
}

sub get_curdatetime {
	return sprintf("%04d%02d%02d_%02d%02d%02d",localtime->year()+1900,localtime->mon()+1,localtime->mday(),localtime->hour(),localtime->min(),localtime->sec());
}

sub get_curdate_dot {
	return sprintf("%02d.%02d.%04d",localtime->mday(), localtime->mon()+1, localtime->year()+ 1900);
}

sub formatDate ($$$;$) {
	my ($y,$m,$d,$template) = @_;
	$template = "YMD" if !$template;
	my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
	my @monate = ('Jän', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez');
	my $result = $template;
	$y = sprintf("%04d", $y);
	$m = sprintf("%02d", $m);
	$d = sprintf("%02d", $d);
	if ($result =~ /MMM/i) {
		my $mmm;
		$mmm = $months[$m-1] if $result =~ /MMM/;
		$mmm = $monate[$m-1] if $result =~ /mmm/;
		$result =~ s/MMM/$mmm/i;
	} else {
		$result =~ s/M/$m/;
	}
	$result =~ s/Y/$y/;
	$result =~ s/D/$d/;
	return $result;
}

sub formatDateFromYYYYMMDD ($;$) {
	my ($year,$mon,$day) = $_[0] =~ /(.{4})(..)(..)/;
	my ($template) = $_[1];
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
	my ($year,$mon,$day) = $_[1] =~ /(.{4})(..)(..)/;
	my $daysToSubtract = $_[2] if $_[2];
	if ($year) {
		my $dateval;
		if ($daysToSubtract) {
			$dateval = localtime(timegm(0,0,12,$day,$mon-1,$year)-$daysToSubtract*24*60*60);
		} else {
			$dateval = localtime(timegm(0,0,12,$day,$mon-1,$year));
		}
		return sprintf("%02d-%02d-%04d",$dateval->mday(), $dateval->mon()+1, $dateval->year()+ 1900 + $y);
	} else {
		return sprintf("%02d-%02d-%04d",localtime->mday(), localtime->mon()+1, localtime->year()+ 1900 + $y);
	}
}

sub get_curtime (;$) {
	my ($format) = $_[0];
	$format = "%02d:%02d:%02d" if !$format;
	return sprintf($format,localtime->hour(),localtime->min(),localtime->sec());
}

sub get_curtime_HHMM {
	return sprintf("%02d%02d",localtime->hour(),localtime->min(),localtime->sec());
}

sub is_first_day_of_month ($) {
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	((gmtime(timegm(0,0,12,$d,$m-1,$y)-24*60*60))[4] != $m-1 ? 1 : 0);
}

sub is_last_day_of_month ($;$) {
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	my $hol = $_[1];
	# for respecting holidays add 1 day and compare month
	if ($hol) {
		my $shiftedDate = addDaysHol($_[0],1,"YMD",$hol);
		my ($ys,$ms,$ds) = $shiftedDate =~ /(.{4})(..)(..)/;
		($ms ne $m ? 1 : 0); 
	} else {
		((gmtime(timegm(0,0,12,$d,$m-1,$y) + 24*60*60))[4] != $m-1 ? 1 : 0);
	}
}
sub get_last_day_of_month ($) {
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	
	# first of following month minus 1 day is always last of current month, timegm expects 0 based month, $m is the following month for timegm therefore
	if ($m == 12) {
		# for December -> January next year
		$m = 0; # month 0 based
		$y++;
	}
	my $mon = (gmtime(timegm(0,0,12,1,$m,$y) - 24*60*60))[4]+1;
	my $day = (gmtime(timegm(0,0,12,1,$m,$y) - 24*60*60))[3];
	$y-- if $m == 0; # for December -> reset year again
	return sprintf("%04d%02d%02d",$y, $mon, $day);
}

sub weekday ($) {
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	(gmtime(timegm(0,0,12,$d,$m-1,$y)))[6]+1;
}

sub is_weekend ($) {
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	(gmtime(timegm(0,0,12,$d,$m-1,$y)))[6] =~ /(0|6)/;
}
# makeMD: argument in timegm form (datetime), returns date in format DDMM (for holiday calculation)
sub makeMD ($) {
	sprintf("%02d%02d", (gmtime($_[0]))[3],(gmtime($_[0]))[4] + 1);
}

sub is_holiday ($$) {
	my ($hol) = $_[0];
	return 0 if $hol eq "WE";
	unless ($hol =~ /^WE$|^BS$|^BF$|^AT$|^TG$|^UK$|^TEST$/) {
		warn("calender <$hol> not implemented !");
		return 0;
	}
	return 1 if $hol eq "TEST"; # for testing purposes, here all days are holidays.
	my ($y,$m,$d) = $_[1] =~ /(.{4})(..)(..)/;
	# fixes holidays
	my $fixedHol = {"BS"=>{"0101"=>1,"0601"=>1,"0105"=>1,"1508"=>1,"2610"=>1,"0111"=>1,"0812"=>1,"2412"=>1,"2512"=>1,"2612"=>1},
					"BF"=>{"0101"=>1,"0601"=>1,"0105"=>1,"1508"=>1,"2610"=>1,"0111"=>1,"0812"=>1,"2412"=>1,"2512"=>1,"2612"=>1},
					"AT"=>{"0101"=>1,"0601"=>1,"0105"=>1,"1508"=>1,"2610"=>1,"0111"=>1,"0812"=>1,"2512"=>1,"2612"=>1},
					"TG"=>{"0101"=>1,"0105"=>1,"2512"=>1,"2612"=>1},
					"UK"=>{"0101"=>1,"2512"=>1,"2612"=>1}};
	# easter, first find easter sunday
	my $D = (((255 - 11 * ($y % 19)) - 21) % 30) + 21;
	my $easter = timegm(0,0,12,1,2,$y) + ($D + ($D > 48 ? 1 : 0) + 6 - (($y + int($y / 4) + $D + ($D > 48 ? 1 : 0) + 1) % 7))*86400;
	# then the rest
	my $goodfriday=makeMD($easter-2*86400);
	my $easterMonday=makeMD($easter+1*86400);
	my $ascensionday=makeMD($easter+39*86400);
	my $whitmonday=makeMD($easter+50*86400);
	my $corpuschristiday=makeMD($easter+60*86400);
	# enter as required for calendar
	my $easterHol = {"BS"=>{$easterMonday=>1,$ascensionday=>1,$whitmonday=>1,$corpuschristiday=>1,$goodfriday=>1},
					 "BF"=>{$easterMonday=>1,$ascensionday=>1,$whitmonday=>1,$corpuschristiday=>1},
					 "AT"=>{$easterMonday=>1,$ascensionday=>1,$whitmonday=>1,$corpuschristiday=>1},
					 "TG"=>{$easterMonday=>1,$goodfriday=>1},
					 "UK"=>{$easterMonday=>1,$goodfriday=>1}};
	# British specialties
	my $specialHol = 0;
	$specialHol = (first_week($d,$m,$y,1,5) || last_week($d,$m,$y,1,5) || last_week($d,$m,$y,1,8)) if ($hol eq "UK");
	if ($fixedHol->{$hol}->{$d.$m} or $easterHol->{$hol}->{$d.$m} or $specialHol) {
		1;
	} else {
		0;
	}
}

sub last_week ($$$$;$) {
	my ($d,$m,$y,$day,$month) = @_;
	$month = $m if !$month;
	unless ((0 <= $day) && ( $day <= 6)) {
		warn("day <$day> is out of range 0 - 6  (sunday==0)");
		return 0;
	}
	my $date = localtime(timelocal(0,0,12,$d,$m-1,$y));
	return 0 unless $m == $month; # return unless the month matches
	return 0 unless $date->wday() == $day; # return unless the (week)day matches
	return 0 unless (localtime(timelocal(0,0,12,$d,$m-1,$y)+7*24*60*60))->mon() != $m-1; # return unless 1 week later we're in a different month
	return 1;
}

sub last_weekYYYYMMDD ($$;$) {
	my ($date,$day,$month) = @_;
	my ($y,$m,$d) = $date =~ /(.{4})(..)(..)/;
	$month = $m if !$month;
	return last_week ($d,$m,$y,$day,$month);
}

sub first_week ($$$$;$) {
	my ($d,$m,$y,$day,$month) = @_;
	$month = $m if !$month;
	unless ((0 <= $day) && ( $day <= 6)) {
		warn("day <$day> is out of range 0 - 6  (sunday==0)");
		return 0;
	}
	my $date = localtime(timelocal(0,0,12,$d,$m-1,$y));
	return 0 unless $m == $month; # return unless the month matches
	return 0 if $d > 7; # can't be the first week of the month if day is after the 7th
	return 0 unless $date->wday() == $day; # return unless the (week)day matches
	return 0 unless (localtime(timelocal(0,0,12,$d,$m-1,$y)-7*24*60*60))->mon() != $m-1; # return unless 1 week earlier we're in a different month
	return 1;
}

sub first_weekYYYYMMDD ($$;$) {
	my ($date,$day,$month) = @_;
	my ($y,$m,$d) = $date =~ /(.{4})(..)(..)/;
	$month = $m if !$month;
	return first_week ($d,$m,$y,$day,$month);
}

sub convertDate ($) {
	my ($y,$m,$d) = ($_[0] =~ /(\d{4})[.\/](\d\d)[.\/](\d\d)/);
	return sprintf("%04d%02d%02d",$y, $m, $d);
}

sub convertDateFromMMM ($$$$) {
	my ($inDate, $day, $mon, $year) = @_;
	my ($d,$m,$y) = ($inDate =~ /(\d{2})-(\w{3})-(\d{4})/);
	my %months = ('Jan'=> 1, 'Feb'=> 2, 'Mar'=> 3, 'Apr'=> 4, 'May'=> 5, 'Jun'=> 6, 'Jul'=> 7, 'Aug'=> 8, 'Sep'=> 9, 'Oct'=> 10, 'Nov'=> 11, 'Dec'=> 12);
	$$day = $d;
	$$mon = $months{$m};
	$$year = $y;
	return sprintf("%02d.%02d.%04d",$d, $months{$m}, $y);
}

sub convertDateToMMM ($$$) {
	my ($day,$mon,$year) = @_;
	my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
	return sprintf("%02d-%03s-%04d",$day, $months[$mon-1], $year);
}

sub convertToDDMMYYYY ($) {
	my ($y,$m,$d) = $_[0] =~ /(.{4})(..)(..)/;
	return "$d.$m.$y";
}

sub addDays ($$$$) {
	my ($day,$mon,$year,$dayDiff) = @_;
	my $curDateEpoch = timelocal(0,0,0,$$day,$$mon-1,$$year-1900);
	my $diffDate = localtime($curDateEpoch + $dayDiff * 60 * 60 * 25);
	my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
	# dereference, so the passed variable is changed
	$$year = $diffDate->year+1900;
	$$mon = $diffDate->mon+1;
	$$day = $diffDate->mday;
	return sprintf("%02d-%03s-%04d",$$day, $months[$$mon-1], $$year);
}

sub subtractDays ($$) {
	my ($date,$days) = @_;
	my ($y,$m,$d) = $date =~ /(.{4})(..)(..)/;
	my $theDate = localtime(timelocal(0,0,12,$d,$m-1,$y) - $days*24*60*60);
	return sprintf("%04d%02d%02d",$theDate->year()+ 1900, $theDate->mon()+1, $theDate->mday());
}

sub subtractDaysHol ($$;$$) {
	my ($date,$days,$template,$hol) = @_;
	$hol="NO" if !$hol;
	my ($y,$m,$d) = $date =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	# first subtract days
	my $refdate = localtime(timelocal(0,0,12,$d,$m-1,$y) - $days*24*60*60);
	# then subtract further days as long weekend or holidays
	if ($hol ne "NO") {
		while ($refdate->wday() == 0 || $refdate->wday() == 6 || is_holiday($hol, sprintf("%04d%02d%02d", $refdate->year()+1900, $refdate->mon()+1, $refdate->mday()))) {
			$refdate = localtime(timelocal(0,0,12,$refdate->mday(),$refdate->mon(),$refdate->year()+1900) - 24*60*60);
		}
	}
	return formatDate($refdate->year()+1900, $refdate->mon()+1, $refdate->mday(),$template);
}

sub addDaysHol ($$;$$) {
	my ($date, $days, $template, $hol) = @_;
	$hol="NO" if !$hol;
	my ($y,$m,$d) = $date =~ /(.{4})(..)(..)/;
	return undef if !$y or !$m or !$d;
	# first add days
	my $refdate = localtime(timelocal(0,0,12,$d,$m-1,$y) + $days*24*60*60);
	# then add further days as long weekend or holidays
	if ($hol ne "NO") {
		while ($refdate->wday() == 0 || $refdate->wday() == 6 || is_holiday($hol,sprintf("%04d%02d%02d", $refdate->year()+1900, $refdate->mon()+1, $refdate->mday()))) {
			$refdate = localtime(timelocal(0,0,12,$refdate->mday(),$refdate->mon(),$refdate->year()+1900) + 24*60*60);
		}
	}
	return formatDate($refdate->year()+1900, $refdate->mon()+1, $refdate->mday(),$template);
}

sub addDatePart {
	my ($date, $count, $datepart, $template) = @_;
	my %datepart = (d=>3,m=>4,y=>5,day=>3,mon=>4,year=>5,D=>3,M=>4,Y=>5,month=>4);
	my ($y,$m,$d) = $date =~ /(.{4})(..)(..)/;
	my $parts = localtime(timelocal(0,0,12,$d,$m-1,$y));
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
	$number = $number / $divideBy if $divideBy;
	$number = "$number";
	$number =~ s/\./,/;
	return $number;
}

sub convertToThousendDecimal ($;$) {
	my ($value,$ignoreDecimal) = @_;
	my ($negSign) = ($value =~ /(-).*?/);
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
	my ($fromDate,$toDate,$hol) = @_;
	my ($yf,$mf,$df) = $fromDate =~ /(.{4})(..)(..)/;
	my ($yt,$mt,$dt) = $toDate =~ /(.{4})(..)(..)/;
	my $from = timelocal(0,0,12,$df,$mf-1,$yf);
	my $to = timelocal(0,0,12,$dt,$mt-1,$yt);
	my @dateseries;
	for ($_= $from; $_<= $to; $_ += 24*60*60) {
		my $date = localtime($_);
		my $datestr = sprintf("%04d%02d%02d",$date->year()+1900,$date->mon()+1,$date->mday());
		if ($hol) {
			push @dateseries, $datestr if $date->wday() != 0 && $date->wday() != 6 && !is_holiday($hol,$datestr);
		} else {
			push @dateseries, $datestr;
		}
	}
	return @dateseries;
}

sub parseFromDDMMYYYY ($) {
	my ($dateStr) = @_;
	my ($df,$mf,$yf) = $dateStr =~ /(..*)\.(..*)\.(.{4})/;
	return "invalid date" if !($yf >= 1900) or !($mf >= 1 && $mf <= 12) or !($df >= 1 && $df <= 31);
	return timelocal(0,0,0,$df,$mf-1,$yf);
}

sub parseFromYYYYMMDD ($) {
	my ($dateStr) = @_;
	my ($yf,$mf,$df) = $dateStr =~ /(.{4})(..)(..)/;
	return "invalid date" if !($yf >= 1900) or !($mf >= 1 && $mf <= 12) or !($df >= 1 && $df <= 31);
	return timelocal(0,0,0,$df,$mf-1,$yf);
}

sub convertEpochToYYYYMMDD ($) {
	my ($arg) = @_;
	if (ref($arg) eq 'Time::Piece') {
		return sprintf("%04d%02d%02d",$arg->year(),$arg->mon(),$arg->mday());
	} else {
		my $date = localtime($arg);
		return sprintf("%04d%02d%02d",$date->year()+1900,$date->mon()+1,$date->mday());
	}

}
1;
__END__

=encoding CP1252

=head1 NAME

EAI::DateUtil - Date and Time helper functions for L<EAI::Wrap>

=head1 SYNOPSIS

 %months = ("Jan" => "01","Feb" => "02","Mar" => "03","Apr" => "04","May" => "05","Jun" => "06","Jul" => "07","Aug" => "08","Sep" => "09","Oct" => "10","Nov" => "11","Dec" => "12");
 %monate = ("Jan" => "01","Feb" => "02","Mär" => "03","Apr" => "04","Mai" => "05","Jun" => "06","Jul" => "07","Aug" => "08","Sep" => "09","Okt" => "10","Nov" => "11","Dez" => "12");

 get_curdate ()
 get_curdatetime ()
 get_curdate_dot ()
 formatDate ($d, $m, $y, [$template])
 formatDateFromYYYYMMDD($date, [$template])
 get_curdate_gen ([$template])
 get_curdate_dash ()
 get_curdate_dash_plus_X_years ($years)
 get_curtime ()
 get_curtime_HHMM ()
 get_lastdateYYYYMMDD ()
 get_lastdateDDMMYYYY ()
 is_first_day_of_month ($date YYYYMMDD)
 is_last_day_of_month ($date YYYYMMDD, [$hol])
 get_last_day_of_month ($date YYYYMMDD)
 weekday ($date YYYYMMDD)
 is_weekend ($date YYYYMMDD)
 is_holiday ($hol, $date YYYYMMDD)
 first_week ($d,$m,$y,$day,[$month])
 first_weekYYYYMMDD ($date,$day,[$month])
 last_week ($d,$m,$y,$day,[$month])
 last_weekYYYYMMDD ($date,$day,[$month])
 convertDate ($date YYYY.MM.DD or YYYY/MM/DD)
 convertDateFromMMM ($inDate dd-mmm-yyyy, out $day, out $mon, out $year)
 convertDateToMMM ($day, $mon, $year)
 convertToDDMMYYYY ($date YYYYMMDD)
 addDays ($day, $mon, $year, $dayDiff)
 addDaysHol ($date, $days, [$template, $hol])
 addDatePart ($date, $count, $datepart, [$template])
 subtractDays ($date, $days)
 subtractDaysHol ($date, $days, [$template, $hol])
 convertcomma ($number, $divideBy)
 convertToThousendDecimal($value, $ignoreDecimal)
 get_dateseries
 parseFromDDMMYYYY ($dateStr)
 parseFromYYYYMMDD ($dateStr)
 convertEpochToYYYYMMDD ($epoch)

=head1 DESCRIPTION

EAI::DateUtil contains all date/time related API-calls.

=head2 API

=over

=item %months

conversion hash english months -> numbers, usage: $months{"Oct"} equals 10

=item %monate

conversion hash german months -> numbers, usage: $monate{"Okt"} equals 10

=item get_curdate

gets current date in format YYYYMMDD

=item get_curdatetime

gets current datetime in format YYYYMMDD_HHMMSS

=item get_curdate_dot

gets current date in format DD.MM.YYYY

=item formatDate

formats passed date (given in arguments $y,$m,$d) into format as defined in $template

 $d .. day part
 $m .. month part
 $y .. year part
 $template .. optional, date template with D for day, M for month and Y for year (e.g. D.M.Y for 01.02.2016),
              D and M is always 2 digit, Y always 4 digit; if empty/nonexistent defaults to "YMD"
              special formats are MMM und mmm als monthpart, here three letter month abbreviations in english (MMM) or german (mmm) are returned as month

=item formatDateFromYYYYMMDD

formats passed date (given in argument $date) in format as defined in $template

 $date .. date in format YYYYMMDD
 $template .. same as in formatDate

=item get_curdate_gen

returns current date in format as defined in $template

 $template .. same as in formatDate

=item get_curdate_dash

returns current date in format DD-MM-YYYY

=item get_curdate_dash_plus_X_years: date + X years in format DD-MM-YYYY

 $y .. years to be added to the current or given date
 $year,$mon,$day .. optional date to which X years should be added (if not given current date is taken instead).
 $daysToSubtract .. days that should be subtracted from the result

=item get_curtime

returns current time in format HH:MM:SS (or as given in formatstring $format, however ordering of format is always hour, minute and second)

 $format .. optional sprintf format string (e.g. %02d:%02d:%02d) for hour, minute and second

=item get_curtime_HHMM

returns current time in format HHMM

=item is_first_day_of_month

returns 1 if first day of months, 0 else

 $date .. date in format YYYYMMDD

=item is_last_day_of_month

returns 1 if last day of month, 0 else

 $date .. date in format YYYYMMDD
 $hol .. optional, calendar for holidays used to get the last of month

=item get_last_day_of_month

returns last day of month of passed date

 $date .. date in format YYYYMMDD

=item weekday

returns 1..sunday to 7..saturday

 $date .. date in format YYYYMMDD

=item is_weekend

returns 1 if saturday or sunday

 $date .. date in format YYYYMMDD

=item is_holiday

returns 1 if weekend or holiday

 $hol .. holiday calendar; currently supported: AT (Austria), TG (Target), UK (see is_holiday) and WE (for only weekends).
         throws error if calendar not supported (Hashlookup).
 $date .. date in format YYYYMMDD

=item last_week

returns 1 if given date ($d,$m,$y) is the last given weekday ($day: 0 - 6, sunday==0) in given month ($month),
 if $month is not passed, then it is taken from passed date.

 $d .. day part
 $m .. month part
 $y .. year part
 $day .. given weekday
 $month .. optional, given month

=item last_weekYYYYMMDD

returns 1 if given date ($date in Format YYYYMMDD) is the last given weekday ($day: 0 - 6, sunday==0) in given month ($month),
 if $month is not passed, then it is taken from passed date.
 
 $date .. given date
 $day .. given weekday
 $month .. optional, given month
 
=item first_week

returns 1 if given date ($d,$m,$y) is the first given weekday ($day: 0 - 6, sunday==0) in given month ($month),
 if $month is not passed, then it is taken from passed date.

 $d .. day part
 $m .. month part
 $y .. year part
 $day .. given weekday
 $month .. optional, given month

=item first_weekYYYYMMDD

returns 1 if given date ($date in Format YYYYMMDD) is the first given weekday ($day: 0 - 6, sunday==0) in given month ($month),
 if $month is not passed, then it is taken from passed date.

 $date .. given date
 $day .. given weekday
 $month .. optional, given month
 
=item convertDate

converts given date to format YYYYMMDD

 $date .. date in format YYYY.MM.DD or YYYY/MM/DD

=item convertDateFromMMM

converts date from format dd-mmm-yyyy (01-Oct-05, english !), returns date in format DD.MM.YYYY ($day, $mon, $year are returned by ref as well)

 $inDate .. date to be converted
 $day .. ref for day part
 $mon .. ref for month part
 $year ..  ref for year part

=item convertDateToMMM

converts date into ($day, $mon, $year) from format dd-mmm-yyyy (01-Oct-05, english !)

 $day .. day part
 $mon .. month part
 $year .. year part

=item convertToDDMMYYYY

converts date into $datestring (dd.mm.yyyy) from format YYYYMMDD

 $date .. date in format YYYYMMDD

=item addDays

adds $dayDiff to date ($day, $mon, $year) and returns in format dd-mmm-yyyy (01-Oct-05, english !),
                arguments $day, $mon, $year are returned by ref as well if not passed as literal

 $day .. day part
 $mon .. month part
 $year .. year part
 $dayDiff .. days to be added

=item subtractDays

subtracts $days actual calendar days from $date

 $date .. date in format YYYYMMDD
 $days .. calendar days to subtract

=item subtractDaysHol

subtracts $days days from $date and regards weekends and holidays of passed calendar

 $date .. date in format YYYYMMDD
 $days .. calendar days to subtract
 $template .. as in formatDate
 $hol .. holiday calendar; currently supported: NO (no holidays  = default if not given), rest as in is_holiday

=item addDaysHol

adds $days days to $date and regards weekends and holidays of passed calendar

 $date .. date in format YYYYMMDD
 $days .. calendar days to add
 $template .. as in formatDate
 $hol .. holiday calendar; currently supported: NO (no holidays = default if not given), rest as in is_holiday
 
=item addDatePart

adds $count dateparts to $date. when adding to months ends (>28 in february, >29 or >30 else), if the month end is not available in the target month, then date is moved into following month

 $date .. date in format YYYYMMDD
 $count .. count of dateparts to add
 $datepart .. can be "d" or "day" for days, "m"/"mon"/"month" for months and "y" or "year" for years
 $template .. as in formatDate

=item get_lastdateYYYYMMDD

returns last business day (only weekends, no holiday here !) in format YYYYMMDD

=item get_lastdateDDMMYYYY

returns last business day (only weekends, no holiday here !) in format DDMMYYYY

=item convertcomma

converts decimal point in $number to comma, also dividing by $divideBy before if $divideBy is set

 $number ..  number to be converted
 $divideBy .. number to be divided by

=item convertToThousendDecimal

converts $value into thousand separated decimal (german format) ignoring decimal places if wanted
 
 $value .. number to be converted
 $ignoreDecimal .. return number without decimal places (truncate)

=item get_dateseries

returns date values (format YYYYMMMDD) starting at $fromDate until $toDate, if a holiday calendar is set in $hol (optional), these holidays (incl. weekends) are regarded as well.
 
 $fromDate .. start date
 $toDate .. end date
 $hol .. holiday calendar

=item parseFromDDMMYYYY

returns time epoch from datestring (dd.mm.yyyy)

 $dateStr .. datestring

=item parseFromYYYYMMDD

returns time epoch from datestring (yyyymmdd)

 $dateStr .. datestring

=item convertEpochToYYYYMMDD

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