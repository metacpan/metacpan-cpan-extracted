package Lingua::JA::FindDates;
use warnings;
use strict;
use Carp qw/carp croak cluck/;
use utf8;
use 5.010000;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK= qw/subsjdate kanji2number seireki_to_nengo nengo_to_seireki
		   regjnums @jdatere/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

our $VERSION = '0.027';

# Kanji number conversion table.

my %kanjinums = 
(
    〇 => 0,
    一 => 1,
    二 => 2,
    三 => 3,
    四 => 4,
    五 => 5,
    六 => 6,
    七 => 7,
    八 => 8,
    九 => 9,
    十 => 10,
    百 => 100,
    # Dates shouldn't get any bigger than the following times a digit.
    千 => 1000,
); 

# The kanji digits.

my $kanjidigits = join ('', keys %kanjinums);

sub kanji2number
{
    my ($knum) = @_;
    return 1 if $knum eq '元';
    my @kanjis = split '', $knum;
    my $value = 0;
    my $keta = 1;
    while (1) {
	my $k = pop @kanjis;
	return $value if ! defined $k;
	my $val = $kanjinums{$k};
        # Make sure this kanji number is one we know how to handle.
	if (! defined $val) {
	    warn "can't cope with '$k' of input '$knum'";
	    return 0;
	}
        # If the value of the individual kanji is more than 10.
	if ($val >= 10) {
	    $keta = $val;
	    my $knext = pop @kanjis;
	    if (!$knext) {
		return $value + $val;
	    }
	    my $val_next = $kanjinums{$knext};
	    if (!defined $val_next) {
		warn "can't cope with '$knext' of input '$knum'.\n";
		return 0;
	    }
	    if ($val_next > 10) {
		push @kanjis, $knext;
		$value += $val;
	    }
            else {
		$value += $val_next * $val;
	    }
	}
        else {
            # $k is a kanji digit from 0 to 9, and $val is its value.
	    $value += $val * $keta;
	    $keta *= 10;
	}
    }
}

#  ____                               
# |  _ \ ___  __ _  _____  _____  ___ 
# | |_) / _ \/ _` |/ _ \ \/ / _ \/ __|
# |  _ <  __/ (_| |  __/>  <  __/\__ \
# |_| \_\___|\__, |\___/_/\_\___||___/
#            |___/                    

my $jdigit = qr/[０-９0-9]/;

# A regular expression to match Japanese numbers

my $jnumber = qr/($jdigit+|[$kanjidigits]+)/x;

# A regular expression to match a Western year

my $wyear = qr/
                  (
                      $jdigit{4}
                  |
                      [$kanjidigits]?千[$kanjidigits]*
                  |
                      [\']$jdigit{2}
                  )
                  \s*年
              /x;

my $alpha_era = qr/
                      # If the H, S, T, or M is part of a longer
                      # string of romaji, do not match it.
                      (?<![A-ZＡ-Ｚ])
                      (?:
                          [H|Ｈ|S|Ｓ|T|Ｔ|M|Ｍ]
                      )
                  /x;

# The recent era names (Heisei, Showa, Taisho, Meiji). These eras are
# sometimes written using the letters H, S, T, and M.

my $jera = qr/($alpha_era|平|昭|大|明|平成|昭和|大正|明治|㍻|㍼|㍽|㍾)/;

# A map of Japanese eras to Western dates. These are the starting year
# of the period minus one, to allow for that the first year is "heisei
# one" rather than "heisei zero".

my %jera2w = (
    H    => 1988,
    Ｈ   => 1988,
    平成 => 1988,
    平 => 1988,
    '㍻' => 1988,
    S    => 1925,
    Ｓ   => 1925,
    昭和 => 1925,
    昭 => 1925,
    '㍼' => 1925,
    T    => 1911,
    Ｔ   => 1911,
    大正 => 1911,
    大 => 1911,
    '㍽' => 1911,
    M    => 1867,
    Ｍ   => 1867,
    明治 => 1867,
    明 => 1867,
    '㍾' => 1867,
);

# Japanese year, with era like "Heisei" at the beginning.

my $jyear = qr/
                  $jera
                  \h*
                  # Only match up to one or two of these digits, to
                  # prevent unlikely matches.
                  (
                      $jdigit{1,2}
                  |
                      [$kanjidigits]{1,2}
                  |
                      # The first year of an era, something like
                      # "昭和元年" (1926, the first year of the Showa era).
                      元 
                  )
                  \h*
                  年
              /x;

# The "jun" or approximately ten day periods (thirds of a month)

my %jun = qw/初 1 上 1 中 2 下 3/;

# The translations of the "jun" above into English.

my @jun2english = (
    'invalid',
    'early ',
    'mid-',
    'late ',
);

# Japanese days of the week, from Monday to Sunday.

my $weekdays = '月火水木金土日';
my @weekdays = split '',$weekdays;

# Match a string for a weekday, like 月曜日 or (日)
# The long part (?=\W) is to stop it from accidentally matching a
# kanji which is part of a different word, like the following:
#平成二十年七月一日
#    日本論・日本人論は非常に面白いものだ。

my $match_weekday =
    qr/[\（(]?
       ([$weekdays])
       (?:(?:(?:曜日|曜)[)\）])|[)\）]|(?=\W))
      /x;

# Match a day of the month, like 10日

my $match_dom = qr/$jnumber\h*日/;

# Match a month

my $match_month = qr/$jnumber\h*月/;

# Match a "jun" (a third of a month).

my $jun_keys = join ('', keys %jun);

my $match_jun = qr/([$jun_keys])\h*旬/;

# Match a month+jun

my $match_month_jun = qr/$match_month\h*$match_jun/;

# Match a month and day of month pair

my $match_month_day = qr/$match_month\h*$match_dom/;

# Match a Japanese year, month, day string

my $matchymd = qr/
                     $jyear
                     \h*
                     $match_month_day
                 /x;

# Match a Western year, month, day string

my $matchwymd = qr/$wyear\h*$match_month_day/;

# Match a Japanese year and month only

my $match_jyear_month = qr/$jyear\h*$match_month/;

# Match a Western year and month only

my $match_wyear_month = qr/$wyear\h*$match_month/;

# Match a month, day, weekday.

my $match_month_day_weekday = qr/$match_month_day\h*$match_weekday/;

# Separators used in date strings
# Microsoft Word uses Unicode 0xFF5E, the "fullwidth tilde", for nyoro symbol.

my $separators = qr/\h*[〜−~]\h*/;
 
#  _     _     _            __                                     
# | |   (_)___| |_    ___  / _|  _ __ ___  __ _  _____  _____  ___ 
# | |   | / __| __|  / _ \| |_  | '__/ _ \/ _` |/ _ \ \/ / _ \/ __|
# | |___| \__ \ |_  | (_) |  _| | | |  __/ (_| |  __/>  <  __/\__ \
# |_____|_|___/\__|  \___/|_|   |_|  \___|\__, |\___/_/\_\___||___/
#                                         |___/                    

# This a list of date regular expressions.

our @jdatere = (

    # Match an empty string like 平成 月 日 as found on a form etc.

    [qr/
           $jyear
           (\h+)
           月
           \h+
           日
       /x,
     "ejx"],

    # Add match for dummy strings here!

    # Match a Japanese era, year, 2 x (month day weekday) combination

    [qr/
           $matchymd
           \h*$match_weekday
           $separators
           $matchymd
           \h*$match_weekday
       /x,
     "e1j1m1d1w1e2j2m2d2w2"],

    # Match 2 x (era, year, month, day) combination

    [qr/
           $matchymd
           $separators
           $matchymd
       /x,
     "e1j1m1d1e2j2m2d2"],

    # Match a Japanese era, year, month 2 x (day, weekday) combination

    [qr/
           $matchymd
           $match_weekday
           $separators
           $match_dom
           \h*
           $match_weekday
       /x, 
     "ejmd1w1d2w2"],

    # Match a Japanese era, year, month 2 x day combination

    [qr/
           $matchymd
           $separators
           $match_dom
           \h*
           $match_weekday
       /x,
     "ejmd1d2"],

    # Match 2x(Western year, month, day, weekday) combination

    [qr/
           $matchwymd
           \h*
           $match_weekday
           $separators
           $matchwymd
           $match_weekday
       /x,
     "y1m1d1w1y2m2d2w2"],

    # Match a Western year, 2x(month, day, weekday) combination

    [qr/
           $matchwymd
           \h*
           $match_weekday
           $separators
           $match_month_day_weekday
       /x,
     "ym1d1w1m2d2w2"],

    # Match a Western year, month, 2x(day, weekday) combination

    [qr/
           $matchwymd
           \h*
           $match_weekday
           $separators
           $match_dom
           \h*
           $match_weekday
       /x,
     "ymd1w1d2w2"],

    # Match a Western year, month, 2x(day) combination

    [qr/
           $matchwymd
           $separators
           $match_dom
       /x,
     "ymd1d2"],

    # Match a Japanese era, year, month1 day1 - month 2 day2 combination

    [qr/
           $matchymd
           $separators
           $match_month_day
       /x,
     "ejm1d1m2d2"],

    # Match 2 x ( Japanese era, year, month) combination

    [qr/
           $jyear
           \h*
           $jnumber
           \h*月?
           $separators
           $jyear
           \h*
           $match_month
       /x, "e1j1m1e2j2m2"],

    # Match a Japanese era, year, month1 - month 2 combination

    [qr/
           $jyear
           \h*
           $jnumber
           \h*月?
           $separators
           $match_month
       /x, "ejm1m2"],

    # Match a Japanese era, year, month, day1 - day2 combination

    [qr/
           $match_jyear_month
           \h*
           $jnumber
           \h*日?
           $separators
           $match_dom
       /x,
     "ejmd1d2"],

    # Match a Japanese era, year, month, day, weekday combination

    [qr/
           $matchymd
           \h*
           $match_weekday
       /x,
     "ejmdw"],

    # Match a Japanese era, year, month, day

    [qr/$matchymd/,
     "ejmd"],

    # Match a Japanese era, year, month, jun

    [qr/
           $match_jyear_month
           \h*
           $match_jun
       /x,
     "ejmz"],

    # Match a Western year, month, day, weekday combination

    [qr/
           $matchwymd
           \h*
           $match_weekday
       /x,
     "ymdw"],

    # Match a Western year, month, day combination

    [qr/$matchwymd/,
     "ymd"],

    # Match a Western year, month, jun combination

    [qr/
           $match_wyear_month
           \h*
           $match_jun
       /x,
     "ymz"],

    # Match a Japanese era, year, month

    [qr/
           $jyear
           \h*
           $jnumber
           \h*
           月
       /x,
     "ejm"],

    # Match a Western year, month

    [qr/$match_wyear_month/,
     "ym"],

    # Match 2 x (month, day, weekday)

    [qr/
           $match_month_day_weekday
           $separators
           $match_month_day_weekday
       /x, 
     "m1d1w1m2d2w2"],

    # Match month, 2 x (day, weekday)

    [qr/
           $match_month_day_weekday
           $separators
           $match_dom
           \h*
           $match_weekday
       /x,
     "md1w1d2w2"],

    # Match month, 2 x (day, weekday)

    [qr/
           $match_month_day
           $separators
           $match_dom
       /x,
     "md1d2"],

    # Match a month, day, weekday

    [qr/$match_month_day_weekday/,
     "mdw"],

    # Match a month, day

    [qr/$match_month_day/,
     "md"],

    # Match a fiscal year (年度, nendo in Japanese). These usually don't
    # have months combined with them, so there is nothing to match a
    # fiscal year with a month.

    [qr/
           $jyear
           度
       /x,
     "en"],

    # Match a fiscal year (年度, nendo in Japanese). These usually don't
    # have months combined with them, so there is nothing to match a
    # fiscal year with a month.

    [qr/
           $wyear
           度
       /x,
     "n"],

    # Match a Japanese era, year

    [qr/$jyear/,
     "ej"],

    # Match a Western year

    [qr/$wyear/,
     "y"],

    # Match a month with a jun

    [
        qr/
              $match_month
              \h*
              $match_jun
          /x,
        "mz"
    ],

    # Match a month

    [
        qr/$match_month/,
        "m"
    ],
);

my @months = qw/Invalid
                January
                February
                March
                April
                May
                June
                July
		August
                September
                October
                November
                December
                MM/;

my @days = qw/Invalid
              Monday
              Tuesday
              Wednesday
              Thursday
              Friday
              Saturday
              Sunday/;

# This is a translation table from the Japanese weekday names to the
# English ones.

my %j2eweekday;

@j2eweekday{@weekdays} = (1..7);

# This is the default routine for turning a Japanese date into a
# foreign-style one.

sub make_date
{
    goto & default_make_date;
}

sub make_date_interval
{
    goto & default_make_date_interval;
}

sub default_make_date
{
    my ($datehash) = @_;
    my ($year, $month, $date, $wday, $jun) = 
	@{$datehash}{qw/year month date wday jun/};
    if (!$year && !$month && !$date && !$jun) {
	carp "No valid inputs\n";
	return;
    }
    my $edate = '';
    $edate = $days[$wday].", " if $wday;
    if ($month) {
	$month = int ($month); # In case it is 07 etc.
	$edate .= $months[$month];
	if ($jun) {
	    $edate = $jun2english[$jun] . $edate;
	}
    }
    if ($date) {
	$edate .= " " if length ($edate);
	$date = int ($date); # In case it is 07 etc.
	$date = "DD" if $date == 32;
	if ($year) {
	    $edate .= "$date, $year";
	}
	else {
	    $edate .= "$date";
	}
    }
    elsif ($year) {
	if (length ($edate) > 0) {
	    $edate .= " ";
	}
	$edate .= $year;
    }
    return $edate;
}

our $date_sep = '-';

# This is the default routine for turning a date interval into a
# foreign-style one, which is then substituted into the text.

sub default_make_date_interval
{
    my ($date1, $date2) = @_;
    my $einterval = '';
    my $usecomma;
    # The case of an interval with different years doesn't need to be
    # considered, because each date in that case can be considered a
    # single date.

    if ($date2->{month}) {
	if (!$date1->{month}) {
	    carp "end month but no starting month";
	    return;
	}
    }
    if ($date1->{month}) {
	if ($date1->{wday} && $date2->{wday}) {
	    if (! $date1->{date} || ! $date2->{date}) {
		carp "malformed date has weekdays but not days of month";
		return;
	    }
	    $usecomma = 1;
	    $einterval = $days[$date1->{wday}]  . " " . $date1->{date} .
		         ($date2->{month} ? ' '.$months[int ($date1->{month})] : ''). $date_sep .
		         $days[$date2->{wday}]  . " " . $date2->{date} . " " .
			 ($date2->{month} ? $months[int ($date2->{month})] : $months[int ($date1->{month})]);
	}
        elsif ($date1->{date} && $date2->{date}) {
	    $usecomma = 1;
	    if ($date1->{wday} || $date2->{wday}) {
		carp "malformed date interval: ",
		    "has weekday for one date $date1->{wday} but not the other one $date2->{wday} .";
		return;
	    }
	    $einterval = $months[int ($date1->{month})] . ' ' .
		         $date1->{date} . $date_sep .
			 ($date2->{month} ? 
			  $months[int ($date2->{month})] . ' ' : '') .
		         $date2->{date};
	}
        else { # no dates or weekdays
	    if ($date1->{date} || $date2->{date}) {
		cluck "malformed date interval: only one day of month";
		return;
	    }
	    if (!$date2->{month}) {
		carp "start month but no end month or date";
		return;
	    }
	    $einterval = $months[int($date1->{month})] . $date_sep . 
		         $months[int($date2->{month})] .
			 $einterval;
	}
    }
    else { # weekday - day / weekday - day case.
	if ($date1->{wday} && $date2->{wday}) {
	    if (! $date1->{date} || ! $date2->{date}) {
		carp "malformed date has weekdays but not days of month";
		return;
	    }
	    $einterval = $date1->{wday}  . " " . $date1->{date} . $date_sep .
		         $date2->{wday}  . " " . $date2->{date};
	}
    }
    if ($date1->{year}) {
	my $year1 = ($usecomma ? ', ': ' ').$date1->{year};
	if (! $date2->{year} || $date2->{year} == $date1->{year}) {
	    $einterval .= $year1;
	}
	else {
	    $einterval =~ s/\Q$date_sep/$year1$date_sep/;
	    my $year2 = ($usecomma ? ', ': ' ').$date2->{year};
	    $einterval .= $year2;
	}
    }
    return $einterval;
}

our $verbose = 0;

sub subsjdate
{
    # $text is the text to substitute. It needs to be in Perl's
    # internal encoding.
    # $replace_callback is a routine to call back if we find valid dates.
    # $data is arbitrary data to pass to the callback routine.
    my ($text, $c) = @_;
    # Save doing existence tests.
    if (! $c) {
        $c = {};
    }
    if (! $text) {
        return $text;
    }
    # Loop through all the possible regular expressions.
    for my $datere (@jdatere) {
	my $regex = $datere->[0];
	my @process = split (/(?=[a-z][12]?)/, $datere->[1]);
        if ($verbose) {
            print "Looking for $datere->[1]\n";
        }
	while ($text =~ /($regex)/g) {
	    my $date1;
	    my $date2;
            # The matching string is in the following variable.
	    my $orig = $1;
	    my @matches = ($2,$3,$4,$5,$6,$7,$8,$9);
            if ($verbose) {
                print "Found '$orig': ";
            }
	    for (0..$#matches) {
		my $arg = $matches[$_];

		last if !$arg;
		$arg =~ tr/０-９/0-9/;
		$arg =~ s/([$kanjidigits]+|元)/kanji2number($1)/ge;
                if ($verbose) {
                    print "Arg $_: $arg ";
                }
		my $argdo = $process[$_];
		if ($argdo eq 'e1') { # Era name in Japanese
		    $date1->{year} = $jera2w{$arg};
		}
                elsif ($argdo eq 'j1') { # Japanese year
		    $date1->{year} += $arg;
		}
                elsif ($argdo eq 'y1') {
		    $date1->{year} = $arg;
		}
		elsif ($argdo eq 'e2') { # Era name in Japanese
		    $date2->{year} = $jera2w{$arg};
		}
                elsif ($argdo eq 'j2') { # Japanese year
		    $date2->{year} += $arg;
		}
                elsif ($argdo eq 'y2') {
		    $date2->{year} = $arg;
		}
		elsif ($argdo eq 'e') { # Era name in Japanese
		    $date1->{year} = $jera2w{$arg};
		}
                elsif ($argdo eq 'j') { # Japanese year
		    $date1->{year} += $arg;
		}
                elsif ($argdo eq 'y') {
		    $date1->{year} = $arg;
		}
                elsif ($argdo eq 'n') {
		    $date1->{year} += $arg;
		    $date1->{year} = "fiscal ".$date1->{year};
		}
                elsif ($argdo eq 'm' || $argdo eq 'm1') {
		    $date1->{month} = $arg;
		}
                elsif ($argdo eq 'd' || $argdo eq 'd1') {
		    $date1->{date} = $arg;
		}
                elsif ($argdo eq 'm2') {
		    $date2->{month} = $arg;
		}
                elsif ($argdo eq 'd2') {
		    $date2->{date} = $arg;
		}
                elsif ($argdo eq 'w' || $argdo eq 'w1') {
		    $date1->{wday} = $j2eweekday{$arg};
		}
                elsif ($argdo eq 'w2') {
		    $date2->{wday} = $j2eweekday{$arg};
		}
                elsif ($argdo eq 'z') {
		    $date1->{jun} = $jun{$arg};
		}
                elsif ($argdo eq 'x') {
                    if ($verbose) {
                        print "Dummy date '$orig'.\n";
                    }
		    $date1->{date}  = 32;
		    $date1->{month} = 13;
		}
	    }
	    my $edate;
	    if ($date2) {
                # Date interval
		if ($c->{make_date_interval}) {
		    $edate = &{$c->{make_date_interval}} ($c->{data}, $orig,
							  $date1, $date2);
		}
                else {
		    $edate = default_make_date_interval ($date1, $date2);
		}
	    }
            else {
                # Single date
		if ($c->{make_date}) {
		    $edate = &{$c->{make_date}}($c->{data}, $orig, $date1);
		}
                else {
		    $edate = default_make_date ($date1);
		}
	    }
            if ($verbose) {
                print "-> '$edate'\n";
            }
	    $text =~ s/\Q$orig\E/$edate/g;
	    if ($c->{replace}) {
		&{$c->{replace}} ($c->{data}, $orig, $edate);
	    }
	}
    }
    return $text;
}

sub nengo_to_seireki
{
    my ($text) = @_;
    my %data;
    $data{count} = 0;

    my $out_text = subsjdate (
        $text, {
            make_date => \& nengo_to_seireki_make_date, 
            data => \%data,
        }
    );
    $out_text =~ s/#REPLACEME(\d+)REPLACEME#/$data{$1}/g;
    return $out_text;
}

sub nengo_to_seireki_make_date
{
    my ($data, $original, $date) = @_;
    if ($date->{year}) {
        $original =~ s/.*年/$date->{year}年/;
        my $count = $data->{count};
        $data->{$count} = $original;
        $data->{count}++;
        return "#REPLACEME${count}REPLACEME#";
    }
    else {
        return $original;
    }
}

sub seireki_to_nengo
{
    my ($text) = @_;
    my %data;
    $data{count} = 0;

    my $out_text = subsjdate (
        $text, {
            make_date => \& seireki_to_nengo_make_date, 
            data => \%data,
        }
    );
    $out_text =~ s/#REPLACEME(\d+)REPLACEME#/$data{$1}/g;
    return $out_text;
}

sub seireki_to_nengo_make_date
{
    my ($data, $original, $date) = @_;
    my $year = $date->{year};
    my @eras = (
        ['平成', 1989, 1, 8],
        ['昭和', 1926, 12, 25],
        ['大正', 1912, 7, 30],
        ['明治', 1868, 1, 25],
    );
    if (defined $year) {
        for my $era (@eras) {
            my $ename = $era->[0];
            my $eyear = $era->[1];
            my $emonth = $era->[2];
            my $eday = $era->[3];
            my $month = $date->{month};
            my $date = $date->{date};

            # This is a flag which says whether to perform a
            # substitution of the year or not.

            my $subs;

            # If the year is greater than the era year, or if the year
            # is the same as the era year and we do not know the
            # month, just replace.

            if ($year > $eyear ||
                ($year == $eyear && ! defined ($month))) {
                $subs = 1;
            }

            # If the year is the same, and there is a month

            elsif ($year == $eyear && defined ($month)) {

                # If there is a day of the month, then only substitute
                # if the month is greater than the changeover month,
                # or the month is the same, and the day of the month
                # is greater than or equal to the changeover day of
                # the month.

                if (defined ($date)) {
                    if ($month > $emonth ||
                        ($month == $emonth && $date >= $eday)) {
                        $subs = 1;
                    }
                }

                # If we don't know the day of the month, substitute if
                # the month is greater than or equal to the changeover
                # month.

                elsif ($month >= $emonth) {
                    $subs = 1;
                }
            }
            if ($subs) {

                # Only substitute if we need to.

                if ($original !~ /$ename/) {

                    # The year counting starts from 1, so we add 1 to
                    # the difference.

                    my $hyear = $year - $eyear + 1;
                    $original =~ s/\d+年/$ename${hyear}年/;
                }

                # Don't replace again, stop the loop.

                last;
            }
        }
    }
    my $count = $data->{count};
    $data->{$count} = $original;
    $data->{count}++;

    # This is a tag for substituting with.

    return "#REPLACEME${count}REPLACEME#";
}

# Regularize any small integer Japanese numbers in a piece of text.

sub regjnums
{
    my ($input) = @_;
    $input =~ tr/０-９/0-9/;
    $input =~ s/([$kanjidigits]+)/kanji2number($1)/ge;
    return $input;
}

1;

