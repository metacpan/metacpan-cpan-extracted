package Geography::Country::TZ::Zone;
use strict 'vars';
use vars qw(%loc %rule %map %map2);

my $offset = 0;
while (<DATA>) {
        chomp;
        s/#.*$//;
        next unless (/\S/);
        my @tokens = split(/\s+/);
        if ($tokens[0] eq 'Zone') {
                $loc{$tokens[1]} = $offset;
        }
        if ($tokens[0] eq 'Link') {
                $loc{$tokens[2]} = $loc{$tokens[1]};
        }
        if ($tokens[0] eq 'Rule') {
                $rule{$tokens[1]} ||= $offset;
        }
        $offset = tell(DATA);
}

sub getblock {
        my $zone = shift;
        my $offset = $loc{$zone};
        return undef unless (defined($offset));
        seek(DATA, $offset, 0);
        my @ary;
        while (<DATA>) {
                chop;
                s/#.*$//;
                next unless (/\S/);
                my @tokens = split(/\s+/, $_);
                last if ($tokens[0] eq 'Link'); 
                last if ($tokens[0] eq 'Rule'); 
                if ($tokens[0] eq 'Zone') {
                        last if @ary;
                        shift @tokens;
                        shift @tokens;
                }
                while (@tokens && !$tokens[0]) {
                        shift @tokens;
                }
                next unless (@tokens);
                @tokens = (@tokens[0 .. 3], join(" ", @tokens[4 .. $#tokens]));
                push(@ary, \@tokens);
        }
        @ary;
}
sub conv {
        my $a = shift;
        $a =~ s/^(-?)//;
        my $neg = $1;
        my @tokens = (split(/:/, $a), 0, 0);
        $neg . ($tokens[0] * 60 + $tokens[1]) * 60 + $tokens[2];
}

sub getoffset {
        my $zone = shift;
        my @ary = &getblock($zone);
        return undef unless (@ary);
        my @t = localtime;
        conv($ary[-1]->[0]) + &getsave($ary[-1]->[1],
                $t[3], $t[4] + 1, $t[5] + 1900);
}

@map{qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)} = (1 .. 12);

sub getpastoffset {
        my ($zone, $d, $m, $y) = @_;
        my @ary = &getblock($zone);
	my $def;
        return undef unless (@ary);
	my $policy;
        foreach (@ary) {
                $def = $_->[0];
                $policy = $_->[1];
                my $from = $_->[3];
		next unless ($from);
                my @tokens = split(/\s+/, $from); 
                last if ($tokens[0] > $y);
                last if ($#tokens && $map{$tokens[1]} > $m);
                last if ($#tokens > 1 && $tokens[2] > $d);
        }
        &conv($def) + &getsave($policy, $d, $m, $y);
}

sub getsave {
        my ($cn, $d, $m, $y, $t) = @_;
        return &conv($cn) if ($cn =~ /^[0-9:]+$/);
        my $offset = $rule{$cn};
        return 0 unless ($offset);
        seek(DATA, $offset, 0);
        my $def = 0;
	my $mm;
        $t = &conv($t) if ($t);
        while (<DATA>) {
                chop;
                my @tokens = split(/\s+/);
                last if ($tokens[0] ne 'Rule' || $tokens[1] ne $cn);
                last if ($tokens[2] > $y);
                next if ($tokens[3] =~ /^\d+$/ && $tokens[3]);
                next if ($tokens[3] eq 'only' && $y != $tokens[2]);
                last if (($mm = $map{$tokens[5]}) > $m);
                next if ($m == $mm && &find($tokens[6], $m, $y) > $d);
                $def = $tokens[8];
        }
        &conv($def);
}

@map2{qw(Sun Mon Tue Wed Thu Fri Sat)} = (1 .. 7);

sub find {
        my ($exp, $m, $y) = @_;
        return $exp if ($exp =~ /^\d+$/);
        my $d;
        if ($exp =~ s/^last//) {
                my $l = $map2{$exp};
                my $t = maketime(1, $m, $y);
                for (;;) {
                        my @t = gmtime($t);
                        last if ($t[4] + 1 != $m);
                        $d = $t[3] if ($t[6] + 1 == $l);
                        $t += 3600 * 24;
                }
		return $d;
        }
#	$exp = "$exp>=1" if ($map2{$exp});
        if ($exp =~ s/([<>])\=(\d+)$//) {
                my $val = $2;
                my $neg = ($1 eq "<") ? -1 : 1;
                my $l = $map2{$exp};
                my $t = maketime($val, $m, $y);
                for (;;) {
                        my @t = gmtime($t);
                        return $t[3] if ($t[6] + 1 == $l);
                        $t += 3600 * 24 * $neg;
                }
        }
        die "Unparsable $exp";
}

sub maketime {
        require Time::Local;
        Time::Local::timegm(0, 0, 0, $_[0], $_[1] - 1, $_[2] - 1900);
}

1;
__DATA__

Zone	Africa/Algiers	0:12:12 -	LMT	1891 Mar 15 0:01
			0:09:21	-	PMT	1911 Mar 11    # Paris Mean Time
			0:00	Algeria	WE%sT	1940 Feb 25 2:00
			1:00	Algeria	CE%sT	1946 Oct  7
			0:00	-	WET	1956 Jan 29
			1:00	-	CET	1963 Apr 14
			0:00	Algeria	WE%sT	1977 Oct 21
			1:00	Algeria	CE%sT	1979 Oct 26
			0:00	Algeria	WE%sT	1981 May
			1:00	-	CET

Zone	Africa/Luanda	0:52:56	-	LMT	1892
			0:52:04	-	LMT	1911 May 26 # Luanda Mean Time?
			1:00	-	WAT

Zone Africa/Porto-Novo	0:10:28	-	LMT	1912
			0:00	-	GMT	1934 Feb 26
			1:00	-	WAT

Zone	Africa/Gaborone	1:43:40 -	LMT	1885
			2:00	-	CAT	1943 Sep 19 2:00
			2:00	1:00	CAST	1944 Mar 19 2:00
			2:00	-	CAT

Zone Africa/Ouagadougou	-0:06:04 -	LMT	1912
			 0:00	-	GMT

Zone Africa/Bujumbura	1:57:28	-	LMT	1890
			2:00	-	CAT

Zone	Africa/Douala	0:38:48	-	LMT	1912
			1:00	-	WAT

Zone Atlantic/Cape_Verde -1:34:04 -	LMT	1907			# Praia
			-2:00	-	CVT	1942 Sep
			-2:00	1:00	CVST	1945 Oct 15
			-2:00	-	CVT	1975 Nov 25 2:00
			-1:00	-	CVT

Zone	Africa/Bangui	1:14:20	-	LMT	1912
			1:00	-	WAT

Zone	Africa/Ndjamena	1:00:12 -	LMT	1912
			1:00	-	WAT	1979 Oct 14
			1:00	1:00	WAST	1980 Mar  8
			1:00	-	WAT

Zone	Indian/Comoro	2:53:04 -	LMT	1911 Jul   # Moroni, Gran Comoro
			3:00	-	EAT

Zone Africa/Kinshasa	1:01:12 -	LMT	1897 Nov 9
			1:00	-	WAT
Zone Africa/Lubumbashi	1:49:52 -	LMT	1897 Nov 9
			2:00	-	CAT

Zone Africa/Brazzaville	1:01:08 -	LMT	1912
			1:00	-	WAT

Zone	Africa/Abidjan	-0:16:08 -	LMT	1912
			 0:00	-	GMT

Zone	Africa/Djibouti	2:52:36 -	LMT	1911 Jul
			3:00	-	EAT




Zone	Africa/Cairo	2:05:00 -	LMT	1900 Oct
			2:00	Egypt	EE%sT

Zone	Africa/Malabo	0:35:08 -	LMT	1912
			0:00	-	GMT	1963 Dec 15
			1:00	-	WAT

Zone	Africa/Asmera	2:35:32 -	LMT	1870
			2:35:32	-	AMT	1890	      # Asmera Mean Time
			2:35:20	-	ADMT	1936 May 5    # Adis Dera MT
			3:00	-	EAT

Zone Africa/Addis_Ababa	2:34:48 -	LMT	1870
			2:35:20	-	ADMT	1936 May 5    # Adis Dera MT
			3:00	-	EAT

Zone Africa/Libreville	0:37:48 -	LMT	1912
			1:00	-	WAT

Zone	Africa/Banjul	-1:06:36 -	LMT	1912
			-1:06:36 -	BMT	1935	# Banjul Mean Time
			-1:00	-	WAT	1964
			 0:00	-	GMT

Zone	Africa/Accra	-0:00:52 -	LMT	1918
			 0:00	Ghana	%s

Zone	Africa/Conakry	-0:54:52 -	LMT	1912
			 0:00	-	GMT	1934 Feb 26
			-1:00	-	WAT	1960
			 0:00	-	GMT

Zone	Africa/Bissau	-1:02:20 -	LMT	1911 May 26
			-1:00	-	WAT	1975
			 0:00	-	GMT

Zone	Africa/Nairobi	2:27:16	-	LMT	1928 Jul
			3:00	-	EAT	1930
			2:30	-	BEAT	1940
			2:45	-	BEAUT	1960
			3:00	-	EAT

Zone	Africa/Maseru	1:50:00 -	LMT	1903 Mar
			2:00	-	SAST	1943 Sep 19 2:00
			2:00	1:00	SAST	1944 Mar 19 2:00
			2:00	-	SAST

Zone	Africa/Monrovia	-0:43:08 -	LMT	1882
			-0:43:08 -	MMT	1919 Mar # Monrovia Mean Time
			-0:44:30 -	LRT	1972 May # Liberia Time
			 0:00	-	GMT



Zone	Africa/Tripoli	0:52:44 -	LMT	1920
			1:00	Libya	CE%sT	1959
			2:00	-	EET	1982
			1:00	Libya	CE%sT	1990 May  4
			2:00	-	EET	1996 Sep 30
			1:00	-	CET	1997 Apr  4
			1:00	1:00	CEST	1997 Oct  4
			2:00	-	EET

Zone Indian/Antananarivo 3:10:04 -	LMT	1911 Jul
			3:00	-	EAT	1954 Feb 27 23:00s
			3:00	1:00	EAST	1954 May 29 23:00s
			3:00	-	EAT

Zone	Africa/Blantyre	2:20:00 -	LMT	1903 Mar
			2:00	-	CAT

Zone	Africa/Bamako	-0:32:00 -	LMT	1912
			 0:00	-	GMT	1934 Feb 26
			-1:00	-	WAT	1960 Jun 20
			 0:00	-	GMT
Zone	Africa/Timbuktu	-0:12:04 -	LMT	1912
			 0:00	-	GMT

Zone Africa/Nouakchott	-1:03:48 -	LMT	1912
			 0:00	-	GMT	1934 Feb 26
			-1:00	-	WAT	1960 Nov 28
			 0:00	-	GMT

Zone Indian/Mauritius	3:50:00 -	LMT	1907		# Port Louis
			4:00	-	MUT	# Mauritius Time

Zone	Indian/Mayotte	3:00:56 -	LMT	1911 Jul	# Mamoutzou
			3:00	-	EAT

Zone Africa/Casablanca	-0:30:20 -	LMT	1913 Oct 26
			 0:00	Morocco	WE%sT	1984 Mar 16
			 1:00	-	CET	1986
			 0:00	-	WET
Zone Africa/El_Aaiun	-0:52:48 -	LMT	1934 Jan
			-1:00	-	WAT	1976 Apr 14
			 0:00	-	WET

Zone	Africa/Maputo	2:10:20 -	LMT	1903 Mar
			2:00	-	CAT

Zone	Africa/Windhoek	1:08:24 -	LMT	1892 Feb 8
			1:30	-	SWAT	1903 Mar	# SW Africa Time
			2:00	-	SAST	1942 Sep 20 2:00
			2:00	1:00	SAST	1943 Mar 21 2:00
			2:00	-	SAST	1990 Mar 21 # independence
			2:00	-	CAT	1994 Apr  3
			1:00	Namibia	WA%sT

Zone	Africa/Niamey	 0:08:28 -	LMT	1912
			-1:00	-	WAT	1934 Feb 26
			 0:00	-	GMT	1960
			 1:00	-	WAT

Zone	Africa/Lagos	0:13:36 -	LMT	1919 Sep
			1:00	-	WAT

Zone	Indian/Reunion	3:41:52 -	LMT	1911 Jun	# Saint-Denis
			4:00	-	RET	# Reunion Time

Zone	Africa/Kigali	2:00:16 -	LMT	1935 Jun
			2:00	-	CAT

Zone Atlantic/St_Helena	-0:22:48 -	LMT	1890		# Jamestown
			-0:22:48 -	JMT	1951	# Jamestown Mean Time
			 0:00	-	GMT

Zone	Africa/Sao_Tome	 0:26:56 -	LMT	1884
			-0:36:32 -	LMT	1912	# Lisbon Mean Time
			 0:00	-	GMT

Zone	Africa/Dakar	-1:09:44 -	LMT	1912
			-1:00	-	WAT	1941 Jun
			 0:00	-	GMT

Zone	Indian/Mahe	3:41:48 -	LMT	1906 Jun	# Victoria
			4:00	-	SCT	# Seychelles Time

Zone	Africa/Freetown	-0:53:00 -	LMT	1882
			-0:53:00 -	FMT	1913 Jun # Freetown Mean Time
			-1:00	SL	%s	1957
			 0:00	SL	%s

Zone Africa/Mogadishu	3:01:28 -	LMT	1893 Nov
			3:00	-	EAT	1931
			2:30	-	BEAT	1957
			3:00	-	EAT

Zone Africa/Johannesburg 1:52:00 -	LMT	1892 Feb 8
			1:30	-	SAST	1903 Mar
			2:00	SA	SAST

Zone	Africa/Khartoum	2:10:08 -	LMT	1931
			2:00	Sudan	CA%sT	2000 Jan 15 12:00
			3:00	-	EAT

Zone	Africa/Mbabane	2:04:24 -	LMT	1903 Mar
			2:00	-	SAST

Zone Africa/Dar_es_Salaam 2:37:08 -	LMT	1931
			3:00	-	EAT	1948
			2:45	-	BEAUT	1961
			3:00	-	EAT

Zone	Africa/Lome	0:04:52 -	LMT	1893
			0:00	-	GMT

Zone	Africa/Tunis	0:40:44 -	LMT	1881 May 12
			0:09:21	-	PMT	1911 Mar 11    # Paris Mean Time
			1:00	Tunisia	CE%sT

Zone	Africa/Kampala	2:09:40 -	LMT	1928 Jul
			3:00	-	EAT	1930
			2:30	-	BEAT	1948
			2:45	-	BEAUT	1957
			3:00	-	EAT

Zone	Africa/Lusaka	1:53:08 -	LMT	1903 Mar
			2:00	-	CAT

Zone	Africa/Harare	2:04:12 -	LMT	1903 Mar
			2:00	-	CAT





Zone Antarctica/Casey	0	-	___	1969
			8:00	-	WST	# Western (Aus) Standard Time
Zone Antarctica/Davis	0	-	___	1957 Jan 13
			7:00	-	DAVT	1964 Nov # Davis Time
			0	-	___	1969 Feb
			7:00	-	DAVT
Zone Antarctica/Mawson	0	-	___	1954 Feb 13
			6:00	-	MAWT	# Mawson Time




Zone Indian/Kerguelen	0	-	___	1950	# Port-aux-Francais
			5:00	-	TFT	# ISO code TF Time
Zone Antarctica/DumontDUrville 0 -	___	1947
			10:00	-	PMT	1952 Jan 14 # Port-Martin Time
			0	-	___	1956 Nov
			10:00	-	DDUT	# Dumont-d'Urville Time




Zone Antarctica/Syowa	0	-	___	1957 Jan 29
			3:00	-	SYOT	# Syowa Time









Zone Antarctica/Palmer	0	-	___	1965
			-4:00	ArgAQ	AR%sT	1969 Oct 5
			-3:00	ArgAQ	AR%sT	1982 May
			-4:00	ChileAQ	CL%sT
Zone Antarctica/McMurdo	0	-	___	1956
			12:00	NZAQ	NZ%sT






Zone	Asia/Kabul	4:36:48 -	LMT	1890
			4:00	-	AFT	1945
			4:30	-	AFT

Zone	Asia/Yerevan	2:58:00 -	LMT	1924 May  2
			3:00	-	YERT	1957 Mar    # Yerevan Time
			4:00 RussiaAsia YER%sT	1991 Mar 31 2:00s
			3:00	1:00	YERST	1991 Sep 23 # independence
			3:00 RussiaAsia	AM%sT	1995 Sep 24 2:00s
			4:00	-	AMT	1997
			4:00 RussiaAsia	AM%sT			

Zone	Asia/Baku	3:19:24 -	LMT	1924 May  2
			3:00	-	BAKT	1957 Mar    # Baku Time
			4:00 RussiaAsia BAK%sT	1991 Mar 31 2:00s
			3:00	1:00	BAKST	1991 Aug 30 # independence
			3:00 RussiaAsia	AZ%sT	1992 Sep lastSun 2:00s
			4:00	-	AZT	1996 # Azerbaijan time
			4:00	EUAsia	AZ%sT	1997
			4:00	Azer	AZ%sT

Zone	Asia/Bahrain	3:22:20 -	LMT	1920		# Al Manamah
			4:00	-	GST	1972 Jun
			3:00	-	AST

Zone	Asia/Dhaka	6:01:40 -	LMT	1890
			5:53:20	-	HMT	1941 Oct    # Howrah Mean Time?
			6:30	-	BURT	1942 May 15 # Burma Time
			5:30	-	IST	1942 Sep
			6:30	-	BURT	1951 Sep 30
			6:00	-	DACT	1971 Mar 26 # Dacca Time
			6:00	-	BDT	# Bangladesh Time

Zone	Asia/Thimphu	5:58:36 -	LMT	1947 Aug 15 # or Thimbu
			5:30	-	IST	1987 Oct
			6:00	-	BTT	# Bhutan Time

Zone	Indian/Chagos	5:00	-	IOT	# BIOT Time

Zone	Asia/Brunei	7:39:40 -	LMT	1926 Mar   # Bandar Seri Begawan
			7:30	-	BNT	1933
			8:00	-	BNT

Zone	Asia/Rangoon	6:24:40 -	LMT	1880		# or Yangon
			6:24:36	-	RMT	1920	   # Rangoon Mean Time?
			6:30	-	BURT	1942 May   # Burma Time
			9:00	-	JST	1945 May 3
			6:30	-	MMT		   # Myanmar Time

Zone	Asia/Phnom_Penh	6:59:40 -	LMT	1906 Jun  9
			7:06:20	-	SMT	1911 Mar 11 0:01 # Saigon MT?
			7:00	-	ICT	1912 May
			8:00	-	ICT	1931 May
			7:00	-	ICT






Zone	Asia/Harbin	8:26:44	-	LMT	1928 # or Haerbin
			8:30	-	HART	1932 Mar # Harbin Time
			8:00	-	CST	1940
			9:00	-	HART	1966 May
			8:30	-	HART	1980 May
			8:00	PRC	C%sT
Zone	Asia/Shanghai	8:05:52	-	LMT	1928
			8:00	Shang	C%sT	1949
			8:00	PRC	C%sT
Zone	Asia/Chungking	7:06:20	-	LMT	1928 # or Chongqing
			7:00	-	CHUT	1980 May # Chungking Time
			8:00	PRC	C%sT
Zone	Asia/Urumqi	5:50:20	-	LMT	1928 # or Urumchi
			6:00	-	URUT	1980 May # Urumqi Time
			8:00	PRC	C%sT
Zone	Asia/Kashgar	5:03:56	-	LMT	1928 # or Kashi or Kaxgar
			5:30	-	KAST	1940	 # Kashgar Time
			5:00	-	KAST	1980 May
			8:00	PRC	C%sT
Zone	Asia/Hong_Kong	7:36:36 -	LMT	1904 Oct 30
			8:00	HK	HK%sT





Zone	Asia/Taipei	8:06:00 -	LMT	1896
			8:00	Taiwan	C%sT

Zone	Asia/Macao	7:34:20 -	LMT	1912
			8:00	Macao	MO%sT	1999 Dec 20 # return to China
			8:00	PRC	C%sT



Zone	Asia/Nicosia	2:13:28 -	LMT	1921 Nov 14
			2:00	Cyprus	EE%sT	1998 Sep
			2:00	EUAsia	EE%sT


Zone	Asia/Tbilisi	2:59:16 -	LMT	1880
			2:59:16	-	TBMT	1924 May  2 # Tbilisi Mean Time
			3:00	-	TBIT	1957 Mar    # Tbilisi Time
			4:00 RussiaAsia TBI%sT	1991 Mar 31 2:00s
			3:00	1:00	TBIST	1991 Apr  9 # independence
			3:00 RussiaAsia GE%sT	1992 # Georgia Time
			3:00 E-EurAsia	GE%sT	1994 Sep lastSun
			4:00 E-EurAsia	GE%sT	1996 Oct lastSun
			4:00	1:00	GEST	1997 Mar lastSun
			4:00 E-EurAsia	GE%sT





Zone	Asia/Dili	8:22:20 -	LMT	1912
			8:00	-	TPT	1942 Feb 21 23:00 # E Timor Time
			9:00	-	JST	1945 Aug
			9:00	-	TPT	1976 May  3
			8:00	-	TPT	2000 Sep 17 00:00
			9:00	-	TPT

Zone	Asia/Calcutta	5:53:28 -	LMT	1880
			5:53:20	-	HMT	1941 Oct    # Howrah Mean Time?
			6:30	-	BURT	1942 May 15 # Burma Time
			5:30	-	IST	1942 Sep
			5:30	1:00	IST	1945 Oct 15
			5:30	-	IST

Zone Asia/Jakarta	7:07:12 -	LMT	1867 Aug 10
			7:07:12	-	JMT	1923 Dec 31 23:47:12 # Jakarta
			7:20	-	JAVT	1932 Nov	 # Java Time
			7:30	-	JAVT	1942 Mar 23
			9:00	-	JST	1945 Aug
			7:30	-	JAVT	1948 May
			8:00	-	JAVT	1950 May
			7:30	-	JAVT	1964
			7:00	-	JAVT
Zone Asia/Ujung_Pandang 7:57:36 -	LMT	1920
			7:57:36	-	MMT	1932 Nov    # Macassar MT
			8:00	-	BORT	1942 Feb  9 # Borneo Time
			9:00	-	JST	1945 Aug
			8:00	-	BORT
Zone Asia/Jayapura	9:22:48 -	LMT	1932 Nov
			9:00	-	JAYT	1944	    # Jayapura Time
			9:30	-	CST	1964
			9:00	-	JAYT

Zone	Asia/Tehran	3:25:44	-	LMT	1916
			3:25:44	-	TMT	1946	# Tehran Mean Time
			3:30	-	IRT	1977 Nov
			4:00	Iran	IR%sT	1979
			3:30	Iran	IR%sT



Zone	Asia/Baghdad	2:57:40	-	LMT	1890
			2:57:36	-	BMT	1918	    # Baghdad Mean Time?
			3:00	-	AST	1982 May
			3:00	Iraq	A%sT
















Zone	Asia/Jerusalem	2:20:56 -	LMT	1880
			2:20:40	-	JMT	1918	# Jerusalem Mean Time?
			2:00	Zion	I%sT









Zone	Asia/Tokyo	9:18:59	-	LMT	1887 Dec 31 15:00u
			9:00	-	JST	1896
			9:00	-	CJT	1938
			9:00	-	JST

Zone	Asia/Amman	2:23:44 -	LMT	1931
			2:00	Jordan	EE%sT

Zone	Asia/Almaty	5:07:48 -	LMT	1924 May  2 # or Alma-Ata
			5:00	-	ALMT	1957 Mar # Alma-Ata Time
			6:00 RussiaAsia ALM%sT	1991 Mar 31 2:00s
			5:00	1:00	ALMST	1991 Sep 29 2:00s
			5:00	-	ALMT	1992 Jan 19 2:00s
			6:00 E-EurAsia	ALM%sT
Zone	Asia/Aqtobe	3:48:40	-	LMT	1924 May  2
			4:00	-	AKT	1957 Mar # Aktyubinsk Time
			5:00 RussiaAsia AK%sT	1991 Mar 31 2:00s
			4:00	1:00	AKTST	1991 Sep 29 2:00s
			4:00	-	AQTT	1992 Jan 19 2:00s # Aqtobe Time
			5:00 E-EurAsia	AQT%sT
Zone	Asia/Aqtau	3:21:04	-	LMT	1924 May  2 # or Aktau
			4:00	-	SHET	1957 Mar # Fort Shevchenko Time
			5:00 RussiaAsia SHE%sT	1991 Mar 31 2:00s
			4:00	1:00	AQTST	1991 Sep 29 2:00s
			4:00	-	AQTT	1992 Jan 19 2:00s # Aqtau Time
			5:00 E-EurAsia	AQT%sT	1995 Sep lastSun
			4:00 E-EurAsia	AQT%sT

Zone	Asia/Bishkek	4:58:24 -	LMT	1924 May  2
			5:00	-	FRUT	1930 Jun 21 # Frunze Time
			6:00 RussiaAsia FRU%sT	1991 Mar 31 2:00s
			5:00	1:00	FRUST	1991 Aug 31 2:00 # independence
			5:00	Kirgiz	KG%sT		    # Kirgizstan Time





Zone	Asia/Seoul	8:27:52	-	LMT	1890
			8:30	-	KST	1904 Dec
			9:00	-	KST	1928
			8:30	-	KST	1932
			9:00	-	KST	1954 Mar 21
			8:00	ROK	K%sT	1961 Aug 10
			8:30	-	KST	1968 Oct
			9:00	ROK	K%sT
Zone	Asia/Pyongyang	8:23:00 -	LMT	1890
			8:30	-	KST	1904 Dec
			9:00	-	KST	1928
			8:30	-	KST	1932
			9:00	-	KST	1954 Mar 21
			8:00	-	KST	1961 Aug 10
			9:00	-	KST


Zone	Asia/Kuwait	3:11:56 -	LMT	1950
			3:00	-	AST

Zone	Asia/Vientiane	6:50:24 -	LMT	1906 Jun  9 # or Viangchan
			7:06:20	-	SMT	1911 Mar 11 0:01 # Saigon MT?
			7:00	-	ICT	1912 May
			8:00	-	ICT	1931 May
			7:00	-	ICT

Zone	Asia/Beirut	2:22:00 -	LMT	1880
			2:00	Lebanon	EE%sT

Zone Asia/Kuala_Lumpur	6:46:48 -	LMT	1880
			6:55:24	-	SMT	1905 Jun # Singapore Mean Time
			7:00	-	MALT	1933	 # Malaya Time
			7:20	-	MALT	1942 Feb 15
			9:00	-	JST	1945 Sep 2
			7:20	-	MALT	1950
			7:30	-	MALT	1982 May
			8:00	-	MYT	# Malaysia Time
Zone Asia/Kuching	7:21:20	-	LMT	1926 Mar
			7:30	-	BORT	1933	# Borneo Time
			8:00	NBorneo	BOR%sT	1942
			9:00	-	JST	1945 Sep 2
			8:00	-	BORT	1982 May
			8:00	-	MYT

Zone	Indian/Maldives	4:54:00 -	LMT	1880	# Male
			4:54:00	-	MMT	1960	# Male Mean Time
			5:00	-	MVT		# Maldives Time







Zone	Asia/Hovd	6:06:36 -	LMT	1905 Aug
			6:00	-	HOVT	1978	# Hovd Time
			7:00	Mongol	HOV%sT
Zone	Asia/Ulaanbaatar 7:07:32 -	LMT	1905 Aug
			7:00	-	ULAT	1978	# Ulaanbaatar Time
			8:00	Mongol	ULA%sT

Zone	Asia/Katmandu	5:41:16 -	LMT	1920
			5:30	-	IST	1986
			5:45	-	NPT	# Nepal Time

Zone	Asia/Muscat	3:54:20 -	LMT	1920
			4:00	-	GST

Zone	Asia/Karachi	4:28:12 -	LMT	1907
			5:30	-	IST	1942 Sep
			5:30	1:00	IST	1945 Oct 15
			5:30	-	IST	1951 Sep 30
			5:00	-	KART	1971 Mar 26 # Karachi Time
			5:00	-	PKT	# Pakistan Time








Zone	Asia/Gaza	2:17:52	-	LMT	1900 Oct
			2:00	Zion	EET	1948 May 15
			2:00 EgyptAsia	EE%sT	1967 Jun  5
			2:00	Zion	I%sT	1996
			2:00	Jordan	EE%sT	1999
			2:00 Palestine	EE%sT


Zone	Asia/Manila	-15:56:00 -	LMT	1844
			8:04:00 -	LMT	1899 May 11
			8:00	Phil	PH%sT	1942 May
			9:00	-	JST	1944 Nov
			8:00	Phil	PH%sT

Zone	Asia/Qatar	3:26:08 -	LMT	1920	# Al Dawhah / Doha
			4:00	-	GST	1972 Jun
			3:00	-	AST

Zone	Asia/Riyadh	3:06:52 -	LMT	1950
			3:00	-	AST

Zone	Asia/Singapore	6:55:24 -	LMT	1880
			6:55:24	-	SMT	1905 Jun # Singapore Mean Time
			7:00	-	MALT	1933	 # Malaya Time
			7:20	-	MALT	1942 Feb 15
			9:00	-	JST	1945 Sep  2
			7:20	-	MALT	1950
			7:30	-	MALT	1965 Aug  9 # independence
			7:30	-	SGT	1982 May # Singapore Time
			8:00	-	SGT



Zone	Asia/Colombo	5:19:24 -	LMT	1880
			5:19:32	-	MMT	1906	# Moratuwa Mean Time
			5:30	-	IST	1942 Jan  5
			5:30	0:30	IHST	1942 Sep
			5:30	1:00	IST	1945 Oct 16 2:00
			5:30	-	IST	1996 May 25 0:00
			6:30	-	LKT	1996 Oct 26 0:30
			6:00	-	LKT

Zone	Asia/Damascus	2:25:12 -	LMT	1920	# Dimashq
			2:00	Syria	EE%sT

Zone	Asia/Dushanbe	4:35:12 -	LMT	1924 May  2
			5:00	-	DUST	1930 Jun 21 # Dushanbe Time
			6:00 RussiaAsia DUS%sT	1991 Mar 31 2:00s
			5:00	1:00	DUSST	1991 Sep  9 2:00s
			5:00	-	TJT		    # Tajikistan Time

Zone	Asia/Bangkok	6:42:04	-	LMT	1880
			6:42:04	-	BMT	1920 Apr # Bangkok Mean Time
			7:00	-	ICT

Zone	Asia/Ashgabat	3:53:32 -	LMT	1924 May  2 # or Ashkhabad
			4:00	-	ASHT	1930 Jun 21 # Ashkhabad Time
			5:00 RussiaAsia	ASH%sT	1991 Mar 31 2:00
			4:00 RussiaAsia	ASH%sT	1991 Oct 27 # independence
			4:00 RussiaAsia TM%sT	1992 Jan 19 2:00
			5:00	-	TMT

Zone	Asia/Dubai	3:41:12 -	LMT	1920
			4:00	-	GST

Zone	Asia/Samarkand	4:27:12 -	LMT	1924 May  2
			4:00	-	SAMT	1930 Jun 21 # Samarkand Time
			5:00	-	SAMT	1981 Apr  1
			5:00	1:00	SAMST	1981 Oct  1
			6:00 RussiaAsia TAS%sT	1991 Mar 31 2:00 # Tashkent Time
			5:00 RussiaAsia	TAS%sT	1991 Sep  1 # independence
			5:00 RussiaAsia	UZ%sT	1992
			5:00 RussiaAsia	UZ%sT	1993
			5:00	-	UZT
Zone	Asia/Tashkent	4:37:12 -	LMT	1924 May  2
			5:00	-	TAST	1930 Jun 21 # Tashkent Time
			6:00 RussiaAsia TAS%sT	1991 Mar 31 2:00s
			5:00 RussiaAsia	TAS%sT	1991 Sep  1 # independence
			5:00 RussiaAsia	UZ%sT	1992
			5:00 RussiaAsia	UZ%sT	1993
			5:00	-	UZT

Zone	Asia/Saigon	7:06:40 -	LMT	1906 Jun  9
			7:06:20	-	SMT	1911 Mar 11 0:01 # Saigon MT?
			7:00	-	ICT	1912 May
			8:00	-	ICT	1931 May
			7:00	-	ICT

Zone	Asia/Aden	3:00:48	-	LMT	1950
			3:00	-	AST





Zone Australia/Darwin	 8:43:20 -	LMT	1895 Feb
			 9:00	-	CST	1899 May
			 9:30	Aus	CST
Zone Australia/Perth	 7:43:24 -	LMT	1895 Dec
			 8:00	Aus	WST	1943 Jul
			 8:00	-	WST	1974 Oct lastSun 2:00s
			 8:00	1:00	WST	1975 Mar Sun>=1 2:00s
			 8:00	-	WST	1983 Oct lastSun 2:00s
			 8:00	1:00	WST	1984 Mar Sun>=1 2:00s
			 8:00	-	WST	1991 Nov 17 2:00s
			 8:00	1:00	WST	1992 Mar Sun>=1 2:00s
			 8:00	-	WST
Zone Australia/Brisbane	10:12:08 -	LMT	1895
			10:00	Aus	EST	1971
			10:00	AQ	EST
Zone Australia/Lindeman  9:55:56 -	LMT	1895
			10:00	Aus	EST	1971
			10:00	AQ	EST	1992 Jul
			10:00	Holiday	EST

Zone Australia/Adelaide	9:14:20 -	LMT	1895 Feb
			9:00	-	CST	1899 May
			9:30	Aus	CST	1971
			9:30	AS	CST

Zone Australia/Hobart	9:49:16	-	LMT	1895 Sep
			10:00	-	EST	1916 Oct 1 2:00
			10:00	1:00	EST	1917 Feb
			10:00	Aus	EST	1967
			10:00	AT	EST

Zone Australia/Melbourne 9:39:52 -	LMT	1895 Feb
			10:00	Aus	EST	1971
			10:00	AV	EST

Zone Australia/Sydney	10:04:52 -	LMT	1895 Feb
			10:00	Aus	EST	1971
			10:00	AN	EST
Zone Australia/Broken_Hill 9:25:48 -	LMT	1895 Feb
			10:00	-	EST	1896 Aug 23
			9:00	-	CST	1899 May
			9:30	Aus	CST	1971
			9:30	AN	CST	2000
			9:30	AS	CST

Zone Australia/Lord_Howe 10:36:20 -	LMT	1895 Feb
			10:00	-	EST	1981 Mar
			10:30	LH	LHST


Zone Indian/Christmas	7:02:52 -	LMT	1895 Feb
			7:00	-	CXT	# Christmas Island Time

Zone Pacific/Rarotonga	-10:39:04 -	LMT	1901		# Avarua
			-10:30	-	CKT	1978 Nov 12	# Cook Is Time
			-10:00	Cook	CK%sT

Zone	Indian/Cocos	6:30	-	CCT	# Cocos Islands Time

Zone	Pacific/Fiji	11:53:40 -	LMT	1915 Oct 26	# Suva
			12:00	Fiji	FJ%sT	# Fiji Time

Zone	Pacific/Gambier	 -8:59:48 -	LMT	1912 Oct	# Rikitea
			 -9:00	-	GAMT	# Gambier Time
Zone	Pacific/Marquesas -9:18:00 -	LMT	1912 Oct
			 -9:30	-	MART	# Marquesas Time
Zone	Pacific/Tahiti	 -9:58:16 -	LMT	1912 Oct	# Papeete
			-10:00	-	TAHT	# Tahiti Time

Zone	Pacific/Guam	 9:39:00 -	LMT	1901		# Agana
			10:00	-	GST

Zone Pacific/Tarawa	 11:32:04 -	LMT	1901		# Bairiki
			 12:00	-	GILT		 # Gilbert Is Time
Zone Pacific/Enderbury	-11:24:20 -	LMT	1901
			-12:00	-	PHOT	1979 Oct # Phoenix Is Time
			-11:00	-	PHOT	1995
			 13:00	-	PHOT
Zone Pacific/Kiritimati	-10:29:20 -	LMT	1901
			-10:40	-	LINT	1979 Oct # Line Is Time
			-10:00	-	LINT	1995
			 14:00	-	LINT

Zone Pacific/Saipan	 9:43:00 -	LMT	1901
			 9:00	-	MPT	1969 Oct # N Mariana Is Time
			10:00	-	MPT

Zone Pacific/Majuro	11:24:48 -	LMT	1901
			11:00	-	MHT	1969 Oct # Marshall Islands Time
			12:00	-	MHT
Zone Pacific/Kwajalein	11:09:20 -	LMT	1901
			11:00	-	MHT	1969 Oct
			-12:00	-	KWAT	1993 Aug 20	# Kwajalein Time
			12:00	-	MHT

Zone Pacific/Yap	9:12:32	-	LMT	1901		# Colonia
			9:00	-	YAPT	1969 Oct	# Yap Time
			10:00	-	YAPT
Zone Pacific/Truk	10:07:08 -	LMT	1901
			10:00	-	TRUT			# Truk Time
Zone Pacific/Ponape	10:32:52 -	LMT	1901		# Kolonia
			11:00	-	PONT			# Ponape Time
Zone Pacific/Kosrae	10:51:56 -	LMT	1901
			11:00	-	KOST	1969 Oct	# Kosrae Time
			12:00	-	KOST	1999
			11:00	-	KOST

Zone	Pacific/Nauru	11:07:40 -	LMT	1921 Jan 15	# Uaobe
			11:30	-	NRT	1942 Mar 15	# Nauru Time
			9:00	-	JST	1944 Aug 15
			11:30	-	NRT	1979 May
			12:00	-	NRT

Zone	Pacific/Noumea	11:05:48 -	LMT	1912 Jan 13
			11:00	NC	NC%sT




Zone Pacific/Auckland	11:39:04 -	LMT	1868
			11:30	NZ	NZ%sT	1940 Sep 29 2:00
			12:00	NZ	NZ%sT
Zone Pacific/Chatham	12:45	Chatham	CHA%sT






Zone	Pacific/Niue	-11:19:40 -	LMT	1901		# Alofi
			-11:20	-	NUT	1951	# Niue Time
			-11:30	-	NUT	1978 Oct 1
			-11:00	-	NUT

Zone	Pacific/Norfolk	11:11:52 -	LMT	1901		# Kingston
			11:12	-	NMT	1951	# Norfolk Mean Time
			11:30	-	NFT		# Norfolk Time

Zone Pacific/Palau	8:57:56 -	LMT	1901		# Koror
			9:00	-	PWT	# Palau Time

Zone Pacific/Port_Moresby 9:48:40 -	LMT	1880
			9:48:40	-	PMMT	1895	# Port Moresby Mean Time
			10:00	-	PGT		# Papua New Guinea Time

Zone Pacific/Pitcairn	-8:40:20 -	LMT	1901		# Adamstown
			-8:30	-	PNT	1998 Apr 27 00:00
			-8:00	-	PST	# Pitcairn Standard Time

Zone Pacific/Pago_Pago	 12:37:12 -	LMT	1879 Jul  5
			-11:22:48 -	LMT	1911
			-11:30	-	SAMT	1950		# Samoa Time
			-11:00	-	NST	1967 Apr	# N=Nome
			-11:00	-	BST	1983 Nov 30	# B=Bering
			-11:00	-	SST			# S=Samoa

Zone Pacific/Apia	 12:33:04 -	LMT	1879 Jul  5
			-11:26:56 -	LMT	1911
			-11:30	-	SAMT	1950		# Samoa Time
			-11:00	-	WST			# W Samoa Time

Zone Pacific/Guadalcanal 10:39:48 -	LMT	1912 Oct	# Honiara
			11:00	-	SBT	# Solomon Is Time

Zone	Pacific/Fakaofo	-11:24:56 -	LMT	1901
			-10:00	-	TKT	# Tokelau Time

Zone Pacific/Tongatapu	12:19:20 -	LMT	1901
			12:20	-	TOT	1941 # Tonga Time
			13:00	-	TOT	1999
			13:00	Tonga	TO%sT

Zone Pacific/Funafuti	11:56:52 -	LMT	1901
			12:00	-	TVT	# Tuvalu Time





Zone Pacific/Johnston	-10:00	-	HST


Zone Pacific/Midway	-11:49:28 -	LMT	1901
			-11:00	-	NST	1967 Apr	# N=Nome
			-11:00	-	BST	1983 Nov 30	# B=Bering
			-11:00	-	SST			# S=Samoa


Zone	Pacific/Wake	11:06:28 -	LMT	1901
			12:00	-	WAKT	# Wake Time


Zone	Pacific/Efate	11:13:16 -	LMT	1912 Jan 13		# Vila
			11:00	Vanuatu	VU%sT	# Vanuatu Time

Zone	Pacific/Wallis	12:15:20 -	LMT	1901
			12:00	-	WFT	# Wallis & Futuna Time

















































































































Zone	Etc/GMT		0	-	GMT
Zone	Etc/UTC		0	-	UTC
Zone	Etc/UCT		0	-	UCT


Zone	Etc/GMT-14	14	-	GMT-14	# 14 hours ahead of GMT
Zone	Etc/GMT-13	13	-	GMT-13
Zone	Etc/GMT-12	12	-	GMT-12
Zone	Etc/GMT-11	11	-	GMT-11
Zone	Etc/GMT-10	10	-	GMT-10
Zone	Etc/GMT-9	9	-	GMT-9
Zone	Etc/GMT-8	8	-	GMT-8
Zone	Etc/GMT-7	7	-	GMT-7
Zone	Etc/GMT-6	6	-	GMT-6
Zone	Etc/GMT-5	5	-	GMT-5
Zone	Etc/GMT-4	4	-	GMT-4
Zone	Etc/GMT-3	3	-	GMT-3
Zone	Etc/GMT-2	2	-	GMT-2
Zone	Etc/GMT-1	1	-	GMT-1
Zone	Etc/GMT+1	-1	-	GMT+1
Zone	Etc/GMT+2	-2	-	GMT+2
Zone	Etc/GMT+3	-3	-	GMT+3
Zone	Etc/GMT+4	-4	-	GMT+4
Zone	Etc/GMT+5	-5	-	GMT+5
Zone	Etc/GMT+6	-6	-	GMT+6
Zone	Etc/GMT+7	-7	-	GMT+7
Zone	Etc/GMT+8	-8	-	GMT+8
Zone	Etc/GMT+9	-9	-	GMT+9
Zone	Etc/GMT+10	-10	-	GMT+10
Zone	Etc/GMT+11	-11	-	GMT+11
Zone	Etc/GMT+12	-12	-	GMT+12

























Zone	Europe/London	-0:01:15 -	LMT	1847 Dec  1
			 0:00	GB-Eire	%s	1968 Oct 27
			 1:00	-	BST	1971 Oct 31 2:00u
			 0:00	GB-Eire	%s	1996
			 0:00	EU	GMT/BST
Zone	Europe/Belfast	-0:23:40 -	LMT	1880 Aug  2
			-0:25:21 -	DMT	1916 May 21 2:00    # Dublin MT
			-0:25:21 1:00	IST	1916 Oct  1 2:00s   # Irish Summer Time
			 0:00	GB-Eire	%s	1968 Oct 27
			 1:00	-	BST	1971 Oct 31 2:00u
			 0:00	GB-Eire	%s	1996
			 0:00	EU	GMT/BST
Zone	Europe/Dublin	-0:25:21 -	LMT	1880 Aug  2
			-0:25:21 -	DMT	1916 May 21 2:00    # Dublin MT
			-0:25:21 1:00	IST	1916 Oct  1 2:00s
			 0:00	GB-Eire	%s	1921 Dec  6 # independence
			 0:00	GB-Eire	GMT/IST	1940 Feb 25 2:00
			 0:00	1:00	IST	1946 Oct  6 2:00
			 0:00	-	GMT	1947 Mar 16 2:00
			 0:00	1:00	IST	1947 Nov  2 2:00
			 0:00	-	GMT	1948 Apr 18 2:00
			 0:00	GB-Eire	GMT/IST	1968 Oct 27
			 1:00	-	IST	1971 Oct 31 2:00u
			 0:00	GB-Eire	GMT/IST	1996
			 0:00	EU	GMT/IST










Zone	WET		0:00	EU	WE%sT
Zone	CET		1:00	C-Eur	CE%sT
Zone	MET		1:00	C-Eur	ME%sT
Zone	EET		2:00	EU	EE%sT




Zone	Europe/Tirane	1:19:20 -	LMT	1914
			1:00	-	CET	1940 Jun 16
			1:00	Albania	CE%sT	1984 Jul
			1:00	EU	CE%sT

Zone	Europe/Andorra	0:06:04 -	LMT	1901
			0:00	-	WET	1946 Sep 30
			1:00	-	CET	1985 Mar 31 2:00
			1:00	EU	CE%sT

Zone	Europe/Vienna	1:05:20 -	LMT	1893 Apr
			1:00	C-Eur	CE%sT	1918 Jun 16 3:00
			1:00	Austria	CE%sT	1940 Apr  1 2:00
			1:00	C-Eur	CE%sT	1945 Apr  2 2:00
			1:00	Austria	CE%sT	1981
			1:00	EU	CE%sT

Zone	Europe/Minsk	1:50:16 -	LMT	1880
			1:50	-	MMT	1924 May 2 # Minsk Mean Time
			2:00	-	EET	1930 Jun 21
			3:00	-	MSK	1941 Jun 28
			1:00	C-Eur	CE%sT	1944 Jul  3
			3:00	Russia	MSK/MSD	1990
			3:00	-	MSK	1991 Mar 31 2:00s
			2:00	1:00	EEST	1991 Sep 29 2:00s
			2:00	-	EET	1992 Mar 29 0:00s
			2:00	1:00	EEST	1992 Sep 27 0:00s
			2:00	Russia	EE%sT

Zone	Europe/Brussels	0:17:30 -	LMT	1880
			0:17:30	-	BMT	1892 May  1 12:00 # Brussels MT
			0:00	-	WET	1914 Nov  8
			1:00	-	CET	1916 May  1  0:00
			1:00	C-Eur	CE%sT	1918 Nov 11 11:00u
			0:00	Belgium	WE%sT	1940 May 20  2:00s
			1:00	C-Eur	CE%sT	1944 Sep  3
			1:00	Belgium	CE%sT	1977
			1:00	EU	CE%sT


Zone	Europe/Sofia	1:33:16 -	LMT	1880
			1:56:56	-	IMT	1894 Nov 30 # Istanbul MT?
			2:00	-	EET	1942 Nov  2  3:00
			1:00	C-Eur	CE%sT	1945 Apr  2  3:00
			2:00	-	EET	1979 Mar 31 23:00
			2:00	Bulg	EE%sT	1982 Sep 26  2:00
			2:00	C-Eur	EE%sT	1991
			2:00	E-Eur	EE%sT	1997
			2:00	EU	EE%sT


Zone	Europe/Prague	0:57:44 -	LMT	1850
			0:57:44	-	PMT	1891 Oct     # Prague Mean Time
			1:00	C-Eur	CE%sT	1944 Sep 17 2:00s
			1:00	Czech	CE%sT	1979
			1:00	EU	CE%sT

Zone Europe/Copenhagen	 0:50:20 -	LMT	1890
			 0:50:20 -	CMT	1894 Apr  # Copenhagen Mean Time
			 1:00	Denmark	CE%sT	1942 Nov  2 2:00s
			 1:00	C-Eur	CE%sT	1945 Apr  2 2:00
			 1:00	Denmark	CE%sT	1980
			 1:00	EU	CE%sT
Zone Atlantic/Faeroe	-0:27:04 -	LMT	1908 Jan 11	# Torshavn
			 0:00	-	WET	1981
			 0:00	EU	WE%sT

Zone America/Scoresbysund -1:29:00 -	LMT	1916 Jul 28 # Ittoqqortoormiit
			-2:00	-	CGT	1980 Apr  6 2:00
			-2:00	C-Eur	CG%sT	1981 Mar 29
			-1:00	EU	EG%sT
Zone America/Godthab	-3:26:56 -	LMT	1916 Jul 28 # Nuuk
			-3:00	-	WGT	1980 Apr  6 2:00
			-3:00	EU	WG%sT
Zone America/Thule	-4:35:08 -	LMT	1916 Jul 28 # Pituffik air base
			-4:00	Thule	A%sT





Zone	Europe/Tallinn	1:39:00	-	LMT	1880
			1:39:00	-	TMT	1918 Feb # Tallinn Mean Time
			1:00	C-Eur	CE%sT	1919 Jul
			1:39:00	-	TMT	1921 May
			2:00	-	EET	1940 Aug  6
			3:00	-	MSK	1941 Sep 15
			1:00	C-Eur	CE%sT	1944 Sep 22
			3:00	Russia	MSK/MSD	1989 Mar 26 2:00s
			2:00	1:00	EEST	1989 Sep 24 2:00s
			2:00	C-Eur	EE%sT	1998 Sep 22
			2:00	EU	EE%sT	1999 Nov  1
			2:00	-	EET

Zone	Europe/Helsinki	1:39:52 -	LMT	1878 May 31
			1:39:52	-	HMT	1921 May    # Helsinki Mean Time
			2:00	Finland	EE%sT	1981 Mar 29 2:00
			2:00	EU	EE%sT

Zone	Europe/Paris	0:09:21 -	LMT	1891 Mar 15  0:01
			0:09:21	-	PMT	1911 Mar 11    # Paris Mean Time
			0:00	France	WE%sT	1940 Jun 14 23:00
			1:00	C-Eur	CE%sT	1944 Aug 25
			0:00	France	WE%sT	1945 Sep 16  3:00
			1:00	France	CE%sT	1977
			1:00	EU	CE%sT



Zone	Europe/Berlin	0:53:28 -	LMT	1893 Apr
			1:00	C-Eur	CE%sT	1945 Apr 2 2:00
			1:00	Germany	CE%sT	1980
			1:00	EU	CE%sT

Zone Europe/Gibraltar	-0:21:24 -	LMT	1880 Aug  2
			0:00	GB-Eire	%s	1957 Apr 14 2:00
			1:00	-	CET	1982
			1:00	EU	CE%sT

Zone	Europe/Athens	1:34:52 -	LMT	1895 Sep 14
			1:34:52	-	AMT	1916 Jul 28 0:01     # Athens MT
			2:00	Greece	EE%sT	1941 Apr 30
			1:00	Greece	CE%sT	1944 Apr  4
			2:00	Greece	EE%sT	1981
			# Shanks says they switched to C-Eur in 1981;
			# go with EU instead, since Greece joined it on Jan 1.
			2:00	EU	EE%sT

Zone	Europe/Budapest	1:16:20 -	LMT	1890 Oct
			1:00	C-Eur	CE%sT	1918
			1:00	Hungary	CE%sT	1941 Apr  6  2:00
			1:00	C-Eur	CE%sT	1945 May  1 23:00
			1:00	Hungary	CE%sT	1980 Sep 28  2:00s
			1:00	EU	CE%sT

Zone Atlantic/Reykjavik	-1:27:24 -	LMT	1837
			-1:27:48 -	RMT	1908 # Reykjavik Mean Time?
			-1:00	Iceland	IS%sT	1968 Apr 7 1:00s
			 0:00	-	GMT

Zone	Europe/Rome	0:49:56 -	LMT	1866 Sep 22
			0:49:56	-	RMT	1893 Nov	# Rome Mean Time
			1:00	Italy	CE%sT	1942 Nov  2 2:00s
			1:00	C-Eur	CE%sT	1944 Jul
			1:00	Italy	CE%sT	1980
			1:00	EU	CE%sT


Zone	Europe/Riga	1:36:24	-	LMT	1880
			1:36:24	-	RMT	1918 Apr 15 2:00 #Riga Mean Time
			1:36:24	1:00	LST	1918 Sep 16 3:00 #Latvian Summer
			1:36:24	-	RMT	1919 Apr  1 2:00
			1:36:24	1:00	LST	1919 May 22 3:00
			1:36:24	-	RMT	1926 May 11
			2:00	-	EET	1940 Aug  5
			3:00	-	MSK	1941 Jul
			1:00	C-Eur	CE%sT	1944 Oct 13
			3:00	Russia	MSK/MSD	1989 Mar lastSun 2:00s
			2:00	1:00	EEST	1989 Sep lastSun 2:00s
			2:00	Latvia	EE%sT	1997 Jan 21
			2:00	EU	EE%sT	2000 Feb 29
			2:00	-	EET

Zone	Europe/Vaduz	0:38:04 -	LMT	1894 Jun
			1:00	-	CET	1981
			1:00	EU	CE%sT






Zone	Europe/Vilnius	1:41:16	-	LMT	1880
			1:24:00	-	WMT	1917	    # Warsaw Mean Time
			1:35:36	-	KMT	1919 Oct 10 # Kaunas Mean Time
			1:00	-	CET	1920 Jul 12
			2:00	-	EET	1920 Oct  9
			1:00	-	CET	1940 Aug  3
			3:00	-	MSK	1941 Jun 24
			1:00	C-Eur	CE%sT	1944 Aug
			3:00	Russia	MSK/MSD	1991 Mar 31 2:00s
			2:00	1:00	EEST	1991 Sep 29 2:00s
			2:00	C-Eur	EE%sT	1998
			2:00	-	EET	1998 Mar 29 1:00u
			1:00	EU	CE%sT	1999 Oct 31 1:00u
			2:00	-	EET

Zone Europe/Luxembourg	0:24:36 -	LMT	1904 Jun
			1:00	Lux	CE%sT	1918 Nov 25
			0:00	Lux	WE%sT	1929 Oct  6 2:00s
			0:00	Belgium	WE%sT	1940 May 14 3:00
			1:00	C-Eur	WE%sT	1944 Sep 18 3:00
			1:00	Belgium	CE%sT	1977
			1:00	EU	CE%sT


Zone	Europe/Malta	0:58:04 -	LMT	1893 Nov  2	# Valletta
			1:00	Italy	CE%sT	1942 Nov  2 2:00s
			1:00	C-Eur	CE%sT	1945 Apr  2 2:00s
			1:00	Italy	CE%sT	1973 Mar 31
			1:00	Malta	CE%sT	1981
			1:00	EU	CE%sT

Zone	Europe/Chisinau	1:55:20 -	LMT	1880
			1:55	-	CMT	1918 Feb 15 # Chisinau MT
			1:44:24	-	BMT	1931 Jul 24 # Bucharest MT
			2:00	Romania	EE%sT	1940 Aug 15
			2:00	1:00	EEST	1941 Jul 17
			1:00	C-Eur	CE%sT	1944 Aug 24
			3:00	Russia	MSK/MSD	1990
			3:00	-	MSK	1990 May 6
			2:00	-	EET	1991
			2:00	Russia	EE%sT	1992
			2:00	E-Eur	EE%sT	1997
			2:00	EU	EE%sT
Zone	Europe/Tiraspol	1:58:32	-	LMT	1880
			1:55	-	CMT	1918 Feb 15 # Chisinau MT
			1:44:24	-	BMT	1931 Jul 24 # Bucharest MT
			2:00	Romania	EE%sT	1940 Aug 15
			2:00	1:00	EEST	1941 Jul 17
			1:00	C-Eur	CE%sT	1944 Aug 24
			3:00	Russia	MSK/MSD	1991 Mar 31 2:00
			2:00	Russia	EE%sT	1992 Jan 19 2:00
			3:00	Russia	MSK/MSD

Zone	Europe/Monaco	0:29:32 -	LMT	1891 Mar 15
			0:09:21	-	PMT	1911 Mar 11    # Paris Mean Time
			0:00	France	WE%sT	1945 Sep 16 3:00
			1:00	France	CE%sT	1977
			1:00	EU	CE%sT

Zone Europe/Amsterdam	0:19:28 -	LMT	1892 May
			0:19:28	Neth	%s	1937 Jul
			0:20	Neth	NE%sT	1940 May 16 0:40
			1:00	C-Eur	CE%sT	1945 Apr  2 2:00
			1:00	Neth	CE%sT	1977
			1:00	EU	CE%sT

Zone	Europe/Oslo	0:43:00 -	LMT	1895
			1:00	Norway	CE%sT	1940 Aug 10 23:00
			1:00	C-Eur	CE%sT	1945 Apr  2  2:00
			1:00	Norway	CE%sT	1980
			1:00	EU	CE%sT

Zone Atlantic/Jan_Mayen	-1:00	-	EGT

Zone	Europe/Warsaw	1:24:00 -	LMT	1880
			1:24:00	-	WMT	1915 Aug  5   # Warsaw Mean Time
			1:00	C-Eur	CE%sT	1918 Sep 16 3:00
			2:00	Poland	EE%sT	1922 Jun
			1:00	Poland	CE%sT	1940 Jun 23 2:00
			1:00	C-Eur	CE%sT	1944 Oct
			1:00	Poland	CE%sT	1977 Apr  3 1:00
			1:00	W-Eur	CE%sT	1999
			1:00	EU	CE%sT

Zone	Europe/Lisbon	-0:36:32 -	LMT	1884
			-0:36:32 -	LMT	1911 May 24   # Lisbon Mean Time
			 0:00	Port	WE%sT	1966 Apr  3 2:00
			 1:00	-	CET	1976 Sep 26 1:00
			 0:00	Port	WE%sT	1983 Sep 25 1:00s
			 0:00	W-Eur	WE%sT	1992 Sep 27 1:00s
			 1:00	EU	CE%sT	1996 Mar 31 1:00u
			 0:00	EU	WE%sT
Zone Atlantic/Azores	-1:42:40 -	LMT	1884		# Ponta Delgada
			-1:55	-	HMT	1911 May 24  # Horta Mean Time
			-2:00	Port	AZO%sT	1966 Apr  3 2:00 # Azores Time
			-1:00	Port	AZO%sT	1983 Sep 25 1:00s
			-1:00	W-Eur	AZO%sT	1992 Sep 27 1:00s
			 0:00	EU	WE%sT	1993 Mar 28 1:00u
			-1:00	EU	AZO%sT
Zone Atlantic/Madeira	-1:07:36 -	LMT	1884		# Funchal
			-1:08	-	FMT	1911 May 24  # Funchal Mean Time
			-1:00	Port	MAD%sT	1966 Apr  3 2:00 # Madeira Time
			 0:00	Port	WE%sT	1983 Sep 25 1:00s
			 0:00	EU	WE%sT

Zone Europe/Bucharest	1:44:24 -	LMT	1891 Oct
			1:44:24	-	BMT	1931 Jul 24	# Bucharest MT
			2:00	Romania	EE%sT	1981 Mar 29 2:00s
			2:00	C-Eur	EE%sT	1991
			2:00	Romania	EE%sT	1994
			2:00	E-Eur	EE%sT	1997
			2:00	EU	EE%sT


Zone Europe/Kaliningrad	 1:22:00 - 	LMT	1893 Apr
			 1:00	C-Eur	CE%sT	1945
			 2:00	Poland	CE%sT	1946
			 3:00	Russia	MSK/MSD	1991 Mar 31 2:00s
			 2:00	Russia	EE%sT
Zone Europe/Moscow	 2:30:20 -	LMT	1880
			 2:30	-	MMT	1916 Jul  3 # Moscow Mean Time
			 2:30:48 Russia	%s	1919 Jul  1 2:00
			 3:00	Russia	MSK/MSD	1922 Oct
			 2:00	-	EET	1930 Jun 21
			 3:00	Russia	MSK/MSD	1991 Mar 31 2:00s
			 2:00	Russia	EE%sT	1992 Jan 19 2:00s
			 3:00	Russia	MSK/MSD
Zone Europe/Samara	 3:20:36 -	LMT	1919 Jul  1 2:00
			 3:00	-	KUYT	1930 Jun 21 # Kuybyshev
			 4:00	Russia	KUY%sT	1989 Mar 26 2:00s
			 3:00	Russia	KUY%sT	1991 Mar 31 2:00s
			 2:00	Russia	KUY%sT	1991 Sep 29 2:00s
			 3:00	-	KUYT	1991 Oct 20 3:00
			 4:00	Russia	SAM%sT	# Samara Time
Zone Asia/Yekaterinburg	 4:02:24 -	LMT	1919 Jul 15 4:00
			 4:00	-	SVET	1930 Jun 21 # Sverdlovsk Time
			 5:00	Russia	SVE%sT	1991 Mar 31 2:00s
			 4:00	Russia	SVE%sT	1992 Jan 19 2:00s
			 5:00	Russia	YEK%sT	# Yekaterinburg Time
Zone Asia/Omsk		 4:53:36 -	LMT	1919 Nov 14
			 5:00	-	OMST	1930 Jun 21 # Omsk TIme
			 6:00	Russia	OMS%sT	1991 Mar 31 2:00s
			 5:00	Russia	OMS%sT	1992 Jan 19 2:00s
			 6:00	Russia	OMS%sT
Zone Asia/Novosibirsk	 5:31:40 -	LMT	1919 Dec 14 6:00
			 6:00	-	NOVT	1930 Jun 21 # Novosibirsk Time
			 7:00	Russia	NOV%sT	1991 Mar 31 2:00s
			 6:00	Russia	NOV%sT	1992 Jan 19 2:00s
			 7:00	Russia	NOV%sT	1993 May 23 # says Shanks
			 6:00	Russia	NOV%sT
Zone Asia/Krasnoyarsk	 6:11:20 -	LMT	1920 Jan  6
			 6:00	-	KRAT	1930 Jun 21 # Krasnoyarsk Time
			 7:00	Russia	KRA%sT	1991 Mar 31 2:00s
			 6:00	Russia	KRA%sT	1992 Jan 19 2:00s
			 7:00	Russia	KRA%sT
Zone Asia/Irkutsk	 6:57:20 -	LMT	1880
			 6:57:20 -	IMT	1920 Jan 25 # Irkutsk Mean Time
			 7:00	-	IRKT	1930 Jun 21 # Irkutsk Time
			 8:00	Russia	IRK%sT	1991 Mar 31 2:00s
			 7:00	Russia	IRK%sT	1992 Jan 19 2:00s
			 8:00	Russia	IRK%sT
Zone Asia/Yakutsk	 8:38:40 -	LMT	1919 Dec 15
			 8:00	-	YAKT	1930 Jun 21 # Yakutsk Time
			 9:00	Russia	YAK%sT	1991 Mar 31 2:00s
			 8:00	Russia	YAK%sT	1992 Jan 19 2:00s
			 9:00	Russia	YAK%sT
Zone Asia/Vladivostok	 8:47:44 -	LMT	1922 Nov 15
			 9:00	-	VLAT	1930 Jun 21 # Vladivostok Time
			10:00	Russia	VLA%sT	1991 Mar 31 2:00s
			 9:00	Russia	VLA%sST	1992 Jan 19 2:00s
			10:00	Russia	VLA%sT
Zone Asia/Magadan	10:03:12 -	LMT	1924 May  2
			10:00	-	MAGT	1930 Jun 21 # Magadan Time
			11:00	Russia	MAG%sT	1991 Mar 31 2:00s
			10:00	Russia	MAG%sT	1992 Jan 19 2:00s
			11:00	Russia	MAG%sT
Zone Asia/Kamchatka	10:34:36 -	LMT	1922 Nov 10
			11:00	-	PETT	1930 Jun 21 # P-K Time
			12:00	Russia	PET%sT	1991 Mar 31 2:00s
			11:00	Russia	PET%sT	1992 Jan 19 2:00s
			12:00	Russia	PET%sT
Zone Asia/Anadyr	11:49:56 -	LMT	1924 May  2
			12:00	-	ANAT	1930 Jun 21 # Anadyr Time
			13:00	Russia	ANA%sT	1982 Apr  1 0:00s
			12:00	Russia	ANA%sT	1991 Mar 31 2:00s
			11:00	Russia	ANA%sT	1992 Jan 19 2:00s
			12:00	Russia	ANA%sT


Zone	Europe/Madrid	-0:14:44 -	LMT	1901
			 0:00	Spain	WE%sT	1946 Sep 30
			 1:00	Spain	CE%sT	1979
			 1:00	EU	CE%sT
Zone	Africa/Ceuta	-0:21:16 -	LMT	1901
			 0:00	-	WET	1918 May  6 23:00
			 0:00	1:00	WEST	1918 Oct  7 23:00
			 0:00	-	WET	1924
			 0:00	Spain	WE%sT	1929
			 0:00 SpainAfrica WE%sT 1984 Mar 16
			 1:00	-	CET	1986
			 1:00	EU	CE%sT
Zone	Atlantic/Canary	-1:01:36 -	LMT	1922 Mar # Las Palmas de Gran C.
			-1:00	-	CANT	1946 Sep 30 1:00 # Canaries Time
			 0:00	-	WET	1980 Apr  6 0:00s
			 0:00	1:00	WEST	1980 Sep 28 0:00s
			 0:00	EU	WE%sT

Zone Europe/Stockholm	1:12:12 -	LMT	1878 May 31
			1:12:12	-	SMT	1900 Jan  1  1:00 # Stockholm MT
			1:00	-	CET	1916 Apr 14 23:00s
			1:00	1:00	CEST	1916 Sep 30 23:00s
			1:00	-	CET	1980
			1:00	EU	CE%sT

Zone	Europe/Zurich	0:34:08 -	LMT	1848 Sep 12
			0:29:44	-	BMT	1894 Jun # Bern Mean Time
			1:00	Swiss	CE%sT	1981
			1:00	EU	CE%sT

Zone	Europe/Istanbul	1:55:52 -	LMT	1880
			1:56:56	-	IMT	1910 Oct # Istanbul Mean Time?
			2:00	Turkey	EE%sT	1978 Oct 15
			3:00	Turkey	TR%sT	1985 Apr 20 # Turkey Time
			2:00	Turkey	EE%sT	1986
			2:00	C-Eur	EE%sT	1991
			2:00	EU	EE%sT

Zone Europe/Kiev	2:02:04 -	LMT	1880
			2:02:04	-	KMT	1924 May  2 # Kiev Mean Time
			2:00	-	EET	1930 Jun 21
			3:00	-	MSK	1941 Sep 20
			1:00	C-Eur	CE%sT	1943 Nov  6
			3:00	Russia	MSK/MSD	1990
			3:00	-	MSK	1990 Jul  1 2:00
			2:00	-	EET	1992
			2:00	E-Eur	EE%sT	1995
			2:00	EU	EE%sT
Zone Europe/Uzhgorod	1:29:12 -	LMT	1890 Oct
			1:00	-	CET	1940
			1:00	C-Eur	CE%sT	1944 Oct
			1:00	1:00	CEST	1944 Oct 26
			1:00	-	CET	1945 Jun 29
			3:00	Russia	MSK/MSD	1990
			3:00	-	MSK	1990 Jul  1 2:00
			1:00	-	CET	1991 Mar 31 3:00
			2:00	-	EET	1992
			2:00	E-Eur	EE%sT	1995
			2:00	EU	EE%sT
Zone Europe/Zaporozhye	2:20:40 -	LMT	1880
			2:20	-	CUT	1924 May  2 # Central Ukraine T
			2:00	-	EET	1930 Jun 21
			3:00	-	MSK	1941 Aug 25
			1:00	C-Eur	CE%sT	1943 Oct 25
			3:00	Russia	MSK/MSD	1991 Mar 31 2:00
			2:00	E-Eur	EE%sT	1995
			2:00	EU	EE%sT
Zone Europe/Simferopol	2:16:24 -	LMT	1880
			2:16	-	SMT	1924 May  2 # Simferopol Mean T
			2:00	-	EET	1930 Jun 21
			3:00	-	MSK	1941 Nov
			1:00	C-Eur	CE%sT	1944 Apr 13
			3:00	Russia	MSK/MSD	1990
			3:00	-	MSK	1990 Jul  1 2:00
			2:00	-	EET	1992
			2:00	E-Eur	EE%sT	1994 May
			3:00	E-Eur	MSK/MSD	1996 Mar 31 3:00s
			3:00	1:00	MSD	1996 Oct 27 3:00s
			3:00	Russia	MSK/MSD	1997
			3:00	-	MSK	1997 Mar lastSun 1:00u
			2:00	EU	EE%sT

Zone	Europe/Belgrade	1:22:00	-	LMT	1884
			1:00	-	CET	1941 Apr 18 23:00
			1:00	C-Eur	CE%sT	1945 May  8  2:00s
			1:00	1:00	CEST	1945 Sep 16  2:00s
			1:00	-	CET	1982 Nov 27
			1:00	EU	CE%sT

Zone America/New_York	-4:56:02 -	LMT	1883 Nov 18 12:00
			-5:00	US	E%sT	1920
			-5:00	NYC	E%sT	1942
			-5:00	US	E%sT	1946
			-5:00	NYC	E%sT	1967
			-5:00	US	E%sT



Zone America/Chicago	-5:50:36 -	LMT	1883 Nov 18 12:00
			-6:00	US	C%sT	1920
			-6:00	Chicago	C%sT	1936 Mar  1 2:00
			-5:00	-	EST	1936 Nov 15 2:00
			-6:00	Chicago	C%sT	1942
			-6:00	US	C%sT	1946
			-6:00	Chicago	C%sT	1967
			-6:00	US	C%sT

Zone America/Denver	-6:59:56 -	LMT	1883 Nov 18 12:00
			-7:00	US	M%sT	1920
			-7:00	Denver	M%sT	1942
			-7:00	US	M%sT	1946
			-7:00	Denver	M%sT	1967
			-7:00	US	M%sT

Zone America/Los_Angeles -7:52:58 -	LMT	1883 Nov 18 12:00
			-8:00	US	P%sT	1946
			-8:00	CA	P%sT	1967
			-8:00	US	P%sT

Zone America/Juneau	 -8:57:41 -	LMT	1900 Aug 20 12:00
			 -8:00	-	PST	1942
			 -8:00	US	P%sT	1946
			 -8:00	-	PST	1969
			 -8:00	US	P%sT	1983 Oct 30 2:00
			 -9:00	US	AK%sT
Zone America/Yakutat	 -9:18:55 -	LMT	1900 Aug 20 12:00
			 -9:00	-	YST	1942
			 -9:00	US	Y%sT	1946
			 -9:00	-	YST	1969
			 -9:00	US	Y%sT	1983 Oct 30 2:00
			 -9:00	US	AK%sT
Zone America/Anchorage	 -9:59:36 -	LMT	1900 Aug 20 12:00
			-10:00	-	CAT	1942
			-10:00	US	CAT/CAWT 1946
			-10:00	-	CAT	1967 Apr
			-10:00	-	AHST	1969
			-10:00	US	AH%sT	1983 Oct 30 2:00
			 -9:00	US	AK%sT
Zone America/Nome	-11:01:38 -	LMT	1900 Aug 20 12:00
			-11:00	-	NST	1942
			-11:00	US	N%sT	1946
			-11:00	-	NST	1967 Apr
			-11:00	-	BST	1969
			-11:00	US	B%sT	1983 Oct 30 2:00
			 -9:00	US	AK%sT
Zone America/Adak	-11:46:38 -	LMT	1900 Aug 20 12:00
			-11:00	-	NST	1942
			-11:00	US	N%sT	1946
			-11:00	-	NST	1967 Apr
			-11:00	-	BST	1969
			-11:00	US	B%sT	1983 Oct 30 2:00
			-10:00	US	HA%sT

Zone Pacific/Honolulu	-10:31:26 -	LMT	1900 Jan  1 12:00
			-10:30	-	HST	1933 Apr 30 2:00
			-10:30	1:00	HDT	1933 May 21 2:00
			-10:30	US	H%sT	1947 Jun  8 2:00
			-10:00	-	HST


Zone America/Phoenix	-7:28:18 -	LMT	1883 Nov 18 12:00
			-7:00	US	M%sT	1944 Jan  1 00:01
			-7:00	-	MST	1944 Mar 17 00:01
			-7:00	US	M%sT	1944 Oct  1 00:01
			-7:00	-	MST	1967
			-7:00	US	M%sT	1968
			-7:00	-	MST


Zone America/Boise	-7:44:49 -	LMT	1883 Nov 18 12:00
			-8:00	US	P%sT	1923 May 13 2:00
			-7:00	US	M%sT	1974
			-7:00	-	MST	1974 Feb  3 2:00
			-7:00	US	M%sT

Zone America/Indianapolis -5:44:38 - LMT 1883 Nov 18 12:00
			-6:00	US	C%sT	1920
			-6:00 Indianapolis C%sT	1942
			-6:00	US	C%sT	1946
			-6:00 Indianapolis C%sT	1955 Apr 24 2:00
			-5:00	-	EST	1957 Sep 29 2:00
			-6:00	-	CST	1958 Apr 27 2:00
			-5:00	-	EST	1969
			-5:00	US	E%sT	1971
			-5:00	-	EST
Zone America/Indiana/Marengo -5:45:23 -	LMT	1883 Nov 18 12:00
			-6:00	US	C%sT	1951
			-6:00	Marengo	C%sT	1961 Apr 30 2:00
			-5:00	-	EST	1969
			-5:00	US	E%sT	1974 Jan  6 2:00
			-6:00	1:00	CDT	1974 Oct 27 2:00
			-5:00	US	E%sT	1976
			-5:00	-	EST
Zone America/Indiana/Knox -5:46:30 -	LMT	1883 Nov 18 12:00
			-6:00	US	C%sT	1947
			-6:00	Starke	C%sT	1962 Apr 29 2:00
			-5:00	-	EST	1963 Oct 27 2:00
			-6:00	US	C%sT	1991 Oct 27 2:00
			-5:00	-	EST
Zone America/Indiana/Vevay -5:40:16 -	LMT	1883 Nov 18 12:00
			-6:00	US	C%sT	1954 Apr 25 2:00
			-5:00	-	EST	1969
			-5:00	US	E%sT	1973
			-5:00	-	EST

Zone America/Louisville	-5:43:02 -	LMT	1883 Nov 18 12:00
			-6:00	US	C%sT	1921
			-6:00 Louisville C%sT	1942
			-6:00	US	C%sT	1946
			-6:00 Louisville C%sT	1961 Jul 23 2:00
			-5:00	-	EST	1968
			-5:00	US	E%sT	1974 Jan  6 2:00
			-6:00	1:00	CDT	1974 Oct 27 2:00
			-5:00	US	E%sT
Zone America/Kentucky/Monticello -5:39:24 - LMT	1883 Nov 18 12:00
			-6:00	US	C%sT	1946
			-6:00	-	CST	1968
			-6:00	US	C%sT	2000 Oct 29  2:00
			-5:00	US	E%sT



Zone America/Detroit	-5:32:11 -	LMT	1905
			-6:00	-	CST	1915 May 15 2:00
			-5:00	-	EST	1942
			-5:00	US	E%sT	1946
			-5:00	Detroit	E%sT	1973
			-5:00	US	E%sT	1975
			-5:00	-	EST	1975 Apr 27 2:00
			-5:00	US	E%sT
Zone America/Menominee	-5:50:27 -	LMT	1885 Sep 18 12:00
			-6:00	US	C%sT	1946
			-6:00 Menominee	C%sT	1969 Apr 27 2:00
			-5:00	-	EST	1973 Apr 29 2:00
			-6:00	US	C%sT

Zone America/St_Johns	-3:30:52 -	LMT	1884
			-3:30:52 StJohns N%sT	1935 Mar 30
			-3:30	StJohns	N%sT



Zone America/Goose_Bay	-4:01:40 -	LMT	1884 # Happy Valley-Goose Bay
			-3:30:52 StJohns NST	1919
			-3:30:52 -	NST	1935 Mar 30
			-3:30	-	NST	1936
			-3:30	StJohns	N%sT	1966 Mar 15 2:00
			-4:00	StJohns	A%sT






Zone America/Halifax	-4:14:24 -	LMT	1902 Jun 15
			-4:00	Halifax	A%sT
Zone America/Glace_Bay	-3:59:48 -	LMT	1902 Jun 15
			-4:00	Canada	A%sT	1953
			-4:00	Halifax	A%sT	1954
			-4:00	-	AST	1972
			-4:00	Halifax	A%sT






Zone America/Montreal	-4:54:16 -	LMT	1884
			-5:00	Mont	E%sT
Zone America/Thunder_Bay -5:57:00 -	LMT	1895
			-5:00	Canada	E%sT	1970
			-5:00	Mont	E%sT	1973
			-5:00	-	EST	1974
			-5:00	Canada	E%sT
Zone America/Nipigon	-5:53:04 -	LMT	1895
			-5:00	Canada	E%sT
Zone America/Rainy_River -6:17:56 -	LMT	1895
			-6:00	Canada	C%sT



Zone America/Winnipeg	-6:28:36 -	LMT	1887 Jul 16
			-6:00	Winn	C%sT





Zone America/Regina	-6:58:36 -	LMT	1905 Sep
			-7:00	Regina	M%sT	1960 Apr lastSun 2:00
			-6:00	-	CST
Zone America/Swift_Current -7:11:20 -	LMT	1905 Sep
			-7:00	Canada	M%sT	1946 Apr lastSun 2:00
			-7:00	Regina	M%sT	1950
			-7:00	Swift	M%sT	1972 Apr lastSun 2:00
			-6:00	-	CST



Zone America/Edmonton	-7:33:52 -	LMT	1906 Sep
			-7:00	Edm	M%sT




Zone America/Vancouver	-8:12:28 -	LMT	1884
			-8:00	Vanc	P%sT
Zone America/Dawson_Creek -8:00:56 -	LMT	1884
			-8:00	Canada	P%sT	1947
			-8:00	Vanc	P%sT	1972 Aug 30 2:00
			-7:00	-	MST











Zone America/Pangnirtung -4:22:56 -	LMT	1884
			-4:00	NT_YK	A%sT	1995 Apr Sun>=1 2:00
			-5:00	Canada	E%sT	1999 Oct 31 2:00
			-6:00	Canada	C%sT	2000 Oct 29 2:00
			-5:00	-	EST
Zone America/Iqaluit	-4:33:52 -	LMT	1884 # Frobisher Bay before 1987
			-5:00	NT_YK	E%sT	1999 Oct 31 2:00
			-6:00	Canada	C%sT	2000 Oct 29 2:00
			-5:00	-	EST
Zone America/Rankin_Inlet -6:08:40 -	LMT	1884
			-6:00	NT_YK	C%sT	2000 Oct 29 2:00
			-5:00	-	EST
Zone America/Cambridge_Bay -7:00:20 -	LMT	1884
			-7:00	NT_YK	M%sT	1999 Oct 31 2:00
			-6:00	Canada	C%sT
Zone America/Yellowknife -7:37:24 -	LMT	1884
			-7:00	NT_YK	M%sT
Zone America/Inuvik	-8:54:00 -	LMT	1884
			-8:00	NT_YK	P%sT	1979 Apr lastSun 2:00
			-7:00	NT_YK	M%sT
Zone America/Whitehorse	-9:00:12 -	LMT	1900 Aug 20
			-9:00	NT_YK	Y%sT	1966 Jul 1 2:00
			-8:00	NT_YK	P%sT
Zone America/Dawson	-9:17:40 -	LMT	1900 Aug 20
			-9:00	NT_YK	Y%sT	1973 Oct 28 0:00
			-8:00	NT_YK	P%sT










Zone America/Cancun	-5:47:04 -	LMT	1922 Jan  1  0:12:56
			-6:00	-	CST	1981 Dec
			-5:00	-	EST	1982 Dec  2
			-6:00	-	CST	1996
			-6:00	Mexico	C%sT	1997 Oct lastSun 2:00
			-5:00	Mexico	E%sT	1998 Aug  2  2:00
			-6:00	Mexico	C%sT
Zone America/Merida	-5:58:28 -	LMT	1922 Jan  1  0:01:32
			-6:00	-	CST	1981 Dec
			-5:00	-	EST	1982 Dec  2
			-6:00	Mexico	C%sT
Zone America/Monterrey	-6:41:16 -	LMT	1922 Jan  1  0:01:32
			-6:00	-	CST	1988
			-6:00	US	C%sT	1989
			-6:00	Mexico	C%sT
Zone America/Mexico_City -6:36:36 -	LMT	1922 Jan  1  0:23:24
			-7:00	-	MST	1927 Jun 10 23:00
			-6:00	-	CST	1930 Nov 15
			-7:00	-	MST	1931 May  1 23:00
			-6:00	-	CST	1931 Oct
			-7:00	-	MST	1932 Mar 30 23:00
			-6:00	Mexico	C%sT
Zone America/Chihuahua	-7:04:20 -	LMT	1921 Dec 31 23:55:40
			-7:00	-	MST	1927 Jun 10 23:00
			-6:00	-	CST	1930 Nov 15
			-7:00	-	MST	1931 May  1 23:00
			-6:00	-	CST	1931 Oct
			-7:00	-	MST	1932 Mar 30 23:00
			-6:00	-	CST	1996
			-6:00	Mexico	C%sT	1998
			-6:00	-	CST	1998 Apr Sun>=1 3:00
			-7:00	Mexico	M%sT
Zone America/Hermosillo	-7:23:52 -	LMT	1921 Dec 31 23:36:08
			-7:00	-	MST	1927 Jun 10 23:00
			-6:00	-	CST	1930 Nov 15
			-7:00	-	MST	1931 May  1 23:00
			-6:00	-	CST	1931 Oct
			-7:00	-	MST	1932 Mar 30 23:00
			-6:00	-	CST	1942 Apr 24
			-7:00	-	MST	1949 Jan 14
			-8:00	-	PST	1970
			-7:00	Mexico	M%sT	1999
			-7:00	-	MST
Zone America/Mazatlan	-7:05:40 -	LMT	1921 Dec 31 23:54:20
			-7:00	-	MST	1927 Jun 10 23:00
			-6:00	-	CST	1930 Nov 15
			-7:00	-	MST	1931 May  1 23:00
			-6:00	-	CST	1931 Oct
			-7:00	-	MST	1932 Mar 30 23:00
			-6:00	-	CST	1942 Apr 24
			-7:00	-	MST	1949 Jan 14
			-8:00	-	PST	1970
			-7:00	Mexico	M%sT
Zone America/Tijuana	-7:48:04 -	LMT	1922 Jan  1  0:11:56
			-8:00	-	PST	1927 Jun 10 23:00
			-7:00	-	MST	1930 Nov 16
			-8:00	-	PST	1942 Apr 24
			-7:00	-	MST	1949 Jan 14
			-8:00	BajaN	P%sT	1976
			-8:00	US	P%sT	1996
			-8:00	Mexico	P%sT


Zone America/Anguilla	-4:12:16 -	LMT	1912 Mar 2
			-4:00	-	AST

Zone	America/Antigua	-4:07:12 -	LMT	1912 Mar 2
			-5:00	-	EST	1951
			-4:00	-	AST

Zone	America/Nassau	-5:09:24 -	LMT	1912 Mar 2
			-5:00	Bahamas	E%sT

Zone America/Barbados	-3:58:28 -	LMT	1924		# Bridgetown
			-3:58:28 -	BMT	1932	  # Bridgetown Mean Time
			-4:00	Barb	A%sT

Zone	America/Belize	-5:52:48 -	LMT	1912 Apr
			-6:00	Belize	C%sT

Zone Atlantic/Bermuda	-4:19:04 -	LMT	1930 Jan  1 2:00    # Hamilton
			-4:00	-	AST	1974 Apr 28 2:00
			-4:00	Bahamas	A%sT

Zone	America/Cayman	-5:25:32 -	LMT	1890		# Georgetown
			-5:07:12 -	KMT	1912 Feb    # Kingston Mean Time
			-5:00	-	EST

Zone America/Costa_Rica	-5:36:20 -	LMT	1890		# San Jose
			-5:36:20 -	SJMT	1921 Jan 15 # San Jose Mean Time
			-6:00	CR	C%sT




Zone	America/Havana	-5:29:28 -	LMT	1890
			-5:29:36 -	HMT	1925 Jul 19 12:00 # Havana MT
			-5:00	Cuba	C%sT

Zone America/Dominica	-4:05:36 -	LMT	1911 Jul 1 0:01		# Roseau
			-4:00	-	AST






Zone America/Santo_Domingo -4:39:36 -	LMT	1890
			-4:40	-	SDMT	1933 Apr  1 12:00 # S. Dom. MT
			-5:00	DR	E%sT	1974 Oct 27
			-4:00	-	AST	2000 Oct 29 02:00
			-5:00	US	E%sT	2000 Dec  3 01:00
			-4:00	-	AST

Zone America/El_Salvador -5:56:48 -	LMT	1921		# San Salvador
			-6:00	Salv	C%sT

Zone	America/Grenada	-4:07:00 -	LMT	1911 Jul	# St George's
			-4:00	-	AST

Zone America/Guadeloupe	-4:06:08 -	LMT	1911 Jun 8	# Pointe a Pitre
			-4:00	-	AST

Zone America/Guatemala	-6:02:04 -	LMT	1918 Oct 5
			-6:00	Guat	C%sT

Zone America/Port-au-Prince -4:49:20 -	LMT	1890
			-4:49	-	PPMT	1917 Jan 24 12:00 # P-a-P MT
			-5:00	Haiti	E%sT

Zone America/Tegucigalpa -5:48:52 -	LMT	1921 Apr
			-6:00	Salv	C%sT




Zone	America/Jamaica	-5:07:12 -	LMT	1890		# Kingston
			-5:07:12 -	KMT	1912 Feb    # Kingston Mean Time
			-5:00	-	EST	1974 Apr 28 2:00
			-5:00	US	E%sT	1984
			-5:00	-	EST

Zone America/Martinique	-4:04:20 -      LMT	1890		# Fort-de-France
			-4:04	-	FFMT	1911 May     # Fort-de-France MT
			-4:00	-	AST	1980 Apr  6
			-4:00	1:00	ADT	1980 Sep 28
			-4:00	-	AST

Zone America/Montserrat	-4:08:52 -	LMT	1911 Jul 1 0:01   # Olveston
			-4:00	-	AST

Zone	America/Managua	-5:45:08 -	LMT	1890
			-5:45	-	MMT	1934 Jun 23  # Managua Mean Time
			-6:00	-	CST	1973 May
			-5:00	-	EST	1975 Feb 16
			-6:00	Nic	C%sT	1993 Jan 1 4:00
			-5:00	-	EST	1998 Dec
			-6:00	-	CST

Zone	America/Panama	-5:18:08 -	LMT	1890
			-5:20	-	PMT	1908 Apr 22   # Panama Mean Time
			-5:00	-	EST

Zone America/Puerto_Rico -4:24:25 -	LMT	1899 Mar 28 12:00    # San Juan
			-4:00	-	AST	1942 May  3
			-4:00	1:00	AWT	1945 Sep 30  2:00
			-4:00	-	AST

Zone America/St_Kitts	-4:10:52 -	LMT	1912 Mar 2	# Basseterre
			-4:00	-	AST

Zone America/St_Lucia	-4:04:00 -	LMT	1890		# Castries
			-4:04	-	CMT	1912	    # Castries Mean Time
			-4:00	-	AST

Zone America/Miquelon	-3:44:40 -	LMT	1911 May 15	# St Pierre
			-4:00	-	AST	1980 May
			-3:00	Mont	PM%sT	# Pierre & Miquelon Time

Zone America/St_Vincent	-4:04:56 -	LMT	1890		# Kingstown
			-4:04:56 -	KMT	1912	   # Kingstown Mean Time
			-4:00	-	AST

Zone America/Grand_Turk	-4:44:32 -	LMT	1890
			-5:07:12 -	KMT	1912 Feb    # Kingston Mean Time
			-5:00	TC	E%sT

Zone America/Tortola	-4:18:28 -	LMT	1911 Jul    # Road Town
			-4:00	-	AST

Zone America/St_Thomas	-4:19:44 -	LMT	1911 Jul    # Charlotte Amalie
			-4:00	-	AST





Link	America/Los_Angeles	US/Pacific-New	##




Zone	Asia/Riyadh87	3:07:04	-		??	1987
			3:07:04	sol87		??	1988
			3:07:04	-		??
Link	Asia/Riyadh87	Mideast/Riyadh87




Zone	Asia/Riyadh88	3:07:04	-		??	1988
			3:07:04	sol88		??	1989
			3:07:04	-		??
Link	Asia/Riyadh88	Mideast/Riyadh88




Zone	Asia/Riyadh89	3:07:04	-		??	1989
			3:07:04	sol89		??	1990
			3:07:04	-		??
Link	Asia/Riyadh89	Mideast/Riyadh89









Zone America/Buenos_Aires -3:53:48 -	LMT	1894 Nov
			-4:16:44 -	CMT	1920 May    # Cordoba Mean Time
			-4:00	-	ART	1930 Dec
			-4:00	Arg	AR%sT	1969 Oct  5
			-3:00	Arg	AR%sT	1999 Oct  3 0:00
			-4:00	Arg	AR%sT	2000 Mar  3 0:00
			-3:00	-	ART
Zone America/Rosario	-4:02:40 -	LMT	1894 Nov
			-4:16:44 -	CMT	1920 May
			-4:00	-	ART	1930 Dec
			-4:00	Arg	AR%sT	1969 Oct  5
			-3:00	Arg	AR%sT	1991 Jul
			-3:00	-	ART	1999 Oct  3 0:00
			-4:00	Arg	AR%sT	2000 Mar  3 0:00
			-3:00	-	ART
Zone America/Cordoba	-4:16:44 -	LMT	1894 Nov
			-4:16:44 -	CMT	1920 May
			-4:00	-	ART	1930 Dec
			-4:00	Arg	AR%sT	1969 Oct  5
			-3:00	Arg	AR%sT	1990 Jul
			-3:00	-	ART	1999 Oct  3 0:00
			-4:00	Arg	AR%sT	2000 Mar  3 0:00
			-3:00	-	ART
Zone America/Jujuy	-4:21:12 -	LMT	1894 Nov
			-4:16:44 -	CMT	1920 May
			-4:00	-	ART	1930 Dec
			-4:00	Arg	AR%sT	1969 Oct  5
			-3:00	Arg	AR%sT	1991 Mar  3
			-4:00	-	WART	1991 Oct  6
			-4:00	1:00	WARST	1992 Mar 15
			-4:00	-	WART	1992 Oct 18
			-3:00	-	ART	1999 Oct  3 0:00
			-4:00	Arg	AR%sT	2000 Mar  3 0:00
			-3:00	-	ART
Zone America/Catamarca	-4:23:08 -	LMT	1894 Nov
			-4:16:44 -	CMT	1920 May
			-4:00	-	ART	1930 Dec
			-4:00	Arg	AR%sT	1969 Oct  5
			-3:00	Arg	AR%sT	1990 Jul
			-3:00	-	ART	1991 Jul
			-3:00	Arg	AR%sT	1992 Jul
			-3:00	-	ART	1999 Oct  3 0:00
			-4:00	Arg	AR%sT	2000 Mar  3 0:00
			-3:00	-	ART
Zone America/Mendoza	-4:35:16 -	LMT	1894 Nov
			-4:16:44 -	CMT	1920 May
			-4:00	-	ART	1930 Dec
			-4:00	Arg	AR%sT	1969 Oct  5
			-3:00	Arg	AR%sT	1991 Mar  3
			-4:00	-	WART	1991 Oct 15
			-4:00	1:00	WARST	1992 Mar  1
			-4:00	-	WART	1992 Oct 18
			-3:00	-	ART	1999 Oct  3 0:00
			-4:00	Arg	AR%sT	2000 Mar  3 0:00
			-3:00	-	ART

Zone	America/Aruba	-4:40:24 -	LMT	1912 Feb 12	# Oranjestad
			-4:30	-	ANT	1965 # Netherlands Antilles Time
			-4:00	-	AST

Zone	America/La_Paz	-4:32:36 -	LMT	1890
			-4:32:36 -	LPMT	1931 Oct 15 # La Paz Mean Time
			-4:32:36 1:00	BOST	1932 Mar 21 # Bolivia ST
			-4:00	-	BOT	# Bolivia Time










Zone America/Noronha	-2:09:40 -	LMT	1914
			-2:00	Brazil	FN%sT	1990 Sep 17
			-2:00	-	FNT
Zone America/Belem	-3:13:56 -	LMT	1914
			-3:00	Brazil	BR%sT	1988 Sep 12
			-3:00	-	BRT
Zone America/Fortaleza	-2:34:00 -	LMT	1914
			-3:00	Brazil	BR%sT	1990 Sep 17
			-3:00	-	BRT	1999 Sep 30
			-3:00	Brazil	BR%sT	2000 Oct 22
			-3:00	-	BRT
Zone America/Recife	-2:19:36 -	LMT	1914
			-3:00	Brazil	BR%sT	1990 Sep 17
			-3:00	-	BRT	1999 Sep 30
			-3:00	Brazil	BR%sT	2000 Oct 15
			-3:00	-	BRT
Zone America/Araguaina	-3:12:48 -	LMT	1914
			-3:00	Brazil	BR%sT	1990 Sep 17
			-3:00	-	BRT	1995 Sep 14
			-3:00	Brazil	BR%sT
Zone America/Maceio	-2:22:52 -	LMT	1914
			-3:00	Brazil	BR%sT	1990 Sep 17
			-3:00	-	BRT	1995 Oct 13
			-3:00	Brazil	BR%sT	1996 Sep  4
			-3:00	-	BRT	1999 Sep 30
			-3:00	Brazil	BR%sT	2000 Oct 22
			-3:00	-	BRT
Zone America/Sao_Paulo	-3:06:28 -	LMT	1914
			-3:00	Brazil	BR%sT	1963 Oct 23 00:00
			-3:00	1:00	BRST	1964
			-3:00	Brazil	BR%sT
Zone America/Cuiaba	-3:44:20 -	LMT	1914
			-4:00	Brazil	AM%sT
Zone America/Porto_Velho -4:15:36 -	LMT	1914
			-4:00	Brazil	AM%sT	1988 Sep 12
			-4:00	-	AMT
Zone America/Boa_Vista	-4:02:40 -	LMT	1914
			-4:00	Brazil	AM%sT	1988 Sep 12
			-4:00	-	AMT	1999 Sep 30
			-4:00	Brazil	AM%sT	2000 Oct 15
			-4:00	-	AMT
Zone America/Manaus	-4:00:04 -	LMT	1914
			-4:00	Brazil	AM%sT	1988 Sep 12
			-4:00	-	AMT	1993 Sep 28
			-4:00	Brazil	AM%sT	1994 Sep 22
			-4:00	-	AMT
Zone America/Eirunepe	-4:39:28 -	LMT	1914
			-5:00	Brazil	AC%sT	1988 Sep 12
			-5:00	-	ACT	1993 Sep 28
			-5:00	Brazil	AC%sT	1994 Sep 22
			-5:00	-	ACT
Zone America/Porto_Acre	-4:31:12 -	LMT	1914
			-5:00	Brazil	AC%sT	1988 Sep 12
			-5:00	-	ACT





Zone America/Santiago	-4:42:40 -	LMT	1890
			-4:42:40 -	SMT	1910	    # Santiago Mean Time
			-5:00	Chile	CL%sT	1932 Sep    # Chile Time
			-4:00	Chile	CL%sT
Zone Pacific/Easter	-7:17:28 -	LMT	1890	    # Mataveri
			-7:17:28 -	MMT	1932 Sep    # Mataveri Mean Time
			-7:00	Chile	EAS%sT	1982 Mar 14 # Easter I Time
			-6:00	Chile	EAS%sT


Zone	America/Bogota	-4:56:20 -	LMT	1884 Mar 13
			-4:56:20 -	BMT	1914 Nov 23 # Bogota Mean Time
			-5:00	CO	CO%sT	# Colombia Time

Zone	America/Curacao	-4:35:44 -	LMT	1912 Feb 12	# Willemstad
			-4:30	-	ANT	1965 # Netherlands Antilles Time
			-4:00	-	AST

Zone America/Guayaquil	-5:19:20 -	LMT	1890
			-5:14:00 -	QMT	1931 # Quito Mean Time
			-5:00	-	ECT	     # Ecuador Time
Zone Pacific/Galapagos	-5:58:24 -	LMT	1931 # Puerto Baquerizo Moreno
			-5:00	-	ECT	1986
			-6:00	-	GALT	     # Galapagos Time

Zone Atlantic/Stanley	-3:51:24 -	LMT	1890
			-3:51:24 -	SMT	1912 Mar 12  # Stanley Mean Time
			-4:00	Falk	FK%sT	1983 May     # Falkland Is Time
			-3:00	Falk	FK%sT	1985 Sep 15
			-4:00	Falk	FK%sT

Zone America/Cayenne	-3:29:20 -	LMT	1911 Jul
			-4:00	-	GFT	1967 Oct # French Guiana Time
			-3:00	-	GFT

Zone	America/Guyana	-3:52:40 -	LMT	1915 Mar	# Georgetown
			-3:45	-	GBGT	1966 May 26 # Br Guiana Time
			-3:45	-	GYT	1975 Jul 31 # Guyana Time
			-3:00	-	GYT	1991
			-4:00	-	GYT

Zone America/Asuncion	-3:50:40 -	LMT	1890
			-3:50:40 -	AMT	1931 Oct 10 # Asuncion Mean Time
			-4:00	-	PYT	1972 Oct # Paraguay Time
			-3:00	-	PYT	1974 Apr
			-4:00	Para	PY%sT

Zone	America/Lima	-5:08:12 -	LMT	1890
			-5:09	-	LMT	1908 Jul 28 # Lima Mean Time
			-5:00	Peru	PE%sT	# Peru Time

Zone Atlantic/South_Georgia -2:26:08 -	LMT	1890		# Grytviken
			-2:00	-	GST	# South Georgia Time


Zone America/Paramaribo	-3:40:40 -	LMT	1911
			-3:40:52 -	PMT	1935     # Paramaribo Mean Time
			-3:40:36 -	PMT	1945 Oct # The capital moved?
			-3:30	-	NEGT	1975 Nov 20 # Dutch Guiana Time
			-3:30	-	SRT	1984 Oct # Suriname Time
			-3:00	-	SRT

Zone America/Port_of_Spain -4:06:04 -	LMT	1912 Mar 2
			-4:00	-	AST

Zone America/Montevideo	-3:44:44 -	LMT	1898 Jun 28
			-3:44:44 -	MMT	1920 May  1	# Montevideo MT
			-3:30	Uruguay	UY%sT	1942 Dec 14	# Uruguay Time
			-3:00	Uruguay	UY%sT

Zone	America/Caracas	-4:27:44 -	LMT	1890
			-4:27:44 -	CMT	1912 Feb 12  # Caracas Mean Time
			-4:30	-	VET	1965	     # Venezuela Time
			-4:00	-	VET



Zone	SystemV/AST4ADT	-4:00	SystemV		A%sT
Zone	SystemV/EST5EDT	-5:00	SystemV		E%sT
Zone	SystemV/CST6CDT	-6:00	SystemV		C%sT
Zone	SystemV/MST7MDT	-7:00	SystemV		M%sT
Zone	SystemV/PST8PDT	-8:00	SystemV		P%sT
Zone	SystemV/YST9YDT	-9:00	SystemV		Y%sT
Zone	SystemV/AST4	-4:00	-		AST
Zone	SystemV/EST5	-5:00	-		EST
Zone	SystemV/CST6	-6:00	-		CST
Zone	SystemV/MST7	-7:00	-		MST
Zone	SystemV/PST8	-8:00	-		PST
Zone	SystemV/YST9	-9:00	-		YST
Zone	SystemV/HST10	-10:00	-		HST
Link	Antarctica/McMurdo	Antarctica/South_Pole
Link	Asia/Nicosia	Europe/Nicosia
Link	Etc/GMT				GMT
Link	Etc/UTC				Etc/Universal
Link	Etc/UTC				Etc/Zulu
Link	Etc/GMT				Etc/Greenwich
Link	Etc/GMT				Etc/GMT-0
Link	Etc/GMT				Etc/GMT+0
Link	Etc/GMT				Etc/GMT0
Link	Europe/Rome	Europe/Vatican
Link	Europe/Rome	Europe/San_Marino
Link	Europe/Oslo	Arctic/Longyearbyen
Link Europe/Prague Europe/Bratislava
Link	Europe/Istanbul	Asia/Istanbul	# Istanbul is in both continents.
Link Europe/Belgrade Europe/Ljubljana	# Slovenia
Link Europe/Belgrade Europe/Sarajevo	# Bosnia and Herzegovina
Link Europe/Belgrade Europe/Skopje	# Macedonia
Link Europe/Belgrade Europe/Zagreb	# Croatia
Link America/Denver America/Shiprock
Link America/Indianapolis America/Indiana/Indianapolis
Link America/Louisville America/Kentucky/Louisville
# Link	LINK-FROM		LINK-TO
Link	America/New_York	EST5EDT
Link	America/Chicago		CST6CDT
Link	America/Denver		MST7MDT
Link	America/Los_Angeles	PST8PDT
Link	America/Indianapolis	EST
Link	America/Phoenix		MST
Link	Pacific/Honolulu	HST
Link	America/Los_Angeles	US/Pacific-New	##
Link	Asia/Riyadh87	Mideast/Riyadh87
Link	Asia/Riyadh88	Mideast/Riyadh88
Link	Asia/Riyadh89	Mideast/Riyadh89
Rule	Algeria	1916	only	-	Jun	14	23:00s	1:00	S
Rule	Algeria	1916	1919	-	Oct	Sun<=7	23:00s	0	-
Rule	Algeria	1917	only	-	Mar	24	23:00s	1:00	S
Rule	Algeria	1918	only	-	Mar	 9	23:00s	1:00	S
Rule	Algeria	1919	only	-	Mar	 1	23:00s	1:00	S
Rule	Algeria	1920	only	-	Feb	14	23:00s	1:00	S
Rule	Algeria	1920	only	-	Oct	23	23:00s	0	-
Rule	Algeria	1921	only	-	Mar	14	23:00s	1:00	S
Rule	Algeria	1921	only	-	Jun	21	23:00s	0	-
Rule	Algeria	1939	only	-	Sep	11	23:00s	1:00	S
Rule	Algeria	1939	only	-	Nov	19	 1:00	0	-
Rule	Algeria	1944	1945	-	Apr	Mon<=7	 2:00	1:00	S
Rule	Algeria	1944	only	-	Oct	 8	 2:00	0	-
Rule	Algeria	1945	only	-	Sep	16	 1:00	0	-
Rule	Algeria	1971	only	-	Apr	25	23:00s	1:00	S
Rule	Algeria	1971	only	-	Sep	26	23:00s	0	-
Rule	Algeria	1977	only	-	May	 6	 0:00	1:00	S
Rule	Algeria	1977	only	-	Oct	21	 0:00	0	-
Rule	Algeria	1978	only	-	Mar	24	 1:00	1:00	S
Rule	Algeria	1978	only	-	Sep	22	 3:00	0	-
Rule	Algeria	1980	only	-	Apr	25	 0:00	1:00	S
Rule	Algeria	1980	only	-	Oct	31	 2:00	0	-
Rule	Egypt	1940	only	-	Jul	15	0:00	1:00	S
Rule	Egypt	1940	only	-	Oct	 1	0:00	0	-
Rule	Egypt	1941	only	-	Apr	15	0:00	1:00	S
Rule	Egypt	1941	only	-	Sep	16	0:00	0	-
Rule	Egypt	1942	1944	-	Apr	 1	0:00	1:00	S
Rule	Egypt	1942	only	-	Oct	27	0:00	0	-
Rule	Egypt	1943	1945	-	Nov	 1	0:00	0	-
Rule	Egypt	1945	only	-	Apr	16	0:00	1:00	S
Rule	Egypt	1957	only	-	May	10	0:00	1:00	S
Rule	Egypt	1957	1958	-	Oct	 1	0:00	0	-
Rule	Egypt	1958	only	-	May	 1	0:00	1:00	S
Rule	Egypt	1959	1981	-	May	 1	1:00	1:00	S
Rule	Egypt	1959	1965	-	Sep	30	3:00	0	-
Rule	Egypt	1966	1994	-	Oct	 1	3:00	0	-
Rule	Egypt	1982	only	-	Jul	25	1:00	1:00	S
Rule	Egypt	1983	only	-	Jul	12	1:00	1:00	S
Rule	Egypt	1984	1988	-	May	 1	1:00	1:00	S
Rule	Egypt	1989	only	-	May	 6	1:00	1:00	S
Rule	Egypt	1990	1994	-	May	 1	1:00	1:00	S
Rule	Egypt	1995	max	-	Apr	lastFri	 0:00s	1:00	S
Rule	Egypt	1995	max	-	Sep	lastThu	23:00s	0	-
Rule	Ghana	1936	1942	-	Sep	 1	0:00	0:20	GHST
Rule	Ghana	1936	1942	-	Dec	31	0:00	0	GMT
Rule	Libya	1951	only	-	Oct	14	2:00	1:00	S
Rule	Libya	1952	only	-	Jan	 1	0:00	0	-
Rule	Libya	1953	only	-	Oct	 9	2:00	1:00	S
Rule	Libya	1954	only	-	Jan	 1	0:00	0	-
Rule	Libya	1955	only	-	Sep	30	0:00	1:00	S
Rule	Libya	1956	only	-	Jan	 1	0:00	0	-
Rule	Libya	1982	1984	-	Apr	 1	0:00	1:00	S
Rule	Libya	1982	1985	-	Oct	 1	0:00	0	-
Rule	Libya	1985	only	-	Apr	 6	0:00	1:00	S
Rule	Libya	1986	only	-	Apr	 4	0:00	1:00	S
Rule	Libya	1986	only	-	Oct	 3	0:00	0	-
Rule	Libya	1987	1989	-	Apr	 1	0:00	1:00	S
Rule	Libya	1987	1990	-	Oct	 1	0:00	0	-
Rule	Morocco	1939	only	-	Sep	12	 0:00	1:00	S
Rule	Morocco	1939	only	-	Nov	19	 0:00	0	-
Rule	Morocco	1940	only	-	Feb	25	 0:00	1:00	S
Rule	Morocco	1945	only	-	Nov	18	 0:00	0	-
Rule	Morocco	1950	only	-	Jun	11	 0:00	1:00	S
Rule	Morocco	1950	only	-	Oct	29	 0:00	0	-
Rule	Morocco	1967	only	-	Jun	 3	12:00	1:00	S
Rule	Morocco	1967	only	-	Oct	 1	 0:00	0	-
Rule	Morocco	1974	only	-	Jun	24	 0:00	1:00	S
Rule	Morocco	1974	only	-	Sep	 1	 0:00	0	-
Rule	Morocco	1976	1977	-	May	 1	 0:00	1:00	S
Rule	Morocco	1976	only	-	Aug	 1	 0:00	0	-
Rule	Morocco	1977	only	-	Sep	28	 0:00	0	-
Rule	Morocco	1978	only	-	Jun	 1	 0:00	1:00	S
Rule	Morocco	1978	only	-	Aug	 4	 0:00	0	-
Rule	Namibia	1994	max	-	Sep	Sun>=1	2:00	1:00	S
Rule	Namibia	1995	max	-	Apr	Sun>=1	2:00	0	-
Rule	SL	1935	1942	-	Jun	 1	0:00	0:40	SLST
Rule	SL	1935	1942	-	Oct	 1	0:00	0	WAT
Rule	SL	1957	1962	-	Jun	 1	0:00	1:00	SLST
Rule	SL	1957	1962	-	Sep	 1	0:00	0	GMT
Rule	SA	1942	1943	-	Sep	Sun>=15	2:00	1:00	-
Rule	SA	1943	1944	-	Mar	Sun>=15	2:00	0	-
Rule	Sudan	1970	only	-	May	 1	0:00	1:00	S
Rule	Sudan	1970	1985	-	Oct	15	0:00	0	-
Rule	Sudan	1971	only	-	Apr	30	0:00	1:00	S
Rule	Sudan	1972	1985	-	Apr	lastSun	0:00	1:00	S
Rule	Tunisia	1939	only	-	Apr	15	23:00s	1:00	S
Rule	Tunisia	1939	only	-	Nov	18	23:00s	0	-
Rule	Tunisia	1940	only	-	Feb	25	23:00s	1:00	S
Rule	Tunisia	1941	only	-	Oct	 6	 0:00	0	-
Rule	Tunisia	1942	only	-	Mar	 9	 0:00	1:00	S
Rule	Tunisia	1942	only	-	Nov	 2	 3:00	0	-
Rule	Tunisia	1943	only	-	Mar	29	 2:00	1:00	S
Rule	Tunisia	1943	only	-	Apr	17	 2:00	0	-
Rule	Tunisia	1943	only	-	Apr	25	 2:00	1:00	S
Rule	Tunisia	1943	only	-	Oct	 4	 2:00	0	-
Rule	Tunisia	1944	1945	-	Apr	Mon>=1	 2:00	1:00	S
Rule	Tunisia	1944	only	-	Oct	 8	 0:00	0	-
Rule	Tunisia	1945	only	-	Sep	16	 0:00	0	-
Rule	Tunisia	1977	only	-	Apr	30	 0:00s	1:00	S
Rule	Tunisia	1977	only	-	Sep	24	 0:00s	0	-
Rule	Tunisia	1978	only	-	May	 1	 0:00s	1:00	S
Rule	Tunisia	1978	only	-	Oct	 1	 0:00s	0	-
Rule	Tunisia	1988	only	-	Jun	 1	 0:00s	1:00	S
Rule	Tunisia	1988	1990	-	Sep	lastSun	 0:00s	0	-
Rule	Tunisia	1989	only	-	Mar	26	 0:00s	1:00	S
Rule	Tunisia	1990	only	-	May	 1	 0:00s	1:00	S
Rule	ArgAQ	1964	1966	-	Mar	 1	0:00	0	-
Rule	ArgAQ	1964	1966	-	Oct	15	0:00	1:00	S
Rule	ArgAQ	1967	only	-	Apr	 1	0:00	0	-
Rule	ArgAQ	1967	1968	-	Oct	Sun<=7	0:00	1:00	S
Rule	ArgAQ	1968	1969	-	Apr	Sun<=7	0:00	0	-
Rule	ArgAQ	1974	only	-	Jan	23	0:00	1:00	S
Rule	ArgAQ	1974	only	-	May	 1	0:00	0	-
Rule	ArgAQ	1974	1976	-	Oct	Sun<=7	0:00	1:00	S
Rule	ArgAQ	1975	1977	-	Apr	Sun<=7	0:00	0	-
Rule	ChileAQ	1969	1997	-	Oct	Sun>=9	0:00	1:00	S
Rule	ChileAQ	1970	1998	-	Mar	Sun>=9	0:00	0	-
Rule	ChileAQ	1998	only	-	Sep	27	0:00	1:00	S
Rule	ChileAQ	1999	only	-	Apr	 4	0:00	0	-
Rule	ChileAQ	1999	max	-	Oct	Sun>=9	0:00	1:00	S
Rule	ChileAQ	2000	max	-	Mar	Sun>=9	0:00	0	-
Rule	NZAQ	1974	only	-	Nov	 3	2:00s	1:00	D
Rule	NZAQ	1975	1988	-	Oct	lastSun	2:00s	1:00	D
Rule	NZAQ	1989	only	-	Oct	 8	2:00s	1:00	D
Rule	NZAQ	1990	max	-	Oct	Sun>=1	2:00s	1:00	D
Rule	NZAQ	1975	only	-	Feb	23	2:00s	0	S
Rule	NZAQ	1976	1989	-	Mar	Sun>=1	2:00s	0	S
Rule	NZAQ	1990	max	-	Mar	Sun>=15	2:00s	0	S
Rule	EUAsia	1981	max	-	Mar	lastSun	 1:00u	1:00	S
Rule	EUAsia	1996	max	-	Oct	lastSun	 1:00u	0	-
Rule E-EurAsia	1981	max	-	Mar	lastSun	 0:00	1:00	S
Rule E-EurAsia	1979	1995	-	Sep	lastSun	 0:00	0	-
Rule E-EurAsia	1996	max	-	Oct	lastSun	 0:00	0	-
Rule RussiaAsia	1981	1984	-	Apr	1	 0:00	1:00	S
Rule RussiaAsia	1981	1983	-	Oct	1	 0:00	0	-
Rule RussiaAsia	1984	1991	-	Sep	lastSun	 2:00s	0	-
Rule RussiaAsia	1985	1991	-	Mar	lastSun	 2:00s	1:00	S
Rule RussiaAsia	1992	only	-	Mar	lastSat	23:00	1:00	S
Rule RussiaAsia	1992	only	-	Sep	lastSat	23:00	0	-
Rule RussiaAsia	1993	max	-	Mar	lastSun	 2:00s	1:00	S
Rule RussiaAsia	1993	1995	-	Sep	lastSun	 2:00s	0	-
Rule RussiaAsia	1996	max	-	Oct	lastSun	 2:00s	0	-
Rule	Azer	1997	max	-	Mar	lastSun	 1:00	1:00	S
Rule	Azer	1997	max	-	Oct	lastSun	 1:00	0	-
Rule	Shang	1940	only	-	Jun	 3	0:00	1:00	D
Rule	Shang	1940	1941	-	Oct	 1	0:00	0	S
Rule	Shang	1941	only	-	Mar	16	0:00	1:00	D
Rule	PRC	1949	only	-	Jan	 1	0:00	0	S
Rule	PRC	1986	only	-	May	 4	0:00	1:00	D
Rule	PRC	1986	1991	-	Sep	Sun>=11	0:00	0	S
Rule	PRC	1987	1991	-	Apr	Sun>=10	0:00	1:00	D
Rule	HK	1946	only	-	Apr	20	3:30	1:00	S
Rule	HK	1946	only	-	Dec	1	3:30	0	-
Rule	HK	1947	only	-	Apr	13	3:30	1:00	S
Rule	HK	1947	only	-	Dec	30	3:30	0	-
Rule	HK	1948	only	-	May	2	3:30	1:00	S
Rule	HK	1948	1952	-	Oct	lastSun	3:30	0	-
Rule	HK	1949	1953	-	Apr	Sun>=1	3:30	1:00	S
Rule	HK	1953	only	-	Nov	1	3:30	0	-
Rule	HK	1954	1964	-	Mar	Sun>=18	3:30	1:00	S
Rule	HK	1954	only	-	Oct	31	3:30	0	-
Rule	HK	1955	1964	-	Nov	Sun>=1	3:30	0	-
Rule	HK	1965	1977	-	Apr	Sun>=16	3:30	1:00	S
Rule	HK	1965	1977	-	Oct	Sun>=16	3:30	0	-
Rule	HK	1979	1980	-	May	Sun>=8	3:30	1:00	S
Rule	HK	1979	1980	-	Oct	Sun>=16	3:30	0	-
Rule	Taiwan	1945	1951	-	May	1	0:00	1:00	D
Rule	Taiwan	1945	1951	-	Oct	1	0:00	0	S
Rule	Taiwan	1952	only	-	Mar	1	0:00	1:00	D
Rule	Taiwan	1952	1954	-	Nov	1	0:00	0	S
Rule	Taiwan	1953	1959	-	Apr	1	0:00	1:00	D
Rule	Taiwan	1955	1961	-	Oct	1	0:00	0	S
Rule	Taiwan	1960	1961	-	Jun	1	0:00	1:00	D
Rule	Taiwan	1974	1975	-	Apr	1	0:00	1:00	D
Rule	Taiwan	1974	1975	-	Oct	1	0:00	0	S
Rule	Taiwan	1980	only	-	Jun	30	0:00	1:00	D
Rule	Taiwan	1980	only	-	Sep	30	0:00	0	S
Rule	Macao	1961	1962	-	Mar	Sun>=16	3:30	1:00	S
Rule	Macao	1961	1964	-	Nov	Sun>=1	3:30	0	-
Rule	Macao	1963	only	-	Mar	Sun>=16	0:00	1:00	S
Rule	Macao	1964	only	-	Mar	Sun>=16	3:30	1:00	S
Rule	Macao	1965	only	-	Mar	Sun>=16	0:00	1:00	S
Rule	Macao	1965	only	-	Oct	31	0:00	0	-
Rule	Macao	1966	1971	-	Apr	Sun>=16	3:30	1:00	S
Rule	Macao	1966	1971	-	Oct	Sun>=16	3:30	0	-
Rule	Macao	1972	1974	-	Apr	Sun>=15	0:00	1:00	S
Rule	Macao	1972	1973	-	Oct	Sun>=15	0:00	0	-
Rule	Macao	1974	1977	-	Oct	Sun>=15	3:30	0	-
Rule	Macao	1975	1977	-	Apr	Sun>=15	3:30	1:00	S
Rule	Macao	1978	1980	-	Apr	Sun>=15	0:00	1:00	S
Rule	Macao	1978	1980	-	Oct	Sun>=15	0:00	0	-
Rule	Cyprus	1975	only	-	Apr	13	0:00	1:00	S
Rule	Cyprus	1975	only	-	Oct	12	0:00	0	-
Rule	Cyprus	1976	only	-	May	15	0:00	1:00	S
Rule	Cyprus	1976	only	-	Oct	11	0:00	0	-
Rule	Cyprus	1977	1980	-	Apr	Sun>=1	0:00	1:00	S
Rule	Cyprus	1977	only	-	Sep	25	0:00	0	-
Rule	Cyprus	1978	only	-	Oct	2	0:00	0	-
Rule	Cyprus	1979	1997	-	Sep	lastSun	0:00	0	-
Rule	Cyprus	1981	1998	-	Mar	lastSun	0:00	1:00	S
Rule	Iran	1978	1980	-	Mar	21	0:00	1:00	S
Rule	Iran	1978	only	-	Oct	21	0:00	0	-
Rule	Iran	1979	only	-	Sep	19	0:00	0	-
Rule	Iran	1980	only	-	Sep	23	0:00	0	-
Rule	Iran	1991	only	-	May	 3	0:00s	1:00	S
Rule	Iran	1991	only	-	Sep	20	0:00s	0	-
Rule	Iran	1992	1995	-	Mar	21	0:00	1:00	S
Rule	Iran	1992	1995	-	Sep	23	0:00	0	-
Rule	Iran	1996	only	-	Mar	20	0:00	1:00	S
Rule	Iran	1996	only	-	Sep	22	0:00	0	-
Rule	Iran	1997	1999	-	Mar	21	0:00	1:00	S
Rule	Iran	1997	1999	-	Sep	23	0:00	0	-
Rule	Iran	2000	only	-	Mar	20	0:00	1:00	S
Rule	Iran	2000	only	-	Sep	22	0:00	0	-
Rule	Iran	2001	2003	-	Mar	21	0:00	1:00	S
Rule	Iran	2001	2003	-	Sep	23	0:00	0	-
Rule	Iran	2004	only	-	Mar	20	0:00	1:00	S
Rule	Iran	2004	only	-	Sep	22	0:00	0	-
Rule	Iran	2005	2007	-	Mar	21	0:00	1:00	S
Rule	Iran	2005	2007	-	Sep	23	0:00	0	-
Rule	Iran	2008	only	-	Mar	20	0:00	1:00	S
Rule	Iran	2008	only	-	Sep	22	0:00	0	-
Rule	Iran	2009	2011	-	Mar	21	0:00	1:00	S
Rule	Iran	2009	2011	-	Sep	23	0:00	0	-
Rule	Iran	2012	only	-	Mar	20	0:00	1:00	S
Rule	Iran	2012	only	-	Sep	22	0:00	0	-
Rule	Iran	2013	2015	-	Mar	21	0:00	1:00	S
Rule	Iran	2013	2015	-	Sep	23	0:00	0	-
Rule	Iran	2016	only	-	Mar	20	0:00	1:00	S
Rule	Iran	2016	only	-	Sep	22	0:00	0	-
Rule	Iran	2017	2019	-	Mar	21	0:00	1:00	S
Rule	Iran	2017	2019	-	Sep	23	0:00	0	-
Rule	Iran	2020	only	-	Mar	20	0:00	1:00	S
Rule	Iran	2020	only	-	Sep	22	0:00	0	-
Rule	Iran	2021	2023	-	Mar	21	0:00	1:00	S
Rule	Iran	2021	2023	-	Sep	23	0:00	0	-
Rule	Iran	2024	2025	-	Mar	20	0:00	1:00	S
Rule	Iran	2024	2025	-	Sep	22	0:00	0	-
Rule	Iran	2026	2027	-	Mar	21	0:00	1:00	S
Rule	Iran	2026	2027	-	Sep	23	0:00	0	-
Rule	Iran	2028	2029	-	Mar	20	0:00	1:00	S
Rule	Iran	2028	2029	-	Sep	22	0:00	0	-
Rule	Iran	2030	2031	-	Mar	21	0:00	1:00	S
Rule	Iran	2030	2031	-	Sep	23	0:00	0	-
Rule	Iran	2032	2033	-	Mar	20	0:00	1:00	S
Rule	Iran	2032	2033	-	Sep	22	0:00	0	-
Rule	Iran	2034	2035	-	Mar	21	0:00	1:00	S
Rule	Iran	2034	2035	-	Sep	23	0:00	0	-
Rule	Iran	2036	2037	-	Mar	20	0:00	1:00	S
Rule	Iran	2036	2037	-	Sep	22	0:00	0	-
Rule	Iraq	1982	only	-	May	1	0:00	1:00	D
Rule	Iraq	1982	1984	-	Oct	1	0:00	0	S
Rule	Iraq	1983	only	-	Mar	31	0:00	1:00	D
Rule	Iraq	1984	1985	-	Apr	1	0:00	1:00	D
Rule	Iraq	1985	1990	-	Sep	lastSun	1:00s	0	S
Rule	Iraq	1986	1990	-	Mar	lastSun	1:00s	1:00	D
Rule	Iraq	1991	max	-	Apr	 1	3:00s	1:00	D
Rule	Iraq	1991	max	-	Oct	 1	3:00s	0	S
Rule	Zion	1940	only	-	Jun	 1	0:00	1:00	D
Rule	Zion	1942	1944	-	Nov	 1	0:00	0	S
Rule	Zion	1943	only	-	Apr	 1	2:00	1:00	D
Rule	Zion	1944	only	-	Apr	 1	0:00	1:00	D
Rule	Zion	1945	only	-	Apr	16	0:00	1:00	D
Rule	Zion	1945	only	-	Nov	 1	2:00	0	S
Rule	Zion	1946	only	-	Apr	16	2:00	1:00	D
Rule	Zion	1946	only	-	Nov	 1	0:00	0	S
Rule	Zion	1948	only	-	May	23	0:00	2:00	DD
Rule	Zion	1948	only	-	Sep	 1	0:00	1:00	D
Rule	Zion	1948	1949	-	Nov	 1	2:00	0	S
Rule	Zion	1949	only	-	May	 1	0:00	1:00	D
Rule	Zion	1950	only	-	Apr	16	0:00	1:00	D
Rule	Zion	1950	only	-	Sep	15	3:00	0	S
Rule	Zion	1951	only	-	Apr	 1	0:00	1:00	D
Rule	Zion	1951	only	-	Nov	11	3:00	0	S
Rule	Zion	1952	only	-	Apr	20	2:00	1:00	D
Rule	Zion	1952	only	-	Oct	19	3:00	0	S
Rule	Zion	1953	only	-	Apr	12	2:00	1:00	D
Rule	Zion	1953	only	-	Sep	13	3:00	0	S
Rule	Zion	1954	only	-	Jun	13	0:00	1:00	D
Rule	Zion	1954	only	-	Sep	12	0:00	0	S
Rule	Zion	1955	only	-	Jun	11	2:00	1:00	D
Rule	Zion	1955	only	-	Sep	11	0:00	0	S
Rule	Zion	1956	only	-	Jun	 3	0:00	1:00	D
Rule	Zion	1956	only	-	Sep	30	3:00	0	S
Rule	Zion	1957	only	-	Apr	29	2:00	1:00	D
Rule	Zion	1957	only	-	Sep	22	0:00	0	S
Rule	Zion	1974	only	-	Jul	 7	0:00	1:00	D
Rule	Zion	1974	only	-	Oct	13	0:00	0	S
Rule	Zion	1975	only	-	Apr	20	0:00	1:00	D
Rule	Zion	1975	only	-	Aug	31	0:00	0	S
Rule	Zion	1985	only	-	Apr	14	0:00	1:00	D
Rule	Zion	1985	only	-	Sep	15	0:00	0	S
Rule	Zion	1986	only	-	May	18	0:00	1:00	D
Rule	Zion	1986	only	-	Sep	 7	0:00	0	S
Rule	Zion	1987	only	-	Apr	15	0:00	1:00	D
Rule	Zion	1987	only	-	Sep	13	0:00	0	S
Rule	Zion	1988	only	-	Apr	 9	0:00	1:00	D
Rule	Zion	1988	only	-	Sep	 3	0:00	0	S
Rule	Zion	1989	only	-	Apr	30	0:00	1:00	D
Rule	Zion	1989	only	-	Sep	 3	0:00	0	S
Rule	Zion	1990	only	-	Mar	25	0:00	1:00	D
Rule	Zion	1990	only	-	Aug	26	0:00	0	S
Rule	Zion	1991	only	-	Mar	24	0:00	1:00	D
Rule	Zion	1991	only	-	Sep	 1	0:00	0	S
Rule	Zion	1992	only	-	Mar	29	0:00	1:00	D
Rule	Zion	1992	only	-	Sep	 6	0:00	0	S
Rule	Zion	1993	only	-	Apr	 2	0:00	1:00	D
Rule	Zion	1993	only	-	Sep	 5	0:00	0	S
Rule	Zion	1994	only	-	Apr	 1	0:00	1:00	D
Rule	Zion	1994	only	-	Aug	28	0:00	0	S
Rule	Zion	1995	only	-	Mar	31	0:00	1:00	D
Rule	Zion	1995	only	-	Sep	 3	0:00	0	S
Rule	Zion	1996	only	-	Mar	15	0:00	1:00	D
Rule	Zion	1996	only	-	Sep	16	0:00	0	S
Rule	Zion	1997	only	-	Mar	21	0:00	1:00	D
Rule	Zion	1997	only	-	Sep	14	0:00	0	S
Rule	Zion	1998	only	-	Mar	20	0:00	1:00	D
Rule	Zion	1998	only	-	Sep	 6	0:00	0	S
Rule	Zion	1999	only	-	Apr	 2	2:00	1:00	D
Rule	Zion	1999	only	-	Sep	 3	2:00	0	S
Rule	Zion	2000	only	-	Apr	14	2:00	1:00	D
Rule	Zion	2000	only	-	Oct	 6	1:00	0	S
Rule	Zion	2001	only	-	Apr	 9	1:00	1:00	D
Rule	Zion	2001	only	-	Sep	24	1:00	0	S
Rule	Zion	2002	only	-	Mar	29	1:00	1:00	D
Rule	Zion	2002	only	-	Oct	 7	1:00	0	S
Rule	Zion	2003	only	-	Mar	28	1:00	1:00	D
Rule	Zion	2003	only	-	Oct	 3	1:00	0	S
Rule	Zion	2004	only	-	Apr	 7	1:00	1:00	D
Rule	Zion	2004	only	-	Sep	22	1:00	0	S
Rule	Zion	2005	max	-	Apr	 1	1:00	1:00	D
Rule	Zion	2005	max	-	Oct	 1	1:00	0	S
Rule    Jordan	1973	only	-	Jun	6	0:00	1:00	S
Rule    Jordan	1973	1975	-	Oct	1	0:00	0	-
Rule    Jordan	1974	1977	-	May	1	0:00	1:00	S
Rule    Jordan	1976	only	-	Nov	1	0:00	0	-
Rule    Jordan	1977	only	-	Oct	1	0:00	0	-
Rule    Jordan	1978	only	-	Apr	30	0:00	1:00	S
Rule    Jordan	1978	only	-	Sep	30	0:00	0	-
Rule    Jordan	1985	only	-	Apr	1	0:00	1:00	S
Rule    Jordan	1985	only	-	Oct	1	0:00	0	-
Rule    Jordan	1986	1988	-	Apr	Fri>=1	0:00	1:00	S
Rule    Jordan	1986	1990	-	Oct	Fri>=1	0:00	0	-
Rule    Jordan	1989	only	-	May	8	0:00	1:00	S
Rule    Jordan	1990	only	-	Apr	27	0:00	1:00	S
Rule    Jordan	1991	only	-	Apr	17	0:00	1:00	S
Rule    Jordan	1991	only	-	Sep	27	0:00	0	-
Rule    Jordan	1992	only	-	Apr	10	0:00	1:00	S
Rule    Jordan	1992	1993	-	Oct	Fri>=1	0:00	0	-
Rule    Jordan	1993	1998	-	Apr	Fri>=1	0:00	1:00	S
Rule    Jordan	1994	only	-	Sep	Fri>=15	0:00	0	-
Rule    Jordan	1995	1998	-	Sep	Fri>=15	0:00s	0	-
Rule	Jordan	1999	only	-	Jul	 1	0:00s	1:00	S
Rule	Jordan	1999	max	-	Sep	lastThu	0:00s	0	-
Rule	Jordan	2000	max	-	Mar	lastThu	0:00s	1:00	S
Rule	Kirgiz	1992	1996	-	Apr	Sun>=7	0:00	1:00	S
Rule	Kirgiz	1992	1996	-	Sep	lastSun	0:00	0	-
Rule	Kirgiz	1997	max	-	Mar	lastSun	2:30	1:00	S
Rule	Kirgiz	1997	max	-	Oct	lastSun	2:30	0	-
Rule	ROK	1960	only	-	May	15	0:00	1:00	D
Rule	ROK	1960	only	-	Sep	13	0:00	0	S
Rule	ROK	1987	1988	-	May	Sun<=14	0:00	1:00	D
Rule	ROK	1987	1988	-	Oct	Sun<=14	0:00	0	S
Rule	Lebanon	1920	only	-	Mar	28	0:00	1:00	S
Rule	Lebanon	1920	only	-	Oct	25	0:00	0	-
Rule	Lebanon	1921	only	-	Apr	3	0:00	1:00	S
Rule	Lebanon	1921	only	-	Oct	3	0:00	0	-
Rule	Lebanon	1922	only	-	Mar	26	0:00	1:00	S
Rule	Lebanon	1922	only	-	Oct	8	0:00	0	-
Rule	Lebanon	1923	only	-	Apr	22	0:00	1:00	S
Rule	Lebanon	1923	only	-	Sep	16	0:00	0	-
Rule	Lebanon	1957	1961	-	May	1	0:00	1:00	S
Rule	Lebanon	1957	1961	-	Oct	1	0:00	0	-
Rule	Lebanon	1972	only	-	Jun	22	0:00	1:00	S
Rule	Lebanon	1972	1977	-	Oct	1	0:00	0	-
Rule	Lebanon	1973	1977	-	May	1	0:00	1:00	S
Rule	Lebanon	1978	only	-	Apr	30	0:00	1:00	S
Rule	Lebanon	1978	only	-	Sep	30	0:00	0	-
Rule	Lebanon	1984	1987	-	May	1	0:00	1:00	S
Rule	Lebanon	1984	1991	-	Oct	16	0:00	0	-
Rule	Lebanon	1988	only	-	Jun	1	0:00	1:00	S
Rule	Lebanon	1989	only	-	May	10	0:00	1:00	S
Rule	Lebanon	1990	1992	-	May	1	0:00	1:00	S
Rule	Lebanon	1992	only	-	Oct	4	0:00	0	-
Rule	Lebanon	1993	max	-	Mar	lastSun	0:00	1:00	S
Rule	Lebanon	1993	1998	-	Sep	lastSun	0:00	0	-
Rule	Lebanon	1999	max	-	Oct	lastSun	0:00	0	-
Rule	NBorneo	1935	1941	-	Sep	14	0:00	0:20	TS
Rule	NBorneo	1935	1941	-	Dec	14	0:00	0	-
Rule	Mongol	1981	1984	-	Apr	1	0:00	1:00	S
Rule	Mongol	1981	1984	-	Oct	1	0:00	0	-
Rule	Mongol	1985	1990	-	Mar	lastSun	2:00	1:00	S
Rule	Mongol	1985	1990	-	Sep	lastSun	3:00	0	-
Rule	Mongol	1991	1998	-	Mar	lastSun	0:00	1:00	S
Rule	Mongol	1991	1995	-	Sep	lastSun	0:00	0	-
Rule	Mongol	1996	only	-	Oct	lastSun	0:00	0	-
Rule	Mongol	1997	1998	-	Sep	lastSun	0:00	0	-
Rule EgyptAsia	1957	only	-	May	10	0:00	1:00	S
Rule EgyptAsia	1957	1958	-	Oct	 1	0:00	0	-
Rule EgyptAsia	1958	only	-	May	 1	0:00	1:00	S
Rule EgyptAsia	1959	1967	-	May	 1	1:00	1:00	S
Rule EgyptAsia	1959	1965	-	Sep	30	3:00	0	-
Rule EgyptAsia	1966	only	-	Oct	 1	3:00	0	-
Rule Palestine	1999	max	-	Apr	Fri>=15	0:00	1:00	S
Rule Palestine	1999	max	-	Oct	Fri>=15	0:00	0	-
Rule	Phil	1936	only	-	Nov	1	0:00	1:00	S
Rule	Phil	1937	only	-	Feb	1	0:00	0	-
Rule	Phil	1954	only	-	Apr	12	0:00	1:00	S
Rule	Phil	1954	only	-	Jul	1	0:00	0	-
Rule	Phil	1978	only	-	Mar	22	0:00	1:00	S
Rule	Phil	1978	only	-	Sep	21	0:00	0	-
Rule	Syria	1920	1923	-	Apr	Sun>=15	2:00	1:00	S
Rule	Syria	1920	1923	-	Oct	Sun>=1	2:00	0	-
Rule	Syria	1962	only	-	Apr	29	2:00	1:00	S
Rule	Syria	1962	only	-	Oct	1	2:00	0	-
Rule	Syria	1963	1965	-	May	1	2:00	1:00	S
Rule	Syria	1963	only	-	Sep	30	2:00	0	-
Rule	Syria	1964	only	-	Oct	1	2:00	0	-
Rule	Syria	1965	only	-	Sep	30	2:00	0	-
Rule	Syria	1966	only	-	Apr	24	2:00	1:00	S
Rule	Syria	1966	1976	-	Oct	1	2:00	0	-
Rule	Syria	1967	1978	-	May	1	2:00	1:00	S
Rule	Syria	1977	1978	-	Sep	1	2:00	0	-
Rule	Syria	1983	1984	-	Apr	9	2:00	1:00	S
Rule	Syria	1983	1984	-	Oct	1	2:00	0	-
Rule	Syria	1986	only	-	Feb	16	2:00	1:00	S
Rule	Syria	1986	only	-	Oct	9	2:00	0	-
Rule	Syria	1987	only	-	Mar	1	2:00	1:00	S
Rule	Syria	1987	1988	-	Oct	31	2:00	0	-
Rule	Syria	1988	only	-	Mar	15	2:00	1:00	S
Rule	Syria	1989	only	-	Mar	31	2:00	1:00	S
Rule	Syria	1989	only	-	Oct	1	2:00	0	-
Rule	Syria	1990	only	-	Apr	1	2:00	1:00	S
Rule	Syria	1990	only	-	Sep	30	2:00	0	-
Rule	Syria	1991	only	-	Apr	 1	0:00	1:00	S
Rule	Syria	1991	1992	-	Oct	 1	0:00	0	-
Rule	Syria	1992	only	-	Apr	 8	0:00	1:00	S
Rule	Syria	1993	only	-	Mar	26	0:00	1:00	S
Rule	Syria	1993	only	-	Sep	25	0:00	0	-
Rule	Syria	1994	1996	-	Apr	 1	0:00	1:00	S
Rule	Syria	1994	max	-	Oct	 1	0:00	0	-
Rule	Syria	1997	1998	-	Mar	lastMon	0:00	1:00	S
Rule	Syria	1999	max	-	Apr	 1	0:00	1:00	S
Rule	Aus	1917	only	-	Jan	 1	0:01	1:00	-
Rule	Aus	1917	only	-	Mar	25	2:00	0	-
Rule	Aus	1942	only	-	Jan	 1	2:00	1:00	-
Rule	Aus	1942	only	-	Mar	29	2:00	0	-
Rule	Aus	1942	only	-	Sep	27	2:00	1:00	-
Rule	Aus	1943	1944	-	Mar	lastSun	2:00	0	-
Rule	Aus	1943	only	-	Oct	 3	2:00	1:00	-
Rule	AQ	1971	only	-	Oct	lastSun	2:00s	1:00	-
Rule	AQ	1972	only	-	Feb	lastSun	2:00s	0	-
Rule	AQ	1989	1991	-	Oct	lastSun	2:00s	1:00	-
Rule	AQ	1990	1992	-	Mar	Sun>=1	2:00s	0	-
Rule	Holiday	1992	1993	-	Oct	lastSun	2:00s	1:00	-
Rule	Holiday	1993	1994	-	Mar	Sun>=1	2:00s	0	-
Rule	AS	1971	1985	-	Oct	lastSun	2:00s	1:00	-
Rule	AS	1986	only	-	Oct	19	2:00s	1:00	-
Rule	AS	1987	max	-	Oct	lastSun	2:00s	1:00	-
Rule	AS	1972	only	-	Feb	27	2:00s	0	-
Rule	AS	1973	1985	-	Mar	Sun>=1	2:00s	0	-
Rule	AS	1986	1989	-	Mar	Sun>=15	2:00s	0	-
Rule	AS	1990	only	-	Mar	Sun>=18	2:00s	0	-
Rule	AS	1991	only	-	Mar	Sun>=1	2:00s	0	-
Rule	AS	1992	only	-	Mar	Sun>=18	2:00s	0	-
Rule	AS	1993	only	-	Mar	Sun>=1	2:00s	0	-
Rule	AS	1994	only	-	Mar	Sun>=18	2:00s	0	-
Rule	AS	1995	max	-	Mar	lastSun	2:00s	0	-
Rule	AT	1967	only	-	Oct	Sun>=1	2:00s	1:00	-
Rule	AT	1968	only	-	Mar	lastSun	2:00s	0	-
Rule	AT	1968	1985	-	Oct	lastSun	2:00s	1:00	-
Rule	AT	1969	1971	-	Mar	Sun>=8	2:00s	0	-
Rule	AT	1972	only	-	Feb	lastSun	2:00s	0	-
Rule	AT	1973	1981	-	Mar	Sun>=1	2:00s	0	-
Rule	AT	1982	1983	-	Mar	lastSun	2:00s	0	-
Rule	AT	1984	1986	-	Mar	Sun>=1	2:00s	0	-
Rule	AT	1986	only	-	Oct	Sun>=15	2:00s	1:00	-
Rule	AT	1987	1990	-	Mar	Sun>=15	2:00s	0	-
Rule	AT	1987	only	-	Oct	Sun>=22	2:00s	1:00	-
Rule	AT	1988	1990	-	Oct	lastSun	2:00s	1:00	-
Rule	AT	1991	1999	-	Oct	Sun>=1	2:00s	1:00	-
Rule	AT	1991	max	-	Mar	lastSun	2:00s	0	-
Rule	AT	2000	only	-	Aug	lastSun	2:00s	1:00	-
Rule	AT	2001	max	-	Oct	Sun>=1	2:00s	1:00	-
Rule	AV	1971	1985	-	Oct	lastSun	2:00s	1:00	-
Rule	AV	1972	only	-	Feb	lastSun	2:00s	0	-
Rule	AV	1973	1985	-	Mar	Sun>=1	2:00s	0	-
Rule	AV	1986	1990	-	Mar	Sun>=15	2:00s	0	-
Rule	AV	1986	1987	-	Oct	Sun>=15	2:00s	1:00	-
Rule	AV	1988	1999	-	Oct	lastSun	2:00s	1:00	-
Rule	AV	1991	1994	-	Mar	Sun>=1	2:00s	0	-
Rule	AV	1995	max	-	Mar	lastSun	2:00s	0	-
Rule	AV	2000	only	-	Aug	lastSun	2:00s	1:00	-
Rule	AV	2001	max	-	Oct	lastSun	2:00s	1:00	-
Rule	AN	1971	1985	-	Oct	lastSun	2:00s	1:00	-
Rule	AN	1972	only	-	Feb	27	2:00s	0	-
Rule	AN	1973	1981	-	Mar	Sun>=1	2:00s	0	-
Rule	AN	1982	only	-	Apr	Sun>=1	2:00s	0	-
Rule	AN	1983	1985	-	Mar	Sun>=1	2:00s	0	-
Rule	AN	1986	1989	-	Mar	Sun>=15	2:00s	0	-
Rule	AN	1986	only	-	Oct	19	2:00s	1:00	-
Rule	AN	1987	1999	-	Oct	lastSun	2:00s	1:00	-
Rule	AN	1990	1995	-	Mar	Sun>=1	2:00s	0	-
Rule	AN	1996	max	-	Mar	lastSun	2:00s	0	-
Rule	AN	2000	only	-	Aug	lastSun	2:00s	1:00	-
Rule	AN	2001	max	-	Oct	lastSun	2:00s	1:00	-
Rule	LH	1981	1984	-	Oct	lastSun	2:00s	1:00	-
Rule	LH	1982	1985	-	Mar	Sun>=1	2:00s	0	-
Rule	LH	1985	only	-	Oct	lastSun	2:00s	0:30	-
Rule	LH	1986	1989	-	Mar	Sun>=15	2:00s	0	-
Rule	LH	1986	only	-	Oct	19	2:00s	0:30	-
Rule	LH	1987	1999	-	Oct	lastSun	2:00s	0:30	-
Rule	LH	1990	1995	-	Mar	Sun>=1	2:00s	0	-
Rule	LH	1996	max	-	Mar	lastSun	2:00s	0	-
Rule	LH	2000	only	-	Aug	lastSun	2:00s	0:30	-
Rule	LH	2001	max	-	Oct	lastSun	2:00s	0:30	-
Rule	Cook	1978	only	-	Nov	12	0:00	0:30	HS
Rule	Cook	1979	1991	-	Mar	Sun>=1	0:00	0	-
Rule	Cook	1979	1990	-	Oct	lastSun	0:00	0:30	HS
Rule	Fiji	1998	1999	-	Nov	Sun>=1	2:00	1:00	S
Rule	Fiji	1999	2000	-	Feb	lastSun	3:00	0	-
Rule	NC	1977	1978	-	Dec	Sun>=1	0:00	1:00	S
Rule	NC	1978	1979	-	Feb	27	0:00	0	-
Rule	NC	1996	only	-	Dec	 1	2:00s	1:00	S
Rule	NC	1997	only	-	Mar	 2	2:00s	0	-
Rule	NZ	1927	only	-	Nov	26	2:00	0:30	HD
Rule	NZ	1928	1929	-	Mar	Sun>=1	2:00	0	S
Rule	NZ	1928	only	-	Nov	 4	2:00	0:30	HD
Rule	NZ	1929	only	-	Oct	30	2:00	0:30	HD
Rule	NZ	1930	1933	-	Mar	Sun>=15	2:00	0	S
Rule	NZ	1930	1933	-	Oct	Sun>=8	2:00	0:30	HD
Rule	NZ	1934	1940	-	Apr	lastSun	2:00	0	S
Rule	NZ	1934	1939	-	Sep	lastSun	2:00	0:30	HD
Rule	NZ	1974	only	-	Nov	 3	2:00s	1:00	D
Rule	NZ	1975	1988	-	Oct	lastSun	2:00s	1:00	D
Rule	NZ	1989	only	-	Oct	 8	2:00s	1:00	D
Rule	NZ	1990	max	-	Oct	Sun>=1	2:00s	1:00	D
Rule	NZ	1975	only	-	Feb	23	2:00s	0	S
Rule	NZ	1976	1989	-	Mar	Sun>=1	2:00s	0	S
Rule	NZ	1990	max	-	Mar	Sun>=15	2:00s	0	S
Rule	Chatham	1990	max	-	Oct	Sun>=1	2:45s	1:00	D
Rule	Chatham	1991	max	-	Mar	Sun>=15	2:45s	0	S
Rule	Tonga	1999	only	-	Oct	 7	2:00s	1:00	S
Rule	Tonga	2000	only	-	Mar	19	2:00s	0	-
Rule	Tonga	2000	only	-	Nov	 4	2:00s	1:00	S
Rule	Tonga	2001	only	-	Jan	27	2:00s	0	-
Rule	Vanuatu	1983	only	-	Sep	25	0:00	1:00	S
Rule	Vanuatu	1984	1991	-	Mar	Sun>=23	0:00	0	-
Rule	Vanuatu	1984	only	-	Oct	23	0:00	1:00	S
Rule	Vanuatu	1985	1991	-	Sep	Sun>=23	0:00	1:00	S
Rule	Vanuatu	1992	1993	-	Jan	Sun>=23	0:00	0	-
Rule	Vanuatu	1992	only	-	Oct	Sun>=23	0:00	1:00	S
Rule	GB-Eire	1916	only	-	May	21	2:00s	1:00	BST
Rule	GB-Eire	1916	only	-	Oct	 1	2:00s	0	GMT
Rule	GB-Eire	1917	only	-	Apr	 8	2:00s	1:00	BST
Rule	GB-Eire	1917	only	-	Sep	17	2:00s	0	GMT
Rule	GB-Eire	1918	only	-	Mar	24	2:00s	1:00	BST
Rule	GB-Eire	1918	only	-	Sep	30	2:00s	0	GMT
Rule	GB-Eire	1919	only	-	Mar	30	2:00s	1:00	BST
Rule	GB-Eire	1919	only	-	Sep	29	2:00s	0	GMT
Rule	GB-Eire	1920	only	-	Mar	28	2:00s	1:00	BST
Rule	GB-Eire	1920	only	-	Oct	25	2:00s	0	GMT
Rule	GB-Eire	1921	only	-	Apr	 3	2:00s	1:00	BST
Rule	GB-Eire	1921	only	-	Oct	 3	2:00s	0	GMT
Rule	GB-Eire	1922	only	-	Mar	26	2:00s	1:00	BST
Rule	GB-Eire	1922	only	-	Oct	 8	2:00s	0	GMT
Rule	GB-Eire	1923	only	-	Apr	Sun>=16	2:00s	1:00	BST
Rule	GB-Eire	1923	1924	-	Sep	Sun>=16	2:00s	0	GMT
Rule	GB-Eire	1924	only	-	Apr	Sun>=9	2:00s	1:00	BST
Rule	GB-Eire	1925	1926	-	Apr	Sun>=16	2:00s	1:00	BST
Rule	GB-Eire	1925	1938	-	Oct	Sun>=2	2:00s	0	GMT
Rule	GB-Eire	1927	only	-	Apr	Sun>=9	2:00s	1:00	BST
Rule	GB-Eire	1928	1929	-	Apr	Sun>=16	2:00s	1:00	BST
Rule	GB-Eire	1930	only	-	Apr	Sun>=9	2:00s	1:00	BST
Rule	GB-Eire	1931	1932	-	Apr	Sun>=16	2:00s	1:00	BST
Rule	GB-Eire	1933	only	-	Apr	Sun>=9	2:00s	1:00	BST
Rule	GB-Eire	1934	only	-	Apr	Sun>=16	2:00s	1:00	BST
Rule	GB-Eire	1935	only	-	Apr	Sun>=9	2:00s	1:00	BST
Rule	GB-Eire	1936	1937	-	Apr	Sun>=16	2:00s	1:00	BST
Rule	GB-Eire	1938	only	-	Apr	Sun>=9	2:00s	1:00	BST
Rule	GB-Eire	1939	only	-	Apr	Sun>=16	2:00s	1:00	BST
Rule	GB-Eire	1939	only	-	Nov	Sun>=16	2:00s	0	GMT
Rule	GB-Eire	1940	only	-	Feb	Sun>=23	2:00s	1:00	BST
Rule	GB-Eire	1941	only	-	May	Sun>=2	1:00s	2:00	BDST
Rule	GB-Eire	1941	1943	-	Aug	Sun>=9	1:00s	1:00	BST
Rule	GB-Eire	1942	1944	-	Apr	Sun>=2	1:00s	2:00	BDST
Rule	GB-Eire	1944	only	-	Sep	Sun>=16	1:00s	1:00	BST
Rule	GB-Eire	1945	only	-	Apr	Mon>=2	1:00s	2:00	BDST
Rule	GB-Eire	1945	only	-	Jul	Sun>=9	1:00s	1:00	BST
Rule	GB-Eire	1945	1946	-	Oct	Sun>=2	2:00s	0	GMT
Rule	GB-Eire	1946	only	-	Apr	Sun>=9	2:00s	1:00	BST
Rule	GB-Eire	1947	only	-	Mar	16	2:00s	1:00	BST
Rule	GB-Eire	1947	only	-	Apr	13	1:00s	2:00	BDST
Rule	GB-Eire	1947	only	-	Aug	10	1:00s	1:00	BST
Rule	GB-Eire	1947	only	-	Nov	 2	2:00s	0	GMT
Rule	GB-Eire	1948	only	-	Mar	14	2:00s	1:00	BST
Rule	GB-Eire	1948	only	-	Oct	31	2:00s	0	GMT
Rule	GB-Eire	1949	only	-	Apr	 3	2:00s	1:00	BST
Rule	GB-Eire	1949	only	-	Oct	30	2:00s	0	GMT
Rule	GB-Eire	1950	1952	-	Apr	Sun>=14	2:00s	1:00	BST
Rule	GB-Eire	1950	1952	-	Oct	Sun>=21	2:00s	0	GMT
Rule	GB-Eire	1953	only	-	Apr	Sun>=16	2:00s	1:00	BST
Rule	GB-Eire	1953	1960	-	Oct	Sun>=2	2:00s	0	GMT
Rule	GB-Eire	1954	only	-	Apr	Sun>=9	2:00s	1:00	BST
Rule	GB-Eire	1955	1956	-	Apr	Sun>=16	2:00s	1:00	BST
Rule	GB-Eire	1957	only	-	Apr	Sun>=9	2:00s	1:00	BST
Rule	GB-Eire	1958	1959	-	Apr	Sun>=16	2:00s	1:00	BST
Rule	GB-Eire	1960	only	-	Apr	Sun>=9	2:00s	1:00	BST
Rule	GB-Eire	1961	1963	-	Mar	lastSun	2:00s	1:00	BST
Rule	GB-Eire	1961	1968	-	Oct	Sun>=23	2:00s	0	GMT
Rule	GB-Eire	1964	1967	-	Mar	Sun>=19	2:00s	1:00	BST
Rule	GB-Eire	1968	only	-	Feb	18	2:00s	1:00	BST
Rule	GB-Eire	1972	1980	-	Mar	Sun>=16	2:00s	1:00	BST
Rule	GB-Eire	1972	1980	-	Oct	Sun>=23	2:00s	0	GMT
Rule	GB-Eire	1981	1995	-	Mar	lastSun	1:00u	1:00	BST
Rule	GB-Eire 1981	1989	-	Oct	Sun>=23	1:00u	0	GMT
Rule	GB-Eire 1990	1995	-	Oct	Sun>=22	1:00u	0	GMT
Rule	EU	1977	1980	-	Apr	Sun>=1	 1:00u	1:00	S
Rule	EU	1977	only	-	Sep	lastSun	 1:00u	0	-
Rule	EU	1978	only	-	Oct	 1	 1:00u	0	-
Rule	EU	1979	1995	-	Sep	lastSun	 1:00u	0	-
Rule	EU	1981	max	-	Mar	lastSun	 1:00u	1:00	S
Rule	EU	1996	max	-	Oct	lastSun	 1:00u	0	-
Rule	W-Eur	1977	1980	-	Apr	Sun>=1	 1:00s	1:00	S
Rule	W-Eur	1977	only	-	Sep	lastSun	 1:00s	0	-
Rule	W-Eur	1978	only	-	Oct	 1	 1:00s	0	-
Rule	W-Eur	1979	1995	-	Sep	lastSun	 1:00s	0	-
Rule	W-Eur	1981	max	-	Mar	lastSun	 1:00s	1:00	S
Rule	W-Eur	1996	max	-	Oct	lastSun	 1:00s	0	-
Rule	C-Eur	1916	only	-	Apr	30	23:00	1:00	S
Rule	C-Eur	1916	only	-	Oct	 1	 1:00	0	-
Rule	C-Eur	1917	1918	-	Apr	Mon>=15	 2:00s	1:00	S
Rule	C-Eur	1917	1918	-	Sep	Mon>=15	 2:00s	0	-
Rule	C-Eur	1940	only	-	Apr	 1	 2:00s	1:00	S
Rule	C-Eur	1942	only	-	Nov	 2	 2:00s	0	-
Rule	C-Eur	1943	only	-	Mar	29	 2:00s	1:00	S
Rule	C-Eur	1943	only	-	Oct	 4	 2:00s	0	-
Rule	C-Eur	1944	only	-	Apr	 3	 2:00s	1:00	S
Rule	C-Eur	1944	only	-	Oct	 2	 2:00s	0	-
Rule	C-Eur	1977	1980	-	Apr	Sun>=1	 2:00s	1:00	S
Rule	C-Eur	1977	only	-	Sep	lastSun	 2:00s	0	-
Rule	C-Eur	1978	only	-	Oct	 1	 2:00s	0	-
Rule	C-Eur	1979	1995	-	Sep	lastSun	 2:00s	0	-
Rule	C-Eur	1981	max	-	Mar	lastSun	 2:00s	1:00	S
Rule	C-Eur	1996	max	-	Oct	lastSun	 2:00s	0	-
Rule	E-Eur	1977	1980	-	Apr	Sun>=1	 0:00	1:00	S
Rule	E-Eur	1977	only	-	Sep	lastSun	 0:00	0	-
Rule	E-Eur	1978	only	-	Oct	 1	 0:00	0	-
Rule	E-Eur	1979	1995	-	Sep	lastSun	 0:00	0	-
Rule	E-Eur	1981	max	-	Mar	lastSun	 0:00	1:00	S
Rule	E-Eur	1996	max	-	Oct	lastSun	 0:00	0	-
Rule	Russia	1917	only	-	Jul	 1	23:00	1:00	MST	# Moscow Summer Time
Rule	Russia	1917	only	-	Dec	28	 0:00	0	MMT	# Moscow Mean Time
Rule	Russia	1918	only	-	May	31	22:00	2:00	MDST	# Moscow Double Summer Time
Rule	Russia	1918	only	-	Sep	16	 1:00	1:00	MST
Rule	Russia	1919	only	-	May	31	23:00	2:00	MDST
Rule	Russia	1919	only	-	Jul	 1	 2:00	1:00	S
Rule	Russia	1919	only	-	Aug	16	 0:00	0	-
Rule	Russia	1921	only	-	Feb	14	23:00	1:00	S
Rule	Russia	1921	only	-	Mar	20	23:00	2:00	M # Midsummer
Rule	Russia	1921	only	-	Sep	 1	 0:00	1:00	S
Rule	Russia	1921	only	-	Oct	 1	 0:00	0	-
Rule	Russia	1981	1984	-	Apr	 1	 0:00	1:00	S
Rule	Russia	1981	1983	-	Oct	 1	 0:00	0	-
Rule	Russia	1984	1991	-	Sep	lastSun	 2:00s	0	-
Rule	Russia	1985	1991	-	Mar	lastSun	 2:00s	1:00	S
Rule	Russia	1992	only	-	Mar	lastSat	 23:00	1:00	S
Rule	Russia	1992	only	-	Sep	lastSat	 23:00	0	-
Rule	Russia	1993	max	-	Mar	lastSun	 2:00s	1:00	S
Rule	Russia	1993	1995	-	Sep	lastSun	 2:00s	0	-
Rule	Russia	1996	max	-	Oct	lastSun	 2:00s	0	-
Rule	Albania	1940	only	-	Jun	16	0:00	1:00	S
Rule	Albania	1942	only	-	Nov	 2	3:00	0	-
Rule	Albania	1943	only	-	Mar	29	2:00	1:00	S
Rule	Albania	1943	only	-	Apr	10	3:00	0	-
Rule	Albania	1974	only	-	May	 4	0:00	1:00	S
Rule	Albania	1974	only	-	Oct	 2	0:00	0	-
Rule	Albania	1975	only	-	May	 1	0:00	1:00	S
Rule	Albania	1975	only	-	Oct	 2	0:00	0	-
Rule	Albania	1976	only	-	May	 2	0:00	1:00	S
Rule	Albania	1976	only	-	Oct	 3	0:00	0	-
Rule	Albania	1977	only	-	May	 8	0:00	1:00	S
Rule	Albania	1977	only	-	Oct	 2	0:00	0	-
Rule	Albania	1978	only	-	May	 6	0:00	1:00	S
Rule	Albania	1978	only	-	Oct	 1	0:00	0	-
Rule	Albania	1979	only	-	May	 5	0:00	1:00	S
Rule	Albania	1979	only	-	Sep	30	0:00	0	-
Rule	Albania	1980	only	-	May	 3	0:00	1:00	S
Rule	Albania	1980	only	-	Oct	 4	0:00	0	-
Rule	Albania	1981	only	-	Apr	26	0:00	1:00	S
Rule	Albania	1981	only	-	Sep	27	0:00	0	-
Rule	Albania	1982	only	-	May	 2	0:00	1:00	S
Rule	Albania	1982	only	-	Oct	 3	0:00	0	-
Rule	Albania	1983	only	-	Apr	18	0:00	1:00	S
Rule	Albania	1983	only	-	Oct	 1	0:00	0	-
Rule	Albania	1984	only	-	Apr	 1	0:00	1:00	S
Rule	Austria	1920	only	-	Apr	 5	2:00s	1:00	S
Rule	Austria	1920	only	-	Sep	13	2:00s	0	-
Rule	Austria	1945	only	-	Apr	 2	2:00s	1:00	S
Rule	Austria	1945	only	-	Nov	18	2:00s	0	-
Rule	Austria	1946	only	-	Apr	14	2:00s	1:00	S
Rule	Austria	1946	1948	-	Oct	Sun>=1	2:00s	0	-
Rule	Austria	1947	only	-	Apr	 6	2:00s	1:00	S
Rule	Austria	1948	only	-	Apr	18	2:00s	1:00	S
Rule	Belgium	1918	only	-	Mar	 9	 0:00s	1:00	S
Rule	Belgium	1918	1919	-	Oct	Sat>=1	23:00s	0	-
Rule	Belgium	1919	only	-	Mar	 1	23:00s	1:00	S
Rule	Belgium	1920	only	-	Feb	14	23:00s	1:00	S
Rule	Belgium	1920	only	-	Oct	23	23:00s	0	-
Rule	Belgium	1921	only	-	Mar	14	23:00s	1:00	S
Rule	Belgium	1921	only	-	Oct	25	23:00s	0	-
Rule	Belgium	1922	only	-	Mar	25	23:00s	1:00	S
Rule	Belgium	1922	1927	-	Oct	Sat>=1	23:00s	0	-
Rule	Belgium	1923	only	-	Apr	21	23:00s	1:00	S
Rule	Belgium	1924	only	-	Mar	29	23:00s	1:00	S
Rule	Belgium	1925	only	-	Apr	 4	23:00s	1:00	S
Rule	Belgium	1926	only	-	Apr	17	23:00s	1:00	S
Rule	Belgium	1927	only	-	Apr	 9	23:00s	1:00	S
Rule	Belgium	1928	only	-	Apr	14	23:00s	1:00	S
Rule	Belgium	1928	1938	-	Oct	Sun>=2	 2:00s	0	-
Rule	Belgium	1929	only	-	Apr	21	 2:00s	1:00	S
Rule	Belgium	1930	only	-	Apr	13	 2:00s	1:00	S
Rule	Belgium	1931	only	-	Apr	19	 2:00s	1:00	S
Rule	Belgium	1932	only	-	Apr	 3	 2:00s	1:00	S
Rule	Belgium	1933	only	-	Mar	26	 2:00s	1:00	S
Rule	Belgium	1934	only	-	Apr	 8	 2:00s	1:00	S
Rule	Belgium	1935	only	-	Mar	31	 2:00s	1:00	S
Rule	Belgium	1936	only	-	Apr	19	 2:00s	1:00	S
Rule	Belgium	1937	only	-	Apr	 4	 2:00s	1:00	S
Rule	Belgium	1938	only	-	Mar	27	 2:00s	1:00	S
Rule	Belgium	1939	only	-	Apr	16	 2:00s	1:00	S
Rule	Belgium	1939	only	-	Nov	19	 2:00s	0	-
Rule	Belgium	1940	only	-	Feb	25	 2:00s	1:00	S
Rule	Belgium	1944	only	-	Sep	17	 2:00s	0	-
Rule	Belgium	1945	only	-	Apr	 2	 2:00s	1:00	S
Rule	Belgium	1945	only	-	Sep	16	 2:00s	0	-
Rule	Belgium	1946	only	-	May	19	 2:00s	1:00	S
Rule	Belgium	1946	only	-	Oct	 7	 2:00s	0	-
Rule	Bulg	1979	only	-	Mar	31	23:00	1:00	S
Rule	Bulg	1979	only	-	Oct	 1	 1:00	0	-
Rule	Bulg	1980	1982	-	Apr	Sat<=7	23:00	1:00	S
Rule	Bulg	1980	only	-	Sep	29	 1:00	0	-
Rule	Bulg	1981	only	-	Sep	27	 2:00	0	-
Rule	Czech	1945	only	-	Apr	 8	2:00s	1:00	S
Rule	Czech	1945	only	-	Nov	18	2:00s	0	-
Rule	Czech	1946	only	-	May	 6	2:00s	1:00	S
Rule	Czech	1946	1949	-	Oct	Sun>=1	2:00s	0	-
Rule	Czech	1947	only	-	Apr	20	2:00s	1:00	S
Rule	Czech	1948	only	-	Apr	18	2:00s	1:00	S
Rule	Czech	1949	only	-	Apr	 9	2:00s	1:00	S
Rule	Denmark	1916	only	-	May	14	23:00	1:00	S
Rule	Denmark	1916	only	-	Sep	30	23:00	0	-
Rule	Denmark	1940	only	-	May	15	 0:00	1:00	S
Rule	Denmark	1945	only	-	Apr	 2	 2:00s	1:00	S
Rule	Denmark	1945	only	-	Aug	15	 2:00s	0	-
Rule	Denmark	1946	only	-	May	 1	 2:00s	1:00	S
Rule	Denmark	1946	only	-	Sep	 1	 2:00s	0	-
Rule	Denmark	1947	only	-	May	 4	 2:00s	1:00	S
Rule	Denmark	1947	only	-	Aug	10	 2:00s	0	-
Rule	Denmark	1948	only	-	May	 9	 2:00s	1:00	S
Rule	Denmark	1948	only	-	Aug	 8	 2:00s	0	-
Rule	Thule	1993	max	-	Apr	Sun>=1	2:00	1:00	D
Rule	Thule	1993	max	-	Oct	lastSun	2:00	0	S
Rule	Finland	1942	only	-	Apr	3	0:00	1:00	S
Rule	Finland	1942	only	-	Oct	3	0:00	0	-
Rule	France	1916	only	-	Jun	14	23:00s	1:00	S
Rule	France	1916	1919	-	Oct	Sun>=1	23:00s	0	-
Rule	France	1917	only	-	Mar	24	23:00s	1:00	S
Rule	France	1918	only	-	Mar	 9	23:00s	1:00	S
Rule	France	1919	only	-	Mar	 1	23:00s	1:00	S
Rule	France	1920	only	-	Feb	14	23:00s	1:00	S
Rule	France	1920	only	-	Oct	23	23:00s	0	-
Rule	France	1921	only	-	Mar	14	23:00s	1:00	S
Rule	France	1921	only	-	Oct	25	23:00s	0	-
Rule	France	1922	only	-	Mar	25	23:00s	1:00	S
Rule	France	1922	1938	-	Oct	Sat>=1	23:00s	0	-
Rule	France	1923	only	-	May	26	23:00s	1:00	S
Rule	France	1924	only	-	Mar	29	23:00s	1:00	S
Rule	France	1925	only	-	Apr	 4	23:00s	1:00	S
Rule	France	1926	only	-	Apr	17	23:00s	1:00	S
Rule	France	1927	only	-	Apr	 9	23:00s	1:00	S
Rule	France	1928	only	-	Apr	14	23:00s	1:00	S
Rule	France	1929	only	-	Apr	20	23:00s	1:00	S
Rule	France	1930	only	-	Apr	12	23:00s	1:00	S
Rule	France	1931	only	-	Apr	18	23:00s	1:00	S
Rule	France	1932	only	-	Apr	 2	23:00s	1:00	S
Rule	France	1933	only	-	Mar	25	23:00s	1:00	S
Rule	France	1934	only	-	Apr	 7	23:00s	1:00	S
Rule	France	1935	only	-	Mar	30	23:00s	1:00	S
Rule	France	1936	only	-	Apr	18	23:00s	1:00	S
Rule	France	1937	only	-	Apr	 3	23:00s	1:00	S
Rule	France	1938	only	-	Mar	26	23:00s	1:00	S
Rule	France	1939	only	-	Apr	15	23:00s	1:00	S
Rule	France	1939	only	-	Nov	18	23:00s	0	-
Rule	France	1940	only	-	Feb	25	 2:00	1:00	S
Rule	France	1941	only	-	May	 5	 0:00	2:00	M # Midsummer
Rule	France	1941	only	-	Oct	 6	 0:00	1:00	S
Rule	France	1942	only	-	Mar	 9	 0:00	2:00	M
Rule	France	1942	only	-	Nov	 2	 3:00	1:00	S
Rule	France	1943	only	-	Mar	29	 2:00	2:00	M
Rule	France	1943	only	-	Oct	 4	 3:00	1:00	S
Rule	France	1944	only	-	Apr	 3	 2:00	2:00	M
Rule	France	1944	only	-	Oct	 8	 1:00	1:00	S
Rule	France	1945	only	-	Apr	 2	 2:00	2:00	M
Rule	France	1945	only	-	Sep	16	 3:00	0	-
Rule	France	1976	only	-	Mar	28	 1:00	1:00	S
Rule	France	1976	only	-	Sep	26	 1:00	0	-
Rule	Germany	1945	only	-	Apr	 2	2:00s	1:00	S
Rule	Germany	1945	only	-	May	31	3:00	2:00	M # Midsummer
Rule	Germany	1945	only	-	Sep	23	3:00	1:00	S
Rule	Germany	1945	only	-	Nov	18	2:00s	0	-
Rule	Germany	1946	only	-	Apr	14	2:00s	1:00	S
Rule	Germany	1946	only	-	Oct	 7	2:00s	0	-
Rule	Germany	1947	1949	-	Oct	Sun>=1	2:00s	0	-
Rule	Germany	1947	only	-	Apr	 6	2:00s	1:00	S
Rule	Germany	1947	only	-	May	11	2:00s	2:00	M
Rule	Germany	1947	only	-	Jun	29	3:00	1:00	S
Rule	Germany	1948	only	-	Apr	18	2:00s	1:00	S
Rule	Germany	1949	only	-	Apr	10	2:00s	1:00	S
Rule	Greece	1932	only	-	Jul	 7	0:00	1:00	S
Rule	Greece	1932	only	-	Sep	 1	0:00	0	-
Rule	Greece	1941	only	-	Apr	 7	0:00	1:00	S
Rule	Greece	1942	only	-	Nov	 2	3:00	0	-
Rule	Greece	1943	only	-	Mar	30	0:00	1:00	S
Rule	Greece	1943	only	-	Oct	 4	0:00	0	-
Rule	Greece	1952	only	-	Jul	 1	0:00	1:00	S
Rule	Greece	1952	only	-	Nov	 2	0:00	0	-
Rule	Greece	1975	only	-	Apr	12	0:00s	1:00	S
Rule	Greece	1975	only	-	Nov	26	0:00s	0	-
Rule	Greece	1976	only	-	Apr	11	2:00s	1:00	S
Rule	Greece	1976	only	-	Oct	10	2:00s	0	-
Rule	Greece	1977	1978	-	Apr	Sun>=1	2:00s	1:00	S
Rule	Greece	1977	only	-	Sep	26	2:00s	0	-
Rule	Greece	1978	only	-	Sep	24	4:00	0	-
Rule	Greece	1979	only	-	Apr	 1	9:00	1:00	S
Rule	Greece	1979	only	-	Sep	29	2:00	0	-
Rule	Greece	1980	only	-	Apr	 1	0:00	1:00	S
Rule	Greece	1980	only	-	Sep	28	0:00	0	-
Rule	Hungary	1918	only	-	Apr	 1	 3:00	1:00	S
Rule	Hungary	1918	only	-	Sep	29	 3:00	0	-
Rule	Hungary	1919	only	-	Apr	15	 3:00	1:00	S
Rule	Hungary	1919	only	-	Sep	15	 3:00	0	-
Rule	Hungary	1920	only	-	Apr	 5	 3:00	1:00	S
Rule	Hungary	1920	only	-	Sep	30	 3:00	0	-
Rule	Hungary	1945	only	-	May	 1	23:00	1:00	S
Rule	Hungary	1945	only	-	Nov	 3	 0:00	0	-
Rule	Hungary	1946	only	-	Mar	31	 2:00s	1:00	S
Rule	Hungary	1946	1949	-	Oct	Sun>=1	 2:00s	0	-
Rule	Hungary	1947	1949	-	Apr	Sun>=4	 2:00s	1:00	S
Rule	Hungary	1950	only	-	Apr	17	 2:00s	1:00	S
Rule	Hungary	1950	only	-	Oct	23	 2:00s	0	-
Rule	Hungary	1954	1955	-	May	23	 0:00	1:00	S
Rule	Hungary	1954	1955	-	Oct	 3	 0:00	0	-
Rule	Hungary	1956	only	-	Jun	Sun>=1	 0:00	1:00	S
Rule	Hungary	1956	only	-	Sep	lastSun	 0:00	0	-
Rule	Hungary	1957	only	-	Jun	Sun>=1	 1:00	1:00	S
Rule	Hungary	1957	only	-	Sep	lastSun	 3:00	0	-
Rule	Hungary	1980	only	-	Apr	 6	 1:00	1:00	S
Rule	Iceland	1917	1918	-	Feb	19	23:00	1:00	S
Rule	Iceland	1917	only	-	Oct	21	 1:00	0	-
Rule	Iceland	1918	only	-	Nov	16	 1:00	0	-
Rule	Iceland	1939	only	-	Apr	29	23:00	1:00	S
Rule	Iceland	1939	only	-	Nov	29	 2:00	0	-
Rule	Iceland	1940	only	-	Feb	25	 2:00	1:00	S
Rule	Iceland	1940	only	-	Nov	 3	 2:00	0	-
Rule	Iceland	1941	only	-	Mar	 2	 1:00s	1:00	S
Rule	Iceland	1941	only	-	Nov	 2	 1:00s	0	-
Rule	Iceland	1942	only	-	Mar	 8	 1:00s	1:00	S
Rule	Iceland	1942	only	-	Oct	25	 1:00s	0	-
Rule	Iceland	1943	1946	-	Mar	Sun>=1	 1:00s	1:00	S
Rule	Iceland	1943	1948	-	Oct	Sun>=22	 1:00s	0	-
Rule	Iceland	1947	1967	-	Apr	Sun>=1	 1:00s	1:00	S
Rule	Iceland	1949	only	-	Oct	30	 1:00s	0	-
Rule	Iceland	1950	1966	-	Oct	Sun>=22	 1:00s	0	-
Rule	Iceland	1967	only	-	Oct	29	 1:00s	0	-
Rule	Italy	1916	only	-	Jun	 3	0:00s	1:00	S
Rule	Italy	1916	only	-	Oct	 1	0:00s	0	-
Rule	Italy	1917	only	-	Apr	 1	0:00s	1:00	S
Rule	Italy	1917	only	-	Sep	30	0:00s	0	-
Rule	Italy	1918	only	-	Mar	10	0:00s	1:00	S
Rule	Italy	1918	1919	-	Oct	Sun>=1	0:00s	0	-
Rule	Italy	1919	only	-	Mar	 2	0:00s	1:00	S
Rule	Italy	1920	only	-	Mar	21	0:00s	1:00	S
Rule	Italy	1920	only	-	Sep	19	0:00s	0	-
Rule	Italy	1940	only	-	Jun	15	0:00s	1:00	S
Rule	Italy	1944	only	-	Sep	17	0:00s	0	-
Rule	Italy	1945	only	-	Apr	 2	2:00	1:00	S
Rule	Italy	1945	only	-	Sep	15	0:00s	0	-
Rule	Italy	1946	only	-	Mar	17	2:00s	1:00	S
Rule	Italy	1946	only	-	Oct	 6	2:00s	0	-
Rule	Italy	1947	only	-	Mar	16	0:00s	1:00	S
Rule	Italy	1947	only	-	Oct	 5	0:00s	0	-
Rule	Italy	1948	only	-	Feb	29	2:00s	1:00	S
Rule	Italy	1948	only	-	Oct	 3	2:00s	0	-
Rule	Italy	1966	1968	-	May	Sun>=22	0:00	1:00	S
Rule	Italy	1966	1969	-	Sep	Sun>=22	0:00	0	-
Rule	Italy	1969	only	-	Jun	 1	0:00	1:00	S
Rule	Italy	1970	only	-	May	31	0:00	1:00	S
Rule	Italy	1970	only	-	Sep	lastSun	0:00	0	-
Rule	Italy	1971	1972	-	May	Sun>=22	0:00	1:00	S
Rule	Italy	1971	only	-	Sep	lastSun	1:00	0	-
Rule	Italy	1972	only	-	Oct	 1	0:00	0	-
Rule	Italy	1973	only	-	Jun	 3	0:00	1:00	S
Rule	Italy	1973	1974	-	Sep	lastSun	0:00	0	-
Rule	Italy	1974	only	-	May	26	0:00	1:00	S
Rule	Italy	1975	only	-	Jun	 1	0:00s	1:00	S
Rule	Italy	1975	1977	-	Sep	lastSun	0:00s	0	-
Rule	Italy	1976	only	-	May	30	0:00s	1:00	S
Rule	Italy	1977	1979	-	May	Sun>=22	0:00s	1:00	S
Rule	Italy	1978	only	-	Oct	 1	0:00s	0	-
Rule	Italy	1979	only	-	Sep	30	0:00s	0	-
Rule	Latvia	1989	1996	-	Mar	lastSun	 2:00s	1:00	S
Rule	Latvia	1989	1996	-	Sep	lastSun	 2:00s	0	-
Rule	Lux	1916	only	-	May	14	23:00	1:00	S
Rule	Lux	1916	only	-	Oct	 1	 1:00	0	-
Rule	Lux	1917	only	-	Apr	28	23:00	1:00	S
Rule	Lux	1917	only	-	Sep	17	 1:00	0	-
Rule	Lux	1918	only	-	Apr	Mon>=15	 2:00s	1:00	S
Rule	Lux	1918	only	-	Sep	Mon>=15	 2:00s	0	-
Rule	Lux	1919	only	-	Mar	 1	23:00	1:00	S
Rule	Lux	1919	only	-	Oct	 5	 3:00	0	-
Rule	Lux	1920	only	-	Feb	14	23:00	1:00	S
Rule	Lux	1920	only	-	Oct	24	 2:00	0	-
Rule	Lux	1921	only	-	Mar	14	23:00	1:00	S
Rule	Lux	1921	only	-	Oct	26	 2:00	0	-
Rule	Lux	1922	only	-	Mar	25	23:00	1:00	S
Rule	Lux	1922	only	-	Oct	Sun>=2	 1:00	0	-
Rule	Lux	1923	only	-	Apr	21	23:00	1:00	S
Rule	Lux	1923	only	-	Oct	Sun>=2	 2:00	0	-
Rule	Lux	1924	only	-	Mar	29	23:00	1:00	S
Rule	Lux	1924	1928	-	Oct	Sun>=2	 1:00	0	-
Rule	Lux	1925	only	-	Apr	 5	23:00	1:00	S
Rule	Lux	1926	only	-	Apr	17	23:00	1:00	S
Rule	Lux	1927	only	-	Apr	 9	23:00	1:00	S
Rule	Lux	1928	only	-	Apr	14	23:00	1:00	S
Rule	Lux	1929	only	-	Apr	20	23:00	1:00	S
Rule	Malta	1973	only	-	Mar	31	0:00s	1:00	S
Rule	Malta	1973	only	-	Sep	29	0:00s	0	-
Rule	Malta	1974	only	-	Apr	21	0:00s	1:00	S
Rule	Malta	1974	only	-	Sep	16	0:00s	0	-
Rule	Malta	1975	1979	-	Apr	Sun>=15	2:00	1:00	S
Rule	Malta	1975	1980	-	Sep	Sun>=15	2:00	0	-
Rule	Malta	1980	only	-	Mar	31	2:00	1:00	S
Rule	Neth	1916	only	-	May	 1	2:00s	1:00	NST	# Netherlands Summer Time
Rule	Neth	1916	only	-	Oct	 2	2:00s	0	AMT	# Amsterdam Mean Time
Rule	Neth	1917	only	-	Apr	16	2:00s	1:00	NST
Rule	Neth	1917	only	-	Sep	17	2:00s	0	AMT
Rule	Neth	1918	1921	-	Apr	Mon>=1	2:00s	1:00	NST
Rule	Neth	1918	1921	-	Sep	Mon>=24	2:00s	0	AMT
Rule	Neth	1922	only	-	Mar	26	2:00s	1:00	NST
Rule	Neth	1922	1936	-	Oct	Sun>=2	2:00s	0	AMT
Rule	Neth	1923	only	-	Jun	 1	2:00s	1:00	NST
Rule	Neth	1924	only	-	Mar	30	2:00s	1:00	NST
Rule	Neth	1925	only	-	Jun	 5	2:00s	1:00	NST
Rule	Neth	1926	1931	-	May	15	2:00s	1:00	NST
Rule	Neth	1932	only	-	May	22	2:00s	1:00	NST
Rule	Neth	1933	1936	-	May	15	2:00s	1:00	NST
Rule	Neth	1937	only	-	May	22	2:00s	1:00	NST
Rule	Neth	1937	only	-	Jul	 1	0:00	1:00	S
Rule	Neth	1937	1939	-	Oct	Sun>=2	2:00s	0	-
Rule	Neth	1938	1939	-	May	15	2:00s	1:00	S
Rule	Neth	1945	only	-	Apr	 2	2:00s	1:00	S
Rule	Neth	1945	only	-	May	20	2:00s	0	-
Rule	Norway	1916	only	-	May	22	1:00	1:00	S
Rule	Norway	1916	only	-	Sep	30	0:00	0	-
Rule	Norway	1945	only	-	Apr	 2	2:00s	1:00	S
Rule	Norway	1945	only	-	Oct	 1	2:00s	0	-
Rule	Norway	1959	1964	-	Mar	Sun>=15	2:00s	1:00	S
Rule	Norway	1959	1965	-	Sep	Sun>=15	2:00s	0	-
Rule	Norway	1965	only	-	Apr	25	2:00s	1:00	S
Rule	Poland	1918	1919	-	Sep	16	2:00s	0	-
Rule	Poland	1919	only	-	Apr	15	2:00s	1:00	S
Rule	Poland	1944	only	-	Oct	 4	2:00	0	-
Rule	Poland	1945	only	-	Apr	29	0:00	1:00	S
Rule	Poland	1945	only	-	Nov	 1	0:00	0	-
Rule	Poland	1946	only	-	Apr	14	0:00	1:00	S
Rule	Poland	1946	only	-	Sep	 7	0:00	0	-
Rule	Poland	1947	only	-	May	 4	0:00	1:00	S
Rule	Poland	1947	1948	-	Oct	Sun>=1	0:00	0	-
Rule	Poland	1948	only	-	Apr	18	0:00	1:00	S
Rule	Poland	1957	only	-	Jun	 2	1:00s	1:00	S
Rule	Poland	1957	1958	-	Sep	lastSun	1:00s	0	-
Rule	Poland	1958	only	-	Mar	30	1:00s	1:00	S
Rule	Poland	1959	only	-	May	31	1:00s	1:00	S
Rule	Poland	1959	1961	-	Oct	Sun>=1	1:00s	0	-
Rule	Poland	1960	only	-	Apr	 3	1:00s	1:00	S
Rule	Poland	1961	1964	-	May	Sun>=25	1:00s	1:00	S
Rule	Poland	1962	1964	-	Sep	lastSun	1:00s	0	-
Rule	Port	1916	only	-	Jun	17	23:00	1:00	S
Rule	Port	1916	only	-	Nov	 1	 1:00	0	-
Rule	Port	1917	only	-	Feb	28	23:00s	1:00	S
Rule	Port	1917	1921	-	Oct	14	23:00s	0	-
Rule	Port	1918	only	-	Mar	 1	23:00s	1:00	S
Rule	Port	1919	only	-	Feb	28	23:00s	1:00	S
Rule	Port	1920	only	-	Feb	29	23:00s	1:00	S
Rule	Port	1921	only	-	Feb	28	23:00s	1:00	S
Rule	Port	1924	only	-	Apr	16	23:00s	1:00	S
Rule	Port	1924	only	-	Oct	14	23:00s	0	-
Rule	Port	1926	only	-	Apr	17	23:00s	1:00	S
Rule	Port	1926	1929	-	Oct	Sat>=1	23:00s	0	-
Rule	Port	1927	only	-	Apr	 9	23:00s	1:00	S
Rule	Port	1928	only	-	Apr	14	23:00s	1:00	S
Rule	Port	1929	only	-	Apr	20	23:00s	1:00	S
Rule	Port	1931	only	-	Apr	18	23:00s	1:00	S
Rule	Port	1931	1932	-	Oct	Sat>=1	23:00s	0	-
Rule	Port	1932	only	-	Apr	 2	23:00s	1:00	S
Rule	Port	1934	only	-	Apr	 7	23:00s	1:00	S
Rule	Port	1934	1938	-	Oct	Sat>=1	23:00s	0	-
Rule	Port	1935	only	-	Mar	30	23:00s	1:00	S
Rule	Port	1936	only	-	Apr	18	23:00s	1:00	S
Rule	Port	1937	only	-	Apr	 3	23:00s	1:00	S
Rule	Port	1938	only	-	Mar	26	23:00s	1:00	S
Rule	Port	1939	only	-	Apr	15	23:00s	1:00	S
Rule	Port	1939	only	-	Nov	18	23:00s	0	-
Rule	Port	1940	only	-	Feb	24	23:00s	1:00	S
Rule	Port	1940	1941	-	Oct	 5	23:00s	0	-
Rule	Port	1941	only	-	Apr	 5	23:00s	1:00	S
Rule	Port	1942	1945	-	Mar	Sat>=8	23:00s	1:00	S
Rule	Port	1942	only	-	Apr	25	22:00s	2:00	M # Midsummer
Rule	Port	1942	only	-	Aug	15	22:00s	1:00	S
Rule	Port	1942	1945	-	Oct	Sat>=24	23:00s	0	-
Rule	Port	1943	only	-	Apr	17	22:00s	2:00	M
Rule	Port	1943	1945	-	Aug	Sat>=25	22:00s	1:00	S
Rule	Port	1944	1945	-	Apr	Sat>=21	22:00s	2:00	M
Rule	Port	1946	only	-	Apr	Sat>=1	23:00s	1:00	S
Rule	Port	1946	only	-	Oct	Sat>=1	23:00s	0	-
Rule	Port	1947	1949	-	Apr	Sun>=1	 2:00s	1:00	S
Rule	Port	1947	1949	-	Oct	Sun>=1	 2:00s	0	-
Rule	Port	1951	1965	-	Apr	Sun>=1	 2:00s	1:00	S
Rule	Port	1951	1965	-	Oct	Sun>=1	 2:00s	0	-
Rule	Port	1977	only	-	Mar	27	 0:00s	1:00	S
Rule	Port	1977	only	-	Sep	25	 0:00s	0	-
Rule	Port	1978	1979	-	Apr	Sun>=1	 0:00s	1:00	S
Rule	Port	1978	only	-	Oct	 1	 0:00s	0	-
Rule	Port	1979	1982	-	Sep	lastSun	 1:00s	0	-
Rule	Port	1980	only	-	Mar	lastSun	 0:00s	1:00	S
Rule	Port	1981	1982	-	Mar	lastSun	 1:00s	1:00	S
Rule	Port	1983	only	-	Mar	lastSun	 2:00s	1:00	S
Rule	Romania	1932	only	-	May	21	 0:00s	1:00	S
Rule	Romania	1932	1939	-	Oct	Sun>=1	 0:00s	0	-
Rule	Romania	1933	1939	-	Apr	Sun>=2	 0:00s	1:00	S
Rule	Romania	1979	only	-	May	27	 0:00	1:00	S
Rule	Romania	1979	only	-	Sep	lastSun	 0:00	0	-
Rule	Romania	1980	only	-	Apr	 5	23:00	1:00	S
Rule	Romania	1980	only	-	Sep	lastSun	 1:00	0	-
Rule	Romania	1991	1993	-	Mar	lastSun	 0:00s	1:00	S
Rule	Romania	1991	1993	-	Sep	lastSun	 0:00s	0	-
Rule	Spain	1917	only	-	May	 5	23:00s	1:00	S
Rule	Spain	1917	1919	-	Oct	 6	23:00s	0	-
Rule	Spain	1918	only	-	Apr	15	23:00s	1:00	S
Rule	Spain	1919	only	-	Apr	 5	23:00s	1:00	S
Rule	Spain	1924	only	-	Apr	16	23:00s	1:00	S
Rule	Spain	1924	only	-	Oct	 4	23:00s	0	-
Rule	Spain	1926	only	-	Apr	17	23:00s	1:00	S
Rule	Spain	1926	1929	-	Oct	Sat>=1	23:00s	0	-
Rule	Spain	1927	only	-	Apr	 9	23:00s	1:00	S
Rule	Spain	1928	only	-	Apr	14	23:00s	1:00	S
Rule	Spain	1929	only	-	Apr	20	23:00s	1:00	S
Rule	Spain	1937	only	-	May	22	23:00s	1:00	S
Rule	Spain	1937	1939	-	Oct	Sat>=1	23:00s	0	-
Rule	Spain	1938	only	-	Mar	22	23:00s	1:00	S
Rule	Spain	1939	only	-	Apr	15	23:00s	1:00	S
Rule	Spain	1940	only	-	Mar	16	23:00s	1:00	S
Rule	Spain	1942	only	-	May	 2	22:00s	2:00	M # Midsummer
Rule	Spain	1942	only	-	Sep	 1	22:00s	1:00	S
Rule	Spain	1943	1946	-	Apr	Sat>=13	22:00s	2:00	M
Rule	Spain	1943	only	-	Oct	 3	22:00s	1:00	S
Rule	Spain	1944	only	-	Oct	10	22:00s	1:00	S
Rule	Spain	1945	only	-	Sep	30	 1:00	1:00	S
Rule	Spain	1946	only	-	Sep	30	 0:00	0	-
Rule	Spain	1949	only	-	Apr	30	23:00	1:00	S
Rule	Spain	1949	only	-	Sep	30	 1:00	0	-
Rule	Spain	1974	1975	-	Apr	Sat>=13	23:00	1:00	S
Rule	Spain	1974	1975	-	Oct	Sun>=1	 1:00	0	-
Rule	Spain	1976	only	-	Mar	27	23:00	1:00	S
Rule	Spain	1976	1977	-	Sep	lastSun	 1:00	0	-
Rule	Spain	1977	1978	-	Apr	 2	23:00	1:00	S
Rule	Spain	1978	only	-	Oct	 1	 1:00	0	-
Rule SpainAfrica 1967	only	-	Jun	 3	12:00	1:00	S
Rule SpainAfrica 1967	only	-	Oct	 1	 0:00	0	-
Rule SpainAfrica 1974	only	-	Jun	24	 0:00	1:00	S
Rule SpainAfrica 1974	only	-	Sep	 1	 0:00	0	-
Rule SpainAfrica 1976	1977	-	May	 1	 0:00	1:00	S
Rule SpainAfrica 1976	only	-	Aug	 1	 0:00	0	-
Rule SpainAfrica 1977	only	-	Sep	28	 0:00	0	-
Rule SpainAfrica 1978	only	-	Jun	 1	 0:00	1:00	S
Rule SpainAfrica 1978	only	-	Aug	 4	 0:00	0	-
Rule	Swiss	1940	only	-	Nov	 2	0:00	1:00	S
Rule	Swiss	1940	only	-	Dec	31	0:00	0	-
Rule	Swiss	1941	1942	-	May	Sun>=1	2:00	1:00	S
Rule	Swiss	1941	1942	-	Oct	Sun>=1	0:00	0	-
Rule	Turkey	1916	only	-	May	 1	0:00	1:00	S
Rule	Turkey	1916	only	-	Oct	 1	0:00	0	-
Rule	Turkey	1920	only	-	Mar	28	0:00	1:00	S
Rule	Turkey	1920	only	-	Oct	25	0:00	0	-
Rule	Turkey	1921	only	-	Apr	 3	0:00	1:00	S
Rule	Turkey	1921	only	-	Oct	 3	0:00	0	-
Rule	Turkey	1922	only	-	Mar	26	0:00	1:00	S
Rule	Turkey	1922	only	-	Oct	 8	0:00	0	-
Rule	Turkey	1924	only	-	May	13	0:00	1:00	S
Rule	Turkey	1924	1925	-	Oct	 1	0:00	0	-
Rule	Turkey	1925	only	-	May	 1	0:00	1:00	S
Rule	Turkey	1940	only	-	Jun	30	0:00	1:00	S
Rule	Turkey	1940	only	-	Oct	 5	0:00	0	-
Rule	Turkey	1940	only	-	Dec	 1	0:00	1:00	S
Rule	Turkey	1941	only	-	Sep	21	0:00	0	-
Rule	Turkey	1942	only	-	Apr	 1	0:00	1:00	S
Rule	Turkey	1942	only	-	Nov	 1	0:00	0	-
Rule	Turkey	1945	only	-	Apr	 2	0:00	1:00	S
Rule	Turkey	1945	only	-	Oct	 8	0:00	0	-
Rule	Turkey	1946	only	-	Jun	 1	0:00	1:00	S
Rule	Turkey	1946	only	-	Oct	 1	0:00	0	-
Rule	Turkey	1947	1948	-	Apr	Sun>=16	0:00	1:00	S
Rule	Turkey	1947	1950	-	Oct	Sun>=2	0:00	0	-
Rule	Turkey	1949	only	-	Apr	10	0:00	1:00	S
Rule	Turkey	1950	only	-	Apr	19	0:00	1:00	S
Rule	Turkey	1951	only	-	Apr	22	0:00	1:00	S
Rule	Turkey	1951	only	-	Oct	 8	0:00	0	-
Rule	Turkey	1962	only	-	Jul	15	0:00	1:00	S
Rule	Turkey	1962	only	-	Oct	 8	0:00	0	-
Rule	Turkey	1964	only	-	May	15	0:00	1:00	S
Rule	Turkey	1964	only	-	Oct	 1	0:00	0	-
Rule	Turkey	1970	1972	-	May	Sun>=2	0:00	1:00	S
Rule	Turkey	1970	1972	-	Oct	Sun>=2	0:00	0	-
Rule	Turkey	1973	only	-	Jun	 3	1:00	1:00	S
Rule	Turkey	1973	only	-	Nov	 4	3:00	0	-
Rule	Turkey	1974	only	-	Mar	31	2:00	1:00	S
Rule	Turkey	1974	only	-	Nov	 3	5:00	0	-
Rule	Turkey	1975	only	-	Mar	30	0:00	1:00	S
Rule	Turkey	1975	1976	-	Oct	lastSun	0:00	0	-
Rule	Turkey	1976	only	-	Jun	 1	0:00	1:00	S
Rule	Turkey	1977	1978	-	Apr	Sun>=1	0:00	1:00	S
Rule	Turkey	1977	only	-	Oct	16	0:00	0	-
Rule	Turkey	1979	1980	-	Apr	Sun>=1	3:00	1:00	S
Rule	Turkey	1979	1982	-	Oct	Mon>=11	0:00	0	-
Rule	Turkey	1981	1982	-	Mar	lastSun	3:00	1:00	S
Rule	Turkey	1983	only	-	Jul	31	0:00	1:00	S
Rule	Turkey	1983	only	-	Oct	 2	0:00	0	-
Rule	Turkey	1985	only	-	Apr	20	0:00	1:00	S
Rule	Turkey	1985	only	-	Sep	28	0:00	0	-
Rule	US	1918	1919	-	Mar	lastSun	2:00	1:00	W # War
Rule	US	1918	1919	-	Oct	lastSun	2:00	0	S
Rule	US	1942	only	-	Feb	9	2:00	1:00	W # War
Rule	US	1945	only	-	Aug	14	23:00u	1:00	P # Peace
Rule	US	1945	only	-	Sep	30	2:00	0	S
Rule	US	1967	max	-	Oct	lastSun	2:00	0	S
Rule	US	1967	1973	-	Apr	lastSun	2:00	1:00	D
Rule	US	1974	only	-	Jan	6	2:00	1:00	D
Rule	US	1975	only	-	Feb	23	2:00	1:00	D
Rule	US	1976	1986	-	Apr	lastSun	2:00	1:00	D
Rule	US	1987	max	-	Apr	Sun>=1	2:00	1:00	D
Rule	NYC	1920	only	-	Mar	lastSun	2:00	1:00	D
Rule	NYC	1920	only	-	Oct	lastSun	2:00	0	S
Rule	NYC	1921	1966	-	Apr	lastSun	2:00	1:00	D
Rule	NYC	1921	1954	-	Sep	lastSun	2:00	0	S
Rule	NYC	1955	1966	-	Oct	lastSun	2:00	0	S
Rule	Chicago	1920	only	-	Jun	13	2:00	1:00	D
Rule	Chicago	1920	1921	-	Oct	lastSun	2:00	0	S
Rule	Chicago	1921	only	-	Mar	lastSun	2:00	1:00	D
Rule	Chicago	1922	1966	-	Apr	lastSun	2:00	1:00	D
Rule	Chicago	1922	1954	-	Sep	lastSun	2:00	0	S
Rule	Chicago	1955	1966	-	Oct	lastSun	2:00	0	S
Rule	Denver	1920	1921	-	Mar	lastSun	2:00	1:00	D
Rule	Denver	1920	only	-	Oct	lastSun	2:00	0	S
Rule	Denver	1921	only	-	May	22	2:00	0	S
Rule	Denver	1965	1966	-	Apr	lastSun	2:00	1:00	D
Rule	Denver	1965	1966	-	Oct	lastSun	2:00	0	S
Rule	CA	1948	only	-	Mar	14	2:00	1:00	D
Rule	CA	1949	only	-	Jan	 1	2:00	0	S
Rule	CA	1950	1966	-	Apr	lastSun	2:00	1:00	D
Rule	CA	1950	1961	-	Sep	lastSun	2:00	0	S
Rule	CA	1962	1966	-	Oct	lastSun	2:00	0	S
Rule Indianapolis 1941	only	-	Jun	22	2:00	1:00	D
Rule Indianapolis 1941	1954	-	Sep	lastSun	2:00	0	S
Rule Indianapolis 1946	1954	-	Apr	lastSun	2:00	1:00	D
Rule	Marengo	1951	only	-	Apr	lastSun	2:00	1:00	D
Rule	Marengo	1951	only	-	Sep	lastSun	2:00	0	S
Rule	Marengo	1954	1960	-	Apr	lastSun	2:00	1:00	D
Rule	Marengo	1954	1960	-	Sep	lastSun	2:00	0	S
Rule	Starke	1947	1961	-	Apr	lastSun	2:00	1:00	D
Rule	Starke	1947	1954	-	Sep	lastSun	2:00	0	S
Rule	Starke	1955	1956	-	Oct	lastSun	2:00	0	S
Rule	Starke	1957	1958	-	Sep	lastSun	2:00	0	S
Rule	Starke	1959	1961	-	Oct	lastSun	2:00	0	S
Rule Louisville	1921	only	-	May	1	2:00	1:00	D
Rule Louisville	1921	only	-	Sep	1	2:00	0	S
Rule Louisville	1941	1961	-	Apr	lastSun	2:00	1:00	D
Rule Louisville	1941	only	-	Sep	lastSun	2:00	0	S
Rule Louisville	1946	only	-	Jun	2	2:00	0	S
Rule Louisville	1950	1955	-	Sep	lastSun	2:00	0	S
Rule Louisville	1956	1960	-	Oct	lastSun	2:00	0	S
Rule	Detroit	1948	only	-	Apr	lastSun	2:00	1:00	D
Rule	Detroit	1948	only	-	Sep	lastSun	2:00	0	S
Rule	Detroit	1967	only	-	Jun	14	2:00	1:00	D
Rule	Detroit	1967	only	-	Oct	lastSun	2:00	0	S
Rule Menominee	1946	only	-	Apr	lastSun	2:00	1:00	D
Rule Menominee	1946	only	-	Sep	lastSun	2:00	0	S
Rule Menominee	1966	only	-	Apr	lastSun	2:00	1:00	D
Rule Menominee	1966	only	-	Oct	lastSun	2:00	0	S
Rule	Canada	1918	only	-	Apr	14	2:00	1:00	D
Rule	Canada	1918	only	-	Oct	31	2:00	0	S
Rule	Canada	1942	only	-	Feb	 9	2:00	1:00	D
Rule	Canada	1945	only	-	Sep	30	2:00	0	S
Rule	Canada	1974	1986	-	Apr	lastSun	2:00	1:00	D
Rule	Canada	1974	max	-	Oct	lastSun	2:00	0	S
Rule	Canada	1987	max	-	Apr	Sun>=1	2:00	1:00	D
Rule	StJohns	1917	1918	-	Apr	Sun>=8	2:00	1:00	D
Rule	StJohns	1917	only	-	Sep	17	2:00	0	S
Rule	StJohns	1918	only	-	Oct	31	2:00	0	S
Rule	StJohns	1919	only	-	May	 5	23:00	1:00	D
Rule	StJohns	1919	only	-	Aug	12	23:00	0	S
Rule	StJohns	1920	1935	-	May	Sun>=1	23:00	1:00	D
Rule	StJohns	1920	1935	-	Oct	lastSun	23:00	0	S
Rule	StJohns	1936	1941	-	May	Sun>=8	0:00	1:00	D
Rule	StJohns	1936	1941	-	Oct	Sun>=1	0:00	0	S
Rule	StJohns	1942	only	-	Mar	 1	0:00	1:00	D
Rule	StJohns	1942	only	-	Dec	31	0:00	0	S
Rule	StJohns	1943	only	-	May	30	0:00	1:00	D
Rule	StJohns	1943	only	-	Sep	 5	0:00	0	S
Rule	StJohns	1944	only	-	Jul	10	0:00	1:00	D
Rule	StJohns	1944	only	-	Sep	 2	0:00	0	S
Rule	StJohns	1945	only	-	Jan	 1	0:00	1:00	D
Rule	StJohns	1945	only	-	Oct	 7	2:00	0	S
Rule	StJohns	1946	1950	-	May	Sun>=8	2:00	1:00	D
Rule	StJohns	1946	1950	-	Oct	Sun>=2	2:00	0	S
Rule	StJohns	1951	1986	-	Apr	lastSun	2:00	1:00	D
Rule	StJohns	1951	1959	-	Sep	lastSun	2:00	0	S
Rule	StJohns	1960	1986	-	Oct	lastSun	2:00	0	S
Rule	StJohns	1987	only	-	Apr	Sun>=1	0:01	1:00	D
Rule	StJohns	1987	max	-	Oct	lastSun	0:01	0	S
Rule	StJohns	1988	only	-	Apr	Sun>=1	0:01	2:00	DD
Rule	StJohns	1989	max	-	Apr	Sun>=1	0:01	1:00	D
Rule Halifax	1916	only	-	Apr	 1	0:00	1:00	D
Rule Halifax	1916	only	-	Oct	 1	0:00	0	S
Rule Halifax	1918	only	-	Apr	14	2:00	1:00	D
Rule Halifax	1918	only	-	Oct	31	2:00	0	S
Rule Halifax	1920	only	-	May	 9	0:00	1:00	D
Rule Halifax	1920	only	-	Aug	29	0:00	0	S
Rule Halifax	1921	only	-	May	 6	0:00	1:00	D
Rule Halifax	1921	1922	-	Sep	 5	0:00	0	S
Rule Halifax	1922	only	-	Apr	30	0:00	1:00	D
Rule Halifax	1923	1925	-	May	Sun>=1	0:00	1:00	D
Rule Halifax	1923	only	-	Sep	 4	0:00	0	S
Rule Halifax	1924	only	-	Sep	15	0:00	0	S
Rule Halifax	1925	only	-	Sep	28	0:00	0	S
Rule Halifax	1926	only	-	May	16	0:00	1:00	D
Rule Halifax	1926	only	-	Sep	13	0:00	0	S
Rule Halifax	1927	only	-	May	 1	0:00	1:00	D
Rule Halifax	1927	only	-	Sep	26	0:00	0	S
Rule Halifax	1928	1931	-	May	Sun>=8	0:00	1:00	D
Rule Halifax	1928	only	-	Sep	 9	0:00	0	S
Rule Halifax	1929	only	-	Sep	 3	0:00	0	S
Rule Halifax	1930	only	-	Sep	15	0:00	0	S
Rule Halifax	1931	1932	-	Sep	Mon>=24	0:00	0	S
Rule Halifax	1933	only	-	Apr	30	0:00	1:00	D
Rule Halifax	1933	only	-	Oct	 2	0:00	0	S
Rule Halifax	1934	only	-	May	20	0:00	1:00	D
Rule Halifax	1934	only	-	Sep	16	0:00	0	S
Rule Halifax	1935	only	-	Jun	 2	0:00	1:00	D
Rule Halifax	1935	only	-	Sep	30	0:00	0	S
Rule Halifax	1936	only	-	Jun	 1	0:00	1:00	D
Rule Halifax	1936	only	-	Sep	14	0:00	0	S
Rule Halifax	1937	1938	-	May	Sun>=1	0:00	1:00	D
Rule Halifax	1937	1941	-	Sep	Mon>=24	0:00	0	S
Rule Halifax	1939	only	-	May	28	0:00	1:00	D
Rule Halifax	1940	1941	-	May	Sun>=1	0:00	1:00	D
Rule Halifax	1942	only	-	Feb	9	2:00	1:00	D
Rule Halifax	1945	1959	-	Sep	lastSun	2:00	0	S
Rule Halifax	1946	1959	-	Apr	lastSun	2:00	1:00	D
Rule Halifax	1962	1986	-	Apr	lastSun	2:00	1:00	D
Rule Halifax	1962	max	-	Oct	lastSun	2:00	0	S
Rule Halifax	1987	max	-	Apr	Sun>=1	2:00	1:00	D
Rule	Mont	1917	only	-	Mar	25	2:00	1:00	D
Rule	Mont	1917	only	-	Apr	24	0:00	0	S
Rule	Mont	1918	only	-	Apr	14	2:00	1:00	D
Rule	Mont	1918	only	-	Oct	31	2:00	0	S
Rule	Mont	1919	only	-	Mar	31	2:30	1:00	D
Rule	Mont	1919	only	-	Oct	25	2:30	0	S
Rule	Mont	1920	only	-	May	 2	2:30	1:00	D
Rule	Mont	1920	only	-	Oct	 3	2:30	0	S
Rule	Mont	1921	only	-	May	 1	2:00	1:00	D
Rule	Mont	1921	only	-	Oct	 2	2:30	0	S
Rule	Mont	1922	only	-	Apr	30	2:00	1:00	D
Rule	Mont	1922	only	-	Oct	 1	2:30	0	S
Rule	Mont	1924	only	-	May	17	2:00	1:00	D
Rule	Mont	1924	1926	-	Sep	lastSun	2:30	0	S
Rule	Mont	1925	1926	-	May	Sun>=1	2:00	1:00	D
Rule	Mont	1927	only	-	May	 1	0:00	1:00	D
Rule	Mont	1927	1932	-	Sep	Sun>=25	0:00	0	S
Rule	Mont	1928	1931	-	Apr	Sun>=25	0:00	1:00	D
Rule	Mont	1932	only	-	May	 1	0:00	1:00	D
Rule	Mont	1933	1940	-	Apr	Sun>=24	0:00	1:00	D
Rule	Mont	1933	only	-	Oct	 1	0:00	0	S
Rule	Mont	1934	1939	-	Sep	Sun>=24	0:00	0	S
Rule	Mont	1945	1948	-	Sep	lastSun	2:00	0	S
Rule	Mont	1946	1986	-	Apr	lastSun	2:00	1:00	D
Rule	Mont	1949	1950	-	Oct	lastSun	2:00	0	S
Rule	Mont	1951	1956	-	Sep	lastSun	2:00	0	S
Rule	Mont	1957	max	-	Oct	lastSun	2:00	0	S
Rule	Mont	1987	max	-	Apr	Sun>=1	2:00	1:00	D
Rule	Winn	1916	only	-	Apr	23	0:00	1:00	D
Rule	Winn	1916	only	-	Sep	17	0:00	0	S
Rule	Winn	1918	only	-	Apr	14	2:00	1:00	D
Rule	Winn	1918	only	-	Oct	31	2:00	0	S
Rule	Winn	1937	only	-	May	16	2:00	1:00	D
Rule	Winn	1937	only	-	Sep	26	2:00	0	S
Rule	Winn	1942	only	-	Feb	 9	2:00	1:00	D
Rule	Winn	1945	only	-	Sep	lastSun	2:00	0	S
Rule	Winn	1946	only	-	May	12	2:00	1:00	D
Rule	Winn	1946	only	-	Oct	13	2:00	0	S
Rule	Winn	1947	1949	-	Apr	lastSun	2:00	1:00	D
Rule	Winn	1947	1949	-	Sep	lastSun	2:00	0	S
Rule	Winn	1950	only	-	May	 1	2:00	1:00	D
Rule	Winn	1950	only	-	Sep	30	2:00	0	S
Rule	Winn	1951	1960	-	Apr	lastSun	2:00	1:00	D
Rule	Winn	1951	1958	-	Sep	lastSun	2:00	0	S
Rule	Winn	1959	only	-	Oct	lastSun	2:00	0	S
Rule	Winn	1960	only	-	Sep	lastSun	2:00	0	S
Rule	Winn	1963	only	-	Apr	lastSun	2:00	1:00	D
Rule	Winn	1963	only	-	Sep	22	2:00	0	S
Rule	Winn	1966	1986	-	Apr	lastSun	2:00	1:00	D
Rule	Winn	1966	1986	-	Oct	lastSun	2:00	0	S
Rule	Winn	1987	max	-	Apr	Sun>=1	2:00	1:00	D
Rule	Winn	1987	max	-	Oct	lastSun	2:00s	0	S
Rule	Regina	1918	only	-	Apr	14	2:00	1:00	D
Rule	Regina	1918	only	-	Oct	31	2:00	0	S
Rule	Regina	1930	1934	-	May	Sun>=1	0:00	1:00	D
Rule	Regina	1930	1934	-	Oct	Sun>=1	0:00	0	S
Rule	Regina	1937	1941	-	Apr	Sun>=8	0:00	1:00	D
Rule	Regina	1937	only	-	Oct	Sun>=8	0:00	0	S
Rule	Regina	1938	only	-	Oct	Sun>=1	0:00	0	S
Rule	Regina	1939	1941	-	Oct	Sun>=8	0:00	0	S
Rule	Regina	1942	only	-	Feb	 9	2:00	1:00	D
Rule	Regina	1945	only	-	Sep	lastSun	2:00	0	S
Rule	Regina	1946	only	-	Apr	Sun>=8	2:00	1:00	D
Rule	Regina	1946	only	-	Oct	Sun>=8	2:00	0	S
Rule	Regina	1947	1959	-	Apr	lastSun	2:00	1:00	D
Rule	Regina	1947	1958	-	Sep	lastSun	2:00	0	S
Rule	Regina	1959	only	-	Oct	lastSun	2:00	0	S
Rule	Swift	1957	only	-	Apr	lastSun	2:00	1:00	D
Rule	Swift	1957	only	-	Oct	lastSun	2:00	0	S
Rule	Swift	1959	1961	-	Apr	lastSun	2:00	1:00	D
Rule	Swift	1959	only	-	Oct	lastSun	2:00	0	S
Rule	Swift	1960	1961	-	Sep	lastSun	2:00	0	S
Rule	Edm	1918	1919	-	Apr	Sun>=8	2:00	1:00	D
Rule	Edm	1918	only	-	Oct	31	2:00	0	S
Rule	Edm	1919	only	-	May	27	2:00	0	S
Rule	Edm	1920	1923	-	Apr	lastSun	2:00	1:00	D
Rule	Edm	1920	only	-	Oct	lastSun	2:00	0	S
Rule	Edm	1921	1923	-	Sep	lastSun	2:00	0	S
Rule	Edm	1942	only	-	Feb	 9	2:00	1:00	D
Rule	Edm	1945	only	-	Sep	lastSun	2:00	0	S
Rule	Edm	1947	only	-	Apr	lastSun	2:00	1:00	D
Rule	Edm	1947	only	-	Sep	lastSun	2:00	0	S
Rule	Edm	1967	only	-	Apr	lastSun	2:00	1:00	D
Rule	Edm	1967	only	-	Oct	lastSun	2:00	0	S
Rule	Edm	1969	only	-	Apr	lastSun	2:00	1:00	D
Rule	Edm	1969	only	-	Oct	lastSun	2:00	0	S
Rule	Edm	1972	1986	-	Apr	lastSun	2:00	1:00	D
Rule	Edm	1972	max	-	Oct	lastSun	2:00	0	S
Rule	Edm	1987	max	-	Apr	Sun>=1	2:00	1:00	D
Rule	Vanc	1918	only	-	Apr	14	2:00	1:00	D
Rule	Vanc	1918	only	-	Oct	31	2:00	0	S
Rule	Vanc	1942	only	-	Feb	 9	2:00	1:00	D
Rule	Vanc	1945	only	-	Sep	30	2:00	0	S
Rule	Vanc	1946	1986	-	Apr	lastSun	2:00	1:00	D
Rule	Vanc	1946	only	-	Oct	13	2:00	0	S
Rule	Vanc	1947	1961	-	Sep	lastSun	2:00	0	S
Rule	Vanc	1962	max	-	Oct	lastSun	2:00	0	S
Rule	Vanc	1987	max	-	Apr	Sun>=1	2:00	1:00	D
Rule	NT_YK	1918	only	-	Apr	14	2:00	1:00	D
Rule	NT_YK	1918	only	-	Oct	27	2:00	0	S
Rule	NT_YK	1919	only	-	May	25	2:00	1:00	D
Rule	NT_YK	1919	only	-	Nov	 1	0:00	0	S
Rule	NT_YK	1942	only	-	Feb	 9	2:00	1:00	D
Rule	NT_YK	1945	only	-	Sep	30	2:00	0	S
Rule	NT_YK	1965	only	-	Apr	lastSun	0:00	2:00	DD
Rule	NT_YK	1965	only	-	Oct	lastSun	2:00	0	S
Rule	NT_YK	1980	1986	-	Apr	lastSun	2:00	1:00	D
Rule	NT_YK	1980	max	-	Oct	lastSun	2:00	0	S
Rule	NT_YK	1987	max	-	Apr	Sun>=1	2:00	1:00	D
Rule	Mexico	1939	only	-	Feb	5	0:00	1:00	D
Rule	Mexico	1939	only	-	Jun	25	0:00	0	S
Rule	Mexico	1940	only	-	Dec	9	0:00	1:00	D
Rule	Mexico	1941	only	-	Apr	1	0:00	0	S
Rule	Mexico	1943	only	-	Dec	16	0:00	1:00	D
Rule	Mexico	1944	only	-	May	1	0:00	0	S
Rule	Mexico	1950	only	-	Feb	12	0:00	1:00	D
Rule	Mexico	1950	only	-	Jul	30	0:00	0	S
Rule	Mexico	1996	max	-	Apr	Sun>=1	2:00	1:00	D
Rule	Mexico	1996	max	-	Oct	lastSun	2:00	0	S
Rule	BajaN	1954	1961	-	Apr	lastSun	2:00	1:00	D
Rule	BajaN	1954	1961	-	Sep	lastSun	2:00	0	S
Rule	Bahamas	1964	max	-	Oct	lastSun	2:00	0	S
Rule	Bahamas	1964	1986	-	Apr	lastSun	2:00	1:00	D
Rule	Bahamas	1987	max	-	Apr	Sun>=1	2:00	1:00	D
Rule	Barb	1977	only	-	Jun	12	2:00	1:00	D
Rule	Barb	1977	1978	-	Oct	Sun>=1	2:00	0	S
Rule	Barb	1978	1980	-	Apr	Sun>=15	2:00	1:00	D
Rule	Barb	1979	only	-	Sep	30	2:00	0	S
Rule	Barb	1980	only	-	Sep	25	2:00	0	S
Rule	Belize	1918	1942	-	Oct	Sun>=2	0:00	0:30	HD
Rule	Belize	1919	1943	-	Feb	Sun>=9	0:00	0	S
Rule	Belize	1973	only	-	Dec	 5	0:00	1:00	D
Rule	Belize	1974	only	-	Feb	 9	0:00	0	S
Rule	Belize	1982	only	-	Dec	18	0:00	1:00	D
Rule	Belize	1983	only	-	Feb	12	0:00	0	S
Rule	CR	1979	1980	-	Feb	lastSun	0:00	1:00	D
Rule	CR	1979	1980	-	Jun	Sun>=1	0:00	0	S
Rule	CR	1991	1992	-	Jan	Sat>=15	0:00	1:00	D
Rule	CR	1991	only	-	Jul	 1	0:00	0	S
Rule	CR	1992	only	-	Mar	15	0:00	0	S
Rule	Cuba	1928	only	-	Jun	10	0:00	1:00	D
Rule	Cuba	1928	only	-	Oct	10	0:00	0	S
Rule	Cuba	1940	1942	-	Jun	Sun>=1	0:00	1:00	D
Rule	Cuba	1940	1942	-	Sep	Sun>=1	0:00	0	S
Rule	Cuba	1945	1946	-	Jun	Sun>=1	0:00	1:00	D
Rule	Cuba	1945	1946	-	Sep	Sun>=1	0:00	0	S
Rule	Cuba	1965	only	-	Jun	1	0:00	1:00	D
Rule	Cuba	1965	only	-	Sep	30	0:00	0	S
Rule	Cuba	1966	only	-	May	29	0:00	1:00	D
Rule	Cuba	1966	only	-	Oct	2	0:00	0	S
Rule	Cuba	1967	only	-	Apr	8	0:00	1:00	D
Rule	Cuba	1967	1968	-	Sep	Sun>=8	0:00	0	S
Rule	Cuba	1968	only	-	Apr	14	0:00	1:00	D
Rule	Cuba	1969	1977	-	Apr	lastSun	0:00	1:00	D
Rule	Cuba	1969	1971	-	Oct	lastSun	0:00	0	S
Rule	Cuba	1972	1974	-	Oct	8	0:00	0	S
Rule	Cuba	1975	1977	-	Oct	lastSun	0:00	0	S
Rule	Cuba	1978	only	-	May	7	0:00	1:00	D
Rule	Cuba	1978	1990	-	Oct	Sun>=8	0:00	0	S
Rule	Cuba	1979	1980	-	Mar	Sun>=15	0:00	1:00	D
Rule	Cuba	1981	1985	-	May	Sun>=5	0:00	1:00	D
Rule	Cuba	1986	1989	-	Mar	Sun>=14	0:00	1:00	D
Rule	Cuba	1990	1997	-	Apr	Sun>=1	0:00	1:00	D
Rule	Cuba	1991	1995	-	Oct	Sun>=8	0:00s	0	S
Rule	Cuba	1996	only	-	Oct	 6	0:00s	0	S
Rule	Cuba	1997	only	-	Oct	12	0:00s	0	S
Rule	Cuba	1998	1999	-	Mar	lastSun	0:00s	1:00	D
Rule	Cuba	1998	max	-	Oct	lastSun	0:00s	0	S
Rule	Cuba	2000	max	-	Apr	Sun>=1	0:00s	1:00	D
Rule	DR	1966	only	-	Oct	30	0:00	1:00	D
Rule	DR	1967	only	-	Feb	28	0:00	0	S
Rule	DR	1969	1973	-	Oct	lastSun	0:00	0:30	HD
Rule	DR	1970	only	-	Feb	21	0:00	0	S
Rule	DR	1971	only	-	Jan	20	0:00	0	S
Rule	DR	1972	1974	-	Jan	21	0:00	0	S
Rule	Salv	1987	1988	-	May	Sun>=1	0:00	1:00	D
Rule	Salv	1987	1988	-	Sep	lastSun	0:00	0	S
Rule	Guat	1973	only	-	Nov	25	0:00	1:00	D
Rule	Guat	1974	only	-	Feb	24	0:00	0	S
Rule	Guat	1983	only	-	May	21	0:00	1:00	D
Rule	Guat	1983	only	-	Sep	22	0:00	0	S
Rule	Guat	1991	only	-	Mar	23	0:00	1:00	D
Rule	Guat	1991	only	-	Sep	 7	0:00	0	S
Rule	Haiti	1983	only	-	May	8	0:00	1:00	D
Rule	Haiti	1984	1987	-	Apr	lastSun	0:00	1:00	D
Rule	Haiti	1983	1987	-	Oct	lastSun	0:00	0	S
Rule	Haiti	1988	1997	-	Apr	Sun>=1	1:00s	1:00	D
Rule	Haiti	1988	1997	-	Oct	lastSun	1:00s	0	S
Rule	Nic	1979	1980	-	Mar	Sun>=16	0:00	1:00	D
Rule	Nic	1979	1980	-	Jun	Mon>=23	0:00	0	S
Rule	Nic	1992	only	-	Jan	1	4:00	1:00	D
Rule	Nic	1992	only	-	Sep	24	0:00	0	S
Rule	TC	1979	1986	-	Apr	lastSun	0:00	1:00	D
Rule	TC	1979	max	-	Oct	lastSun	0:00	0	S
Rule	TC	1987	max	-	Apr	Sun>=1	0:00	1:00	D
Rule	sol87	1987	only	-	Jan	1	12:03:20s -0:03:20 -
Rule	sol87	1987	only	-	Jan	2	12:03:50s -0:03:50 -
Rule	sol87	1987	only	-	Jan	3	12:04:15s -0:04:15 -
Rule	sol87	1987	only	-	Jan	4	12:04:45s -0:04:45 -
Rule	sol87	1987	only	-	Jan	5	12:05:10s -0:05:10 -
Rule	sol87	1987	only	-	Jan	6	12:05:40s -0:05:40 -
Rule	sol87	1987	only	-	Jan	7	12:06:05s -0:06:05 -
Rule	sol87	1987	only	-	Jan	8	12:06:30s -0:06:30 -
Rule	sol87	1987	only	-	Jan	9	12:06:55s -0:06:55 -
Rule	sol87	1987	only	-	Jan	10	12:07:20s -0:07:20 -
Rule	sol87	1987	only	-	Jan	11	12:07:45s -0:07:45 -
Rule	sol87	1987	only	-	Jan	12	12:08:10s -0:08:10 -
Rule	sol87	1987	only	-	Jan	13	12:08:30s -0:08:30 -
Rule	sol87	1987	only	-	Jan	14	12:08:55s -0:08:55 -
Rule	sol87	1987	only	-	Jan	15	12:09:15s -0:09:15 -
Rule	sol87	1987	only	-	Jan	16	12:09:35s -0:09:35 -
Rule	sol87	1987	only	-	Jan	17	12:09:55s -0:09:55 -
Rule	sol87	1987	only	-	Jan	18	12:10:15s -0:10:15 -
Rule	sol87	1987	only	-	Jan	19	12:10:35s -0:10:35 -
Rule	sol87	1987	only	-	Jan	20	12:10:55s -0:10:55 -
Rule	sol87	1987	only	-	Jan	21	12:11:10s -0:11:10 -
Rule	sol87	1987	only	-	Jan	22	12:11:30s -0:11:30 -
Rule	sol87	1987	only	-	Jan	23	12:11:45s -0:11:45 -
Rule	sol87	1987	only	-	Jan	24	12:12:00s -0:12:00 -
Rule	sol87	1987	only	-	Jan	25	12:12:15s -0:12:15 -
Rule	sol87	1987	only	-	Jan	26	12:12:30s -0:12:30 -
Rule	sol87	1987	only	-	Jan	27	12:12:40s -0:12:40 -
Rule	sol87	1987	only	-	Jan	28	12:12:55s -0:12:55 -
Rule	sol87	1987	only	-	Jan	29	12:13:05s -0:13:05 -
Rule	sol87	1987	only	-	Jan	30	12:13:15s -0:13:15 -
Rule	sol87	1987	only	-	Jan	31	12:13:25s -0:13:25 -
Rule	sol87	1987	only	-	Feb	1	12:13:35s -0:13:35 -
Rule	sol87	1987	only	-	Feb	2	12:13:40s -0:13:40 -
Rule	sol87	1987	only	-	Feb	3	12:13:50s -0:13:50 -
Rule	sol87	1987	only	-	Feb	4	12:13:55s -0:13:55 -
Rule	sol87	1987	only	-	Feb	5	12:14:00s -0:14:00 -
Rule	sol87	1987	only	-	Feb	6	12:14:05s -0:14:05 -
Rule	sol87	1987	only	-	Feb	7	12:14:10s -0:14:10 -
Rule	sol87	1987	only	-	Feb	8	12:14:10s -0:14:10 -
Rule	sol87	1987	only	-	Feb	9	12:14:15s -0:14:15 -
Rule	sol87	1987	only	-	Feb	10	12:14:15s -0:14:15 -
Rule	sol87	1987	only	-	Feb	11	12:14:15s -0:14:15 -
Rule	sol87	1987	only	-	Feb	12	12:14:15s -0:14:15 -
Rule	sol87	1987	only	-	Feb	13	12:14:15s -0:14:15 -
Rule	sol87	1987	only	-	Feb	14	12:14:15s -0:14:15 -
Rule	sol87	1987	only	-	Feb	15	12:14:10s -0:14:10 -
Rule	sol87	1987	only	-	Feb	16	12:14:10s -0:14:10 -
Rule	sol87	1987	only	-	Feb	17	12:14:05s -0:14:05 -
Rule	sol87	1987	only	-	Feb	18	12:14:00s -0:14:00 -
Rule	sol87	1987	only	-	Feb	19	12:13:55s -0:13:55 -
Rule	sol87	1987	only	-	Feb	20	12:13:50s -0:13:50 -
Rule	sol87	1987	only	-	Feb	21	12:13:45s -0:13:45 -
Rule	sol87	1987	only	-	Feb	22	12:13:35s -0:13:35 -
Rule	sol87	1987	only	-	Feb	23	12:13:30s -0:13:30 -
Rule	sol87	1987	only	-	Feb	24	12:13:20s -0:13:20 -
Rule	sol87	1987	only	-	Feb	25	12:13:10s -0:13:10 -
Rule	sol87	1987	only	-	Feb	26	12:13:00s -0:13:00 -
Rule	sol87	1987	only	-	Feb	27	12:12:50s -0:12:50 -
Rule	sol87	1987	only	-	Feb	28	12:12:40s -0:12:40 -
Rule	sol87	1987	only	-	Mar	1	12:12:30s -0:12:30 -
Rule	sol87	1987	only	-	Mar	2	12:12:20s -0:12:20 -
Rule	sol87	1987	only	-	Mar	3	12:12:05s -0:12:05 -
Rule	sol87	1987	only	-	Mar	4	12:11:55s -0:11:55 -
Rule	sol87	1987	only	-	Mar	5	12:11:40s -0:11:40 -
Rule	sol87	1987	only	-	Mar	6	12:11:25s -0:11:25 -
Rule	sol87	1987	only	-	Mar	7	12:11:15s -0:11:15 -
Rule	sol87	1987	only	-	Mar	8	12:11:00s -0:11:00 -
Rule	sol87	1987	only	-	Mar	9	12:10:45s -0:10:45 -
Rule	sol87	1987	only	-	Mar	10	12:10:30s -0:10:30 -
Rule	sol87	1987	only	-	Mar	11	12:10:15s -0:10:15 -
Rule	sol87	1987	only	-	Mar	12	12:09:55s -0:09:55 -
Rule	sol87	1987	only	-	Mar	13	12:09:40s -0:09:40 -
Rule	sol87	1987	only	-	Mar	14	12:09:25s -0:09:25 -
Rule	sol87	1987	only	-	Mar	15	12:09:10s -0:09:10 -
Rule	sol87	1987	only	-	Mar	16	12:08:50s -0:08:50 -
Rule	sol87	1987	only	-	Mar	17	12:08:35s -0:08:35 -
Rule	sol87	1987	only	-	Mar	18	12:08:15s -0:08:15 -
Rule	sol87	1987	only	-	Mar	19	12:08:00s -0:08:00 -
Rule	sol87	1987	only	-	Mar	20	12:07:40s -0:07:40 -
Rule	sol87	1987	only	-	Mar	21	12:07:25s -0:07:25 -
Rule	sol87	1987	only	-	Mar	22	12:07:05s -0:07:05 -
Rule	sol87	1987	only	-	Mar	23	12:06:50s -0:06:50 -
Rule	sol87	1987	only	-	Mar	24	12:06:30s -0:06:30 -
Rule	sol87	1987	only	-	Mar	25	12:06:10s -0:06:10 -
Rule	sol87	1987	only	-	Mar	26	12:05:55s -0:05:55 -
Rule	sol87	1987	only	-	Mar	27	12:05:35s -0:05:35 -
Rule	sol87	1987	only	-	Mar	28	12:05:15s -0:05:15 -
Rule	sol87	1987	only	-	Mar	29	12:05:00s -0:05:00 -
Rule	sol87	1987	only	-	Mar	30	12:04:40s -0:04:40 -
Rule	sol87	1987	only	-	Mar	31	12:04:25s -0:04:25 -
Rule	sol87	1987	only	-	Apr	1	12:04:05s -0:04:05 -
Rule	sol87	1987	only	-	Apr	2	12:03:45s -0:03:45 -
Rule	sol87	1987	only	-	Apr	3	12:03:30s -0:03:30 -
Rule	sol87	1987	only	-	Apr	4	12:03:10s -0:03:10 -
Rule	sol87	1987	only	-	Apr	5	12:02:55s -0:02:55 -
Rule	sol87	1987	only	-	Apr	6	12:02:35s -0:02:35 -
Rule	sol87	1987	only	-	Apr	7	12:02:20s -0:02:20 -
Rule	sol87	1987	only	-	Apr	8	12:02:05s -0:02:05 -
Rule	sol87	1987	only	-	Apr	9	12:01:45s -0:01:45 -
Rule	sol87	1987	only	-	Apr	10	12:01:30s -0:01:30 -
Rule	sol87	1987	only	-	Apr	11	12:01:15s -0:01:15 -
Rule	sol87	1987	only	-	Apr	12	12:00:55s -0:00:55 -
Rule	sol87	1987	only	-	Apr	13	12:00:40s -0:00:40 -
Rule	sol87	1987	only	-	Apr	14	12:00:25s -0:00:25 -
Rule	sol87	1987	only	-	Apr	15	12:00:10s -0:00:10 -
Rule	sol87	1987	only	-	Apr	16	11:59:55s 0:00:05 -
Rule	sol87	1987	only	-	Apr	17	11:59:45s 0:00:15 -
Rule	sol87	1987	only	-	Apr	18	11:59:30s 0:00:30 -
Rule	sol87	1987	only	-	Apr	19	11:59:15s 0:00:45 -
Rule	sol87	1987	only	-	Apr	20	11:59:05s 0:00:55 -
Rule	sol87	1987	only	-	Apr	21	11:58:50s 0:01:10 -
Rule	sol87	1987	only	-	Apr	22	11:58:40s 0:01:20 -
Rule	sol87	1987	only	-	Apr	23	11:58:25s 0:01:35 -
Rule	sol87	1987	only	-	Apr	24	11:58:15s 0:01:45 -
Rule	sol87	1987	only	-	Apr	25	11:58:05s 0:01:55 -
Rule	sol87	1987	only	-	Apr	26	11:57:55s 0:02:05 -
Rule	sol87	1987	only	-	Apr	27	11:57:45s 0:02:15 -
Rule	sol87	1987	only	-	Apr	28	11:57:35s 0:02:25 -
Rule	sol87	1987	only	-	Apr	29	11:57:25s 0:02:35 -
Rule	sol87	1987	only	-	Apr	30	11:57:15s 0:02:45 -
Rule	sol87	1987	only	-	May	1	11:57:10s 0:02:50 -
Rule	sol87	1987	only	-	May	2	11:57:00s 0:03:00 -
Rule	sol87	1987	only	-	May	3	11:56:55s 0:03:05 -
Rule	sol87	1987	only	-	May	4	11:56:50s 0:03:10 -
Rule	sol87	1987	only	-	May	5	11:56:45s 0:03:15 -
Rule	sol87	1987	only	-	May	6	11:56:40s 0:03:20 -
Rule	sol87	1987	only	-	May	7	11:56:35s 0:03:25 -
Rule	sol87	1987	only	-	May	8	11:56:30s 0:03:30 -
Rule	sol87	1987	only	-	May	9	11:56:25s 0:03:35 -
Rule	sol87	1987	only	-	May	10	11:56:25s 0:03:35 -
Rule	sol87	1987	only	-	May	11	11:56:20s 0:03:40 -
Rule	sol87	1987	only	-	May	12	11:56:20s 0:03:40 -
Rule	sol87	1987	only	-	May	13	11:56:20s 0:03:40 -
Rule	sol87	1987	only	-	May	14	11:56:20s 0:03:40 -
Rule	sol87	1987	only	-	May	15	11:56:20s 0:03:40 -
Rule	sol87	1987	only	-	May	16	11:56:20s 0:03:40 -
Rule	sol87	1987	only	-	May	17	11:56:20s 0:03:40 -
Rule	sol87	1987	only	-	May	18	11:56:20s 0:03:40 -
Rule	sol87	1987	only	-	May	19	11:56:25s 0:03:35 -
Rule	sol87	1987	only	-	May	20	11:56:25s 0:03:35 -
Rule	sol87	1987	only	-	May	21	11:56:30s 0:03:30 -
Rule	sol87	1987	only	-	May	22	11:56:35s 0:03:25 -
Rule	sol87	1987	only	-	May	23	11:56:40s 0:03:20 -
Rule	sol87	1987	only	-	May	24	11:56:45s 0:03:15 -
Rule	sol87	1987	only	-	May	25	11:56:50s 0:03:10 -
Rule	sol87	1987	only	-	May	26	11:56:55s 0:03:05 -
Rule	sol87	1987	only	-	May	27	11:57:00s 0:03:00 -
Rule	sol87	1987	only	-	May	28	11:57:10s 0:02:50 -
Rule	sol87	1987	only	-	May	29	11:57:15s 0:02:45 -
Rule	sol87	1987	only	-	May	30	11:57:25s 0:02:35 -
Rule	sol87	1987	only	-	May	31	11:57:30s 0:02:30 -
Rule	sol87	1987	only	-	Jun	1	11:57:40s 0:02:20 -
Rule	sol87	1987	only	-	Jun	2	11:57:50s 0:02:10 -
Rule	sol87	1987	only	-	Jun	3	11:58:00s 0:02:00 -
Rule	sol87	1987	only	-	Jun	4	11:58:10s 0:01:50 -
Rule	sol87	1987	only	-	Jun	5	11:58:20s 0:01:40 -
Rule	sol87	1987	only	-	Jun	6	11:58:30s 0:01:30 -
Rule	sol87	1987	only	-	Jun	7	11:58:40s 0:01:20 -
Rule	sol87	1987	only	-	Jun	8	11:58:50s 0:01:10 -
Rule	sol87	1987	only	-	Jun	9	11:59:05s 0:00:55 -
Rule	sol87	1987	only	-	Jun	10	11:59:15s 0:00:45 -
Rule	sol87	1987	only	-	Jun	11	11:59:30s 0:00:30 -
Rule	sol87	1987	only	-	Jun	12	11:59:40s 0:00:20 -
Rule	sol87	1987	only	-	Jun	13	11:59:50s 0:00:10 -
Rule	sol87	1987	only	-	Jun	14	12:00:05s -0:00:05 -
Rule	sol87	1987	only	-	Jun	15	12:00:15s -0:00:15 -
Rule	sol87	1987	only	-	Jun	16	12:00:30s -0:00:30 -
Rule	sol87	1987	only	-	Jun	17	12:00:45s -0:00:45 -
Rule	sol87	1987	only	-	Jun	18	12:00:55s -0:00:55 -
Rule	sol87	1987	only	-	Jun	19	12:01:10s -0:01:10 -
Rule	sol87	1987	only	-	Jun	20	12:01:20s -0:01:20 -
Rule	sol87	1987	only	-	Jun	21	12:01:35s -0:01:35 -
Rule	sol87	1987	only	-	Jun	22	12:01:50s -0:01:50 -
Rule	sol87	1987	only	-	Jun	23	12:02:00s -0:02:00 -
Rule	sol87	1987	only	-	Jun	24	12:02:15s -0:02:15 -
Rule	sol87	1987	only	-	Jun	25	12:02:25s -0:02:25 -
Rule	sol87	1987	only	-	Jun	26	12:02:40s -0:02:40 -
Rule	sol87	1987	only	-	Jun	27	12:02:50s -0:02:50 -
Rule	sol87	1987	only	-	Jun	28	12:03:05s -0:03:05 -
Rule	sol87	1987	only	-	Jun	29	12:03:15s -0:03:15 -
Rule	sol87	1987	only	-	Jun	30	12:03:30s -0:03:30 -
Rule	sol87	1987	only	-	Jul	1	12:03:40s -0:03:40 -
Rule	sol87	1987	only	-	Jul	2	12:03:50s -0:03:50 -
Rule	sol87	1987	only	-	Jul	3	12:04:05s -0:04:05 -
Rule	sol87	1987	only	-	Jul	4	12:04:15s -0:04:15 -
Rule	sol87	1987	only	-	Jul	5	12:04:25s -0:04:25 -
Rule	sol87	1987	only	-	Jul	6	12:04:35s -0:04:35 -
Rule	sol87	1987	only	-	Jul	7	12:04:45s -0:04:45 -
Rule	sol87	1987	only	-	Jul	8	12:04:55s -0:04:55 -
Rule	sol87	1987	only	-	Jul	9	12:05:05s -0:05:05 -
Rule	sol87	1987	only	-	Jul	10	12:05:15s -0:05:15 -
Rule	sol87	1987	only	-	Jul	11	12:05:20s -0:05:20 -
Rule	sol87	1987	only	-	Jul	12	12:05:30s -0:05:30 -
Rule	sol87	1987	only	-	Jul	13	12:05:40s -0:05:40 -
Rule	sol87	1987	only	-	Jul	14	12:05:45s -0:05:45 -
Rule	sol87	1987	only	-	Jul	15	12:05:50s -0:05:50 -
Rule	sol87	1987	only	-	Jul	16	12:06:00s -0:06:00 -
Rule	sol87	1987	only	-	Jul	17	12:06:05s -0:06:05 -
Rule	sol87	1987	only	-	Jul	18	12:06:10s -0:06:10 -
Rule	sol87	1987	only	-	Jul	19	12:06:15s -0:06:15 -
Rule	sol87	1987	only	-	Jul	20	12:06:15s -0:06:15 -
Rule	sol87	1987	only	-	Jul	21	12:06:20s -0:06:20 -
Rule	sol87	1987	only	-	Jul	22	12:06:25s -0:06:25 -
Rule	sol87	1987	only	-	Jul	23	12:06:25s -0:06:25 -
Rule	sol87	1987	only	-	Jul	24	12:06:25s -0:06:25 -
Rule	sol87	1987	only	-	Jul	25	12:06:30s -0:06:30 -
Rule	sol87	1987	only	-	Jul	26	12:06:30s -0:06:30 -
Rule	sol87	1987	only	-	Jul	27	12:06:30s -0:06:30 -
Rule	sol87	1987	only	-	Jul	28	12:06:30s -0:06:30 -
Rule	sol87	1987	only	-	Jul	29	12:06:25s -0:06:25 -
Rule	sol87	1987	only	-	Jul	30	12:06:25s -0:06:25 -
Rule	sol87	1987	only	-	Jul	31	12:06:25s -0:06:25 -
Rule	sol87	1987	only	-	Aug	1	12:06:20s -0:06:20 -
Rule	sol87	1987	only	-	Aug	2	12:06:15s -0:06:15 -
Rule	sol87	1987	only	-	Aug	3	12:06:10s -0:06:10 -
Rule	sol87	1987	only	-	Aug	4	12:06:05s -0:06:05 -
Rule	sol87	1987	only	-	Aug	5	12:06:00s -0:06:00 -
Rule	sol87	1987	only	-	Aug	6	12:05:55s -0:05:55 -
Rule	sol87	1987	only	-	Aug	7	12:05:50s -0:05:50 -
Rule	sol87	1987	only	-	Aug	8	12:05:40s -0:05:40 -
Rule	sol87	1987	only	-	Aug	9	12:05:35s -0:05:35 -
Rule	sol87	1987	only	-	Aug	10	12:05:25s -0:05:25 -
Rule	sol87	1987	only	-	Aug	11	12:05:15s -0:05:15 -
Rule	sol87	1987	only	-	Aug	12	12:05:05s -0:05:05 -
Rule	sol87	1987	only	-	Aug	13	12:04:55s -0:04:55 -
Rule	sol87	1987	only	-	Aug	14	12:04:45s -0:04:45 -
Rule	sol87	1987	only	-	Aug	15	12:04:35s -0:04:35 -
Rule	sol87	1987	only	-	Aug	16	12:04:25s -0:04:25 -
Rule	sol87	1987	only	-	Aug	17	12:04:10s -0:04:10 -
Rule	sol87	1987	only	-	Aug	18	12:04:00s -0:04:00 -
Rule	sol87	1987	only	-	Aug	19	12:03:45s -0:03:45 -
Rule	sol87	1987	only	-	Aug	20	12:03:30s -0:03:30 -
Rule	sol87	1987	only	-	Aug	21	12:03:15s -0:03:15 -
Rule	sol87	1987	only	-	Aug	22	12:03:00s -0:03:00 -
Rule	sol87	1987	only	-	Aug	23	12:02:45s -0:02:45 -
Rule	sol87	1987	only	-	Aug	24	12:02:30s -0:02:30 -
Rule	sol87	1987	only	-	Aug	25	12:02:15s -0:02:15 -
Rule	sol87	1987	only	-	Aug	26	12:02:00s -0:02:00 -
Rule	sol87	1987	only	-	Aug	27	12:01:40s -0:01:40 -
Rule	sol87	1987	only	-	Aug	28	12:01:25s -0:01:25 -
Rule	sol87	1987	only	-	Aug	29	12:01:05s -0:01:05 -
Rule	sol87	1987	only	-	Aug	30	12:00:50s -0:00:50 -
Rule	sol87	1987	only	-	Aug	31	12:00:30s -0:00:30 -
Rule	sol87	1987	only	-	Sep	1	12:00:10s -0:00:10 -
Rule	sol87	1987	only	-	Sep	2	11:59:50s 0:00:10 -
Rule	sol87	1987	only	-	Sep	3	11:59:35s 0:00:25 -
Rule	sol87	1987	only	-	Sep	4	11:59:15s 0:00:45 -
Rule	sol87	1987	only	-	Sep	5	11:58:55s 0:01:05 -
Rule	sol87	1987	only	-	Sep	6	11:58:35s 0:01:25 -
Rule	sol87	1987	only	-	Sep	7	11:58:15s 0:01:45 -
Rule	sol87	1987	only	-	Sep	8	11:57:55s 0:02:05 -
Rule	sol87	1987	only	-	Sep	9	11:57:30s 0:02:30 -
Rule	sol87	1987	only	-	Sep	10	11:57:10s 0:02:50 -
Rule	sol87	1987	only	-	Sep	11	11:56:50s 0:03:10 -
Rule	sol87	1987	only	-	Sep	12	11:56:30s 0:03:30 -
Rule	sol87	1987	only	-	Sep	13	11:56:10s 0:03:50 -
Rule	sol87	1987	only	-	Sep	14	11:55:45s 0:04:15 -
Rule	sol87	1987	only	-	Sep	15	11:55:25s 0:04:35 -
Rule	sol87	1987	only	-	Sep	16	11:55:05s 0:04:55 -
Rule	sol87	1987	only	-	Sep	17	11:54:45s 0:05:15 -
Rule	sol87	1987	only	-	Sep	18	11:54:20s 0:05:40 -
Rule	sol87	1987	only	-	Sep	19	11:54:00s 0:06:00 -
Rule	sol87	1987	only	-	Sep	20	11:53:40s 0:06:20 -
Rule	sol87	1987	only	-	Sep	21	11:53:15s 0:06:45 -
Rule	sol87	1987	only	-	Sep	22	11:52:55s 0:07:05 -
Rule	sol87	1987	only	-	Sep	23	11:52:35s 0:07:25 -
Rule	sol87	1987	only	-	Sep	24	11:52:15s 0:07:45 -
Rule	sol87	1987	only	-	Sep	25	11:51:55s 0:08:05 -
Rule	sol87	1987	only	-	Sep	26	11:51:35s 0:08:25 -
Rule	sol87	1987	only	-	Sep	27	11:51:10s 0:08:50 -
Rule	sol87	1987	only	-	Sep	28	11:50:50s 0:09:10 -
Rule	sol87	1987	only	-	Sep	29	11:50:30s 0:09:30 -
Rule	sol87	1987	only	-	Sep	30	11:50:10s 0:09:50 -
Rule	sol87	1987	only	-	Oct	1	11:49:50s 0:10:10 -
Rule	sol87	1987	only	-	Oct	2	11:49:35s 0:10:25 -
Rule	sol87	1987	only	-	Oct	3	11:49:15s 0:10:45 -
Rule	sol87	1987	only	-	Oct	4	11:48:55s 0:11:05 -
Rule	sol87	1987	only	-	Oct	5	11:48:35s 0:11:25 -
Rule	sol87	1987	only	-	Oct	6	11:48:20s 0:11:40 -
Rule	sol87	1987	only	-	Oct	7	11:48:00s 0:12:00 -
Rule	sol87	1987	only	-	Oct	8	11:47:45s 0:12:15 -
Rule	sol87	1987	only	-	Oct	9	11:47:25s 0:12:35 -
Rule	sol87	1987	only	-	Oct	10	11:47:10s 0:12:50 -
Rule	sol87	1987	only	-	Oct	11	11:46:55s 0:13:05 -
Rule	sol87	1987	only	-	Oct	12	11:46:40s 0:13:20 -
Rule	sol87	1987	only	-	Oct	13	11:46:25s 0:13:35 -
Rule	sol87	1987	only	-	Oct	14	11:46:10s 0:13:50 -
Rule	sol87	1987	only	-	Oct	15	11:45:55s 0:14:05 -
Rule	sol87	1987	only	-	Oct	16	11:45:45s 0:14:15 -
Rule	sol87	1987	only	-	Oct	17	11:45:30s 0:14:30 -
Rule	sol87	1987	only	-	Oct	18	11:45:20s 0:14:40 -
Rule	sol87	1987	only	-	Oct	19	11:45:05s 0:14:55 -
Rule	sol87	1987	only	-	Oct	20	11:44:55s 0:15:05 -
Rule	sol87	1987	only	-	Oct	21	11:44:45s 0:15:15 -
Rule	sol87	1987	only	-	Oct	22	11:44:35s 0:15:25 -
Rule	sol87	1987	only	-	Oct	23	11:44:25s 0:15:35 -
Rule	sol87	1987	only	-	Oct	24	11:44:20s 0:15:40 -
Rule	sol87	1987	only	-	Oct	25	11:44:10s 0:15:50 -
Rule	sol87	1987	only	-	Oct	26	11:44:05s 0:15:55 -
Rule	sol87	1987	only	-	Oct	27	11:43:55s 0:16:05 -
Rule	sol87	1987	only	-	Oct	28	11:43:50s 0:16:10 -
Rule	sol87	1987	only	-	Oct	29	11:43:45s 0:16:15 -
Rule	sol87	1987	only	-	Oct	30	11:43:45s 0:16:15 -
Rule	sol87	1987	only	-	Oct	31	11:43:40s 0:16:20 -
Rule	sol87	1987	only	-	Nov	1	11:43:40s 0:16:20 -
Rule	sol87	1987	only	-	Nov	2	11:43:35s 0:16:25 -
Rule	sol87	1987	only	-	Nov	3	11:43:35s 0:16:25 -
Rule	sol87	1987	only	-	Nov	4	11:43:35s 0:16:25 -
Rule	sol87	1987	only	-	Nov	5	11:43:35s 0:16:25 -
Rule	sol87	1987	only	-	Nov	6	11:43:40s 0:16:20 -
Rule	sol87	1987	only	-	Nov	7	11:43:40s 0:16:20 -
Rule	sol87	1987	only	-	Nov	8	11:43:45s 0:16:15 -
Rule	sol87	1987	only	-	Nov	9	11:43:50s 0:16:10 -
Rule	sol87	1987	only	-	Nov	10	11:43:55s 0:16:05 -
Rule	sol87	1987	only	-	Nov	11	11:44:00s 0:16:00 -
Rule	sol87	1987	only	-	Nov	12	11:44:05s 0:15:55 -
Rule	sol87	1987	only	-	Nov	13	11:44:15s 0:15:45 -
Rule	sol87	1987	only	-	Nov	14	11:44:20s 0:15:40 -
Rule	sol87	1987	only	-	Nov	15	11:44:30s 0:15:30 -
Rule	sol87	1987	only	-	Nov	16	11:44:40s 0:15:20 -
Rule	sol87	1987	only	-	Nov	17	11:44:50s 0:15:10 -
Rule	sol87	1987	only	-	Nov	18	11:45:05s 0:14:55 -
Rule	sol87	1987	only	-	Nov	19	11:45:15s 0:14:45 -
Rule	sol87	1987	only	-	Nov	20	11:45:30s 0:14:30 -
Rule	sol87	1987	only	-	Nov	21	11:45:45s 0:14:15 -
Rule	sol87	1987	only	-	Nov	22	11:46:00s 0:14:00 -
Rule	sol87	1987	only	-	Nov	23	11:46:15s 0:13:45 -
Rule	sol87	1987	only	-	Nov	24	11:46:30s 0:13:30 -
Rule	sol87	1987	only	-	Nov	25	11:46:50s 0:13:10 -
Rule	sol87	1987	only	-	Nov	26	11:47:10s 0:12:50 -
Rule	sol87	1987	only	-	Nov	27	11:47:25s 0:12:35 -
Rule	sol87	1987	only	-	Nov	28	11:47:45s 0:12:15 -
Rule	sol87	1987	only	-	Nov	29	11:48:05s 0:11:55 -
Rule	sol87	1987	only	-	Nov	30	11:48:30s 0:11:30 -
Rule	sol87	1987	only	-	Dec	1	11:48:50s 0:11:10 -
Rule	sol87	1987	only	-	Dec	2	11:49:10s 0:10:50 -
Rule	sol87	1987	only	-	Dec	3	11:49:35s 0:10:25 -
Rule	sol87	1987	only	-	Dec	4	11:50:00s 0:10:00 -
Rule	sol87	1987	only	-	Dec	5	11:50:25s 0:09:35 -
Rule	sol87	1987	only	-	Dec	6	11:50:50s 0:09:10 -
Rule	sol87	1987	only	-	Dec	7	11:51:15s 0:08:45 -
Rule	sol87	1987	only	-	Dec	8	11:51:40s 0:08:20 -
Rule	sol87	1987	only	-	Dec	9	11:52:05s 0:07:55 -
Rule	sol87	1987	only	-	Dec	10	11:52:30s 0:07:30 -
Rule	sol87	1987	only	-	Dec	11	11:53:00s 0:07:00 -
Rule	sol87	1987	only	-	Dec	12	11:53:25s 0:06:35 -
Rule	sol87	1987	only	-	Dec	13	11:53:55s 0:06:05 -
Rule	sol87	1987	only	-	Dec	14	11:54:25s 0:05:35 -
Rule	sol87	1987	only	-	Dec	15	11:54:50s 0:05:10 -
Rule	sol87	1987	only	-	Dec	16	11:55:20s 0:04:40 -
Rule	sol87	1987	only	-	Dec	17	11:55:50s 0:04:10 -
Rule	sol87	1987	only	-	Dec	18	11:56:20s 0:03:40 -
Rule	sol87	1987	only	-	Dec	19	11:56:50s 0:03:10 -
Rule	sol87	1987	only	-	Dec	20	11:57:20s 0:02:40 -
Rule	sol87	1987	only	-	Dec	21	11:57:50s 0:02:10 -
Rule	sol87	1987	only	-	Dec	22	11:58:20s 0:01:40 -
Rule	sol87	1987	only	-	Dec	23	11:58:50s 0:01:10 -
Rule	sol87	1987	only	-	Dec	24	11:59:20s 0:00:40 -
Rule	sol87	1987	only	-	Dec	25	11:59:50s 0:00:10 -
Rule	sol87	1987	only	-	Dec	26	12:00:20s -0:00:20 -
Rule	sol87	1987	only	-	Dec	27	12:00:45s -0:00:45 -
Rule	sol87	1987	only	-	Dec	28	12:01:15s -0:01:15 -
Rule	sol87	1987	only	-	Dec	29	12:01:45s -0:01:45 -
Rule	sol87	1987	only	-	Dec	30	12:02:15s -0:02:15 -
Rule	sol87	1987	only	-	Dec	31	12:02:45s -0:02:45 -
Rule	sol88	1988	only	-	Jan	1	12:03:15s -0:03:15 -
Rule	sol88	1988	only	-	Jan	2	12:03:40s -0:03:40 -
Rule	sol88	1988	only	-	Jan	3	12:04:10s -0:04:10 -
Rule	sol88	1988	only	-	Jan	4	12:04:40s -0:04:40 -
Rule	sol88	1988	only	-	Jan	5	12:05:05s -0:05:05 -
Rule	sol88	1988	only	-	Jan	6	12:05:30s -0:05:30 -
Rule	sol88	1988	only	-	Jan	7	12:06:00s -0:06:00 -
Rule	sol88	1988	only	-	Jan	8	12:06:25s -0:06:25 -
Rule	sol88	1988	only	-	Jan	9	12:06:50s -0:06:50 -
Rule	sol88	1988	only	-	Jan	10	12:07:15s -0:07:15 -
Rule	sol88	1988	only	-	Jan	11	12:07:40s -0:07:40 -
Rule	sol88	1988	only	-	Jan	12	12:08:05s -0:08:05 -
Rule	sol88	1988	only	-	Jan	13	12:08:25s -0:08:25 -
Rule	sol88	1988	only	-	Jan	14	12:08:50s -0:08:50 -
Rule	sol88	1988	only	-	Jan	15	12:09:10s -0:09:10 -
Rule	sol88	1988	only	-	Jan	16	12:09:30s -0:09:30 -
Rule	sol88	1988	only	-	Jan	17	12:09:50s -0:09:50 -
Rule	sol88	1988	only	-	Jan	18	12:10:10s -0:10:10 -
Rule	sol88	1988	only	-	Jan	19	12:10:30s -0:10:30 -
Rule	sol88	1988	only	-	Jan	20	12:10:50s -0:10:50 -
Rule	sol88	1988	only	-	Jan	21	12:11:05s -0:11:05 -
Rule	sol88	1988	only	-	Jan	22	12:11:25s -0:11:25 -
Rule	sol88	1988	only	-	Jan	23	12:11:40s -0:11:40 -
Rule	sol88	1988	only	-	Jan	24	12:11:55s -0:11:55 -
Rule	sol88	1988	only	-	Jan	25	12:12:10s -0:12:10 -
Rule	sol88	1988	only	-	Jan	26	12:12:25s -0:12:25 -
Rule	sol88	1988	only	-	Jan	27	12:12:40s -0:12:40 -
Rule	sol88	1988	only	-	Jan	28	12:12:50s -0:12:50 -
Rule	sol88	1988	only	-	Jan	29	12:13:00s -0:13:00 -
Rule	sol88	1988	only	-	Jan	30	12:13:10s -0:13:10 -
Rule	sol88	1988	only	-	Jan	31	12:13:20s -0:13:20 -
Rule	sol88	1988	only	-	Feb	1	12:13:30s -0:13:30 -
Rule	sol88	1988	only	-	Feb	2	12:13:40s -0:13:40 -
Rule	sol88	1988	only	-	Feb	3	12:13:45s -0:13:45 -
Rule	sol88	1988	only	-	Feb	4	12:13:55s -0:13:55 -
Rule	sol88	1988	only	-	Feb	5	12:14:00s -0:14:00 -
Rule	sol88	1988	only	-	Feb	6	12:14:05s -0:14:05 -
Rule	sol88	1988	only	-	Feb	7	12:14:10s -0:14:10 -
Rule	sol88	1988	only	-	Feb	8	12:14:10s -0:14:10 -
Rule	sol88	1988	only	-	Feb	9	12:14:15s -0:14:15 -
Rule	sol88	1988	only	-	Feb	10	12:14:15s -0:14:15 -
Rule	sol88	1988	only	-	Feb	11	12:14:15s -0:14:15 -
Rule	sol88	1988	only	-	Feb	12	12:14:15s -0:14:15 -
Rule	sol88	1988	only	-	Feb	13	12:14:15s -0:14:15 -
Rule	sol88	1988	only	-	Feb	14	12:14:15s -0:14:15 -
Rule	sol88	1988	only	-	Feb	15	12:14:10s -0:14:10 -
Rule	sol88	1988	only	-	Feb	16	12:14:10s -0:14:10 -
Rule	sol88	1988	only	-	Feb	17	12:14:05s -0:14:05 -
Rule	sol88	1988	only	-	Feb	18	12:14:00s -0:14:00 -
Rule	sol88	1988	only	-	Feb	19	12:13:55s -0:13:55 -
Rule	sol88	1988	only	-	Feb	20	12:13:50s -0:13:50 -
Rule	sol88	1988	only	-	Feb	21	12:13:45s -0:13:45 -
Rule	sol88	1988	only	-	Feb	22	12:13:40s -0:13:40 -
Rule	sol88	1988	only	-	Feb	23	12:13:30s -0:13:30 -
Rule	sol88	1988	only	-	Feb	24	12:13:20s -0:13:20 -
Rule	sol88	1988	only	-	Feb	25	12:13:15s -0:13:15 -
Rule	sol88	1988	only	-	Feb	26	12:13:05s -0:13:05 -
Rule	sol88	1988	only	-	Feb	27	12:12:55s -0:12:55 -
Rule	sol88	1988	only	-	Feb	28	12:12:45s -0:12:45 -
Rule	sol88	1988	only	-	Feb	29	12:12:30s -0:12:30 -
Rule	sol88	1988	only	-	Mar	1	12:12:20s -0:12:20 -
Rule	sol88	1988	only	-	Mar	2	12:12:10s -0:12:10 -
Rule	sol88	1988	only	-	Mar	3	12:11:55s -0:11:55 -
Rule	sol88	1988	only	-	Mar	4	12:11:45s -0:11:45 -
Rule	sol88	1988	only	-	Mar	5	12:11:30s -0:11:30 -
Rule	sol88	1988	only	-	Mar	6	12:11:15s -0:11:15 -
Rule	sol88	1988	only	-	Mar	7	12:11:00s -0:11:00 -
Rule	sol88	1988	only	-	Mar	8	12:10:45s -0:10:45 -
Rule	sol88	1988	only	-	Mar	9	12:10:30s -0:10:30 -
Rule	sol88	1988	only	-	Mar	10	12:10:15s -0:10:15 -
Rule	sol88	1988	only	-	Mar	11	12:10:00s -0:10:00 -
Rule	sol88	1988	only	-	Mar	12	12:09:45s -0:09:45 -
Rule	sol88	1988	only	-	Mar	13	12:09:30s -0:09:30 -
Rule	sol88	1988	only	-	Mar	14	12:09:10s -0:09:10 -
Rule	sol88	1988	only	-	Mar	15	12:08:55s -0:08:55 -
Rule	sol88	1988	only	-	Mar	16	12:08:40s -0:08:40 -
Rule	sol88	1988	only	-	Mar	17	12:08:20s -0:08:20 -
Rule	sol88	1988	only	-	Mar	18	12:08:05s -0:08:05 -
Rule	sol88	1988	only	-	Mar	19	12:07:45s -0:07:45 -
Rule	sol88	1988	only	-	Mar	20	12:07:30s -0:07:30 -
Rule	sol88	1988	only	-	Mar	21	12:07:10s -0:07:10 -
Rule	sol88	1988	only	-	Mar	22	12:06:50s -0:06:50 -
Rule	sol88	1988	only	-	Mar	23	12:06:35s -0:06:35 -
Rule	sol88	1988	only	-	Mar	24	12:06:15s -0:06:15 -
Rule	sol88	1988	only	-	Mar	25	12:06:00s -0:06:00 -
Rule	sol88	1988	only	-	Mar	26	12:05:40s -0:05:40 -
Rule	sol88	1988	only	-	Mar	27	12:05:20s -0:05:20 -
Rule	sol88	1988	only	-	Mar	28	12:05:05s -0:05:05 -
Rule	sol88	1988	only	-	Mar	29	12:04:45s -0:04:45 -
Rule	sol88	1988	only	-	Mar	30	12:04:25s -0:04:25 -
Rule	sol88	1988	only	-	Mar	31	12:04:10s -0:04:10 -
Rule	sol88	1988	only	-	Apr	1	12:03:50s -0:03:50 -
Rule	sol88	1988	only	-	Apr	2	12:03:35s -0:03:35 -
Rule	sol88	1988	only	-	Apr	3	12:03:15s -0:03:15 -
Rule	sol88	1988	only	-	Apr	4	12:03:00s -0:03:00 -
Rule	sol88	1988	only	-	Apr	5	12:02:40s -0:02:40 -
Rule	sol88	1988	only	-	Apr	6	12:02:25s -0:02:25 -
Rule	sol88	1988	only	-	Apr	7	12:02:05s -0:02:05 -
Rule	sol88	1988	only	-	Apr	8	12:01:50s -0:01:50 -
Rule	sol88	1988	only	-	Apr	9	12:01:35s -0:01:35 -
Rule	sol88	1988	only	-	Apr	10	12:01:15s -0:01:15 -
Rule	sol88	1988	only	-	Apr	11	12:01:00s -0:01:00 -
Rule	sol88	1988	only	-	Apr	12	12:00:45s -0:00:45 -
Rule	sol88	1988	only	-	Apr	13	12:00:30s -0:00:30 -
Rule	sol88	1988	only	-	Apr	14	12:00:15s -0:00:15 -
Rule	sol88	1988	only	-	Apr	15	12:00:00s 0:00:00 -
Rule	sol88	1988	only	-	Apr	16	11:59:45s 0:00:15 -
Rule	sol88	1988	only	-	Apr	17	11:59:30s 0:00:30 -
Rule	sol88	1988	only	-	Apr	18	11:59:20s 0:00:40 -
Rule	sol88	1988	only	-	Apr	19	11:59:05s 0:00:55 -
Rule	sol88	1988	only	-	Apr	20	11:58:55s 0:01:05 -
Rule	sol88	1988	only	-	Apr	21	11:58:40s 0:01:20 -
Rule	sol88	1988	only	-	Apr	22	11:58:30s 0:01:30 -
Rule	sol88	1988	only	-	Apr	23	11:58:15s 0:01:45 -
Rule	sol88	1988	only	-	Apr	24	11:58:05s 0:01:55 -
Rule	sol88	1988	only	-	Apr	25	11:57:55s 0:02:05 -
Rule	sol88	1988	only	-	Apr	26	11:57:45s 0:02:15 -
Rule	sol88	1988	only	-	Apr	27	11:57:35s 0:02:25 -
Rule	sol88	1988	only	-	Apr	28	11:57:30s 0:02:30 -
Rule	sol88	1988	only	-	Apr	29	11:57:20s 0:02:40 -
Rule	sol88	1988	only	-	Apr	30	11:57:10s 0:02:50 -
Rule	sol88	1988	only	-	May	1	11:57:05s 0:02:55 -
Rule	sol88	1988	only	-	May	2	11:56:55s 0:03:05 -
Rule	sol88	1988	only	-	May	3	11:56:50s 0:03:10 -
Rule	sol88	1988	only	-	May	4	11:56:45s 0:03:15 -
Rule	sol88	1988	only	-	May	5	11:56:40s 0:03:20 -
Rule	sol88	1988	only	-	May	6	11:56:35s 0:03:25 -
Rule	sol88	1988	only	-	May	7	11:56:30s 0:03:30 -
Rule	sol88	1988	only	-	May	8	11:56:25s 0:03:35 -
Rule	sol88	1988	only	-	May	9	11:56:25s 0:03:35 -
Rule	sol88	1988	only	-	May	10	11:56:20s 0:03:40 -
Rule	sol88	1988	only	-	May	11	11:56:20s 0:03:40 -
Rule	sol88	1988	only	-	May	12	11:56:20s 0:03:40 -
Rule	sol88	1988	only	-	May	13	11:56:20s 0:03:40 -
Rule	sol88	1988	only	-	May	14	11:56:20s 0:03:40 -
Rule	sol88	1988	only	-	May	15	11:56:20s 0:03:40 -
Rule	sol88	1988	only	-	May	16	11:56:20s 0:03:40 -
Rule	sol88	1988	only	-	May	17	11:56:20s 0:03:40 -
Rule	sol88	1988	only	-	May	18	11:56:25s 0:03:35 -
Rule	sol88	1988	only	-	May	19	11:56:25s 0:03:35 -
Rule	sol88	1988	only	-	May	20	11:56:30s 0:03:30 -
Rule	sol88	1988	only	-	May	21	11:56:35s 0:03:25 -
Rule	sol88	1988	only	-	May	22	11:56:40s 0:03:20 -
Rule	sol88	1988	only	-	May	23	11:56:45s 0:03:15 -
Rule	sol88	1988	only	-	May	24	11:56:50s 0:03:10 -
Rule	sol88	1988	only	-	May	25	11:56:55s 0:03:05 -
Rule	sol88	1988	only	-	May	26	11:57:00s 0:03:00 -
Rule	sol88	1988	only	-	May	27	11:57:05s 0:02:55 -
Rule	sol88	1988	only	-	May	28	11:57:15s 0:02:45 -
Rule	sol88	1988	only	-	May	29	11:57:20s 0:02:40 -
Rule	sol88	1988	only	-	May	30	11:57:30s 0:02:30 -
Rule	sol88	1988	only	-	May	31	11:57:40s 0:02:20 -
Rule	sol88	1988	only	-	Jun	1	11:57:50s 0:02:10 -
Rule	sol88	1988	only	-	Jun	2	11:57:55s 0:02:05 -
Rule	sol88	1988	only	-	Jun	3	11:58:05s 0:01:55 -
Rule	sol88	1988	only	-	Jun	4	11:58:15s 0:01:45 -
Rule	sol88	1988	only	-	Jun	5	11:58:30s 0:01:30 -
Rule	sol88	1988	only	-	Jun	6	11:58:40s 0:01:20 -
Rule	sol88	1988	only	-	Jun	7	11:58:50s 0:01:10 -
Rule	sol88	1988	only	-	Jun	8	11:59:00s 0:01:00 -
Rule	sol88	1988	only	-	Jun	9	11:59:15s 0:00:45 -
Rule	sol88	1988	only	-	Jun	10	11:59:25s 0:00:35 -
Rule	sol88	1988	only	-	Jun	11	11:59:35s 0:00:25 -
Rule	sol88	1988	only	-	Jun	12	11:59:50s 0:00:10 -
Rule	sol88	1988	only	-	Jun	13	12:00:00s 0:00:00 -
Rule	sol88	1988	only	-	Jun	14	12:00:15s -0:00:15 -
Rule	sol88	1988	only	-	Jun	15	12:00:25s -0:00:25 -
Rule	sol88	1988	only	-	Jun	16	12:00:40s -0:00:40 -
Rule	sol88	1988	only	-	Jun	17	12:00:55s -0:00:55 -
Rule	sol88	1988	only	-	Jun	18	12:01:05s -0:01:05 -
Rule	sol88	1988	only	-	Jun	19	12:01:20s -0:01:20 -
Rule	sol88	1988	only	-	Jun	20	12:01:30s -0:01:30 -
Rule	sol88	1988	only	-	Jun	21	12:01:45s -0:01:45 -
Rule	sol88	1988	only	-	Jun	22	12:02:00s -0:02:00 -
Rule	sol88	1988	only	-	Jun	23	12:02:10s -0:02:10 -
Rule	sol88	1988	only	-	Jun	24	12:02:25s -0:02:25 -
Rule	sol88	1988	only	-	Jun	25	12:02:35s -0:02:35 -
Rule	sol88	1988	only	-	Jun	26	12:02:50s -0:02:50 -
Rule	sol88	1988	only	-	Jun	27	12:03:00s -0:03:00 -
Rule	sol88	1988	only	-	Jun	28	12:03:15s -0:03:15 -
Rule	sol88	1988	only	-	Jun	29	12:03:25s -0:03:25 -
Rule	sol88	1988	only	-	Jun	30	12:03:40s -0:03:40 -
Rule	sol88	1988	only	-	Jul	1	12:03:50s -0:03:50 -
Rule	sol88	1988	only	-	Jul	2	12:04:00s -0:04:00 -
Rule	sol88	1988	only	-	Jul	3	12:04:10s -0:04:10 -
Rule	sol88	1988	only	-	Jul	4	12:04:25s -0:04:25 -
Rule	sol88	1988	only	-	Jul	5	12:04:35s -0:04:35 -
Rule	sol88	1988	only	-	Jul	6	12:04:45s -0:04:45 -
Rule	sol88	1988	only	-	Jul	7	12:04:55s -0:04:55 -
Rule	sol88	1988	only	-	Jul	8	12:05:05s -0:05:05 -
Rule	sol88	1988	only	-	Jul	9	12:05:10s -0:05:10 -
Rule	sol88	1988	only	-	Jul	10	12:05:20s -0:05:20 -
Rule	sol88	1988	only	-	Jul	11	12:05:30s -0:05:30 -
Rule	sol88	1988	only	-	Jul	12	12:05:35s -0:05:35 -
Rule	sol88	1988	only	-	Jul	13	12:05:45s -0:05:45 -
Rule	sol88	1988	only	-	Jul	14	12:05:50s -0:05:50 -
Rule	sol88	1988	only	-	Jul	15	12:05:55s -0:05:55 -
Rule	sol88	1988	only	-	Jul	16	12:06:00s -0:06:00 -
Rule	sol88	1988	only	-	Jul	17	12:06:05s -0:06:05 -
Rule	sol88	1988	only	-	Jul	18	12:06:10s -0:06:10 -
Rule	sol88	1988	only	-	Jul	19	12:06:15s -0:06:15 -
Rule	sol88	1988	only	-	Jul	20	12:06:20s -0:06:20 -
Rule	sol88	1988	only	-	Jul	21	12:06:25s -0:06:25 -
Rule	sol88	1988	only	-	Jul	22	12:06:25s -0:06:25 -
Rule	sol88	1988	only	-	Jul	23	12:06:25s -0:06:25 -
Rule	sol88	1988	only	-	Jul	24	12:06:30s -0:06:30 -
Rule	sol88	1988	only	-	Jul	25	12:06:30s -0:06:30 -
Rule	sol88	1988	only	-	Jul	26	12:06:30s -0:06:30 -
Rule	sol88	1988	only	-	Jul	27	12:06:30s -0:06:30 -
Rule	sol88	1988	only	-	Jul	28	12:06:30s -0:06:30 -
Rule	sol88	1988	only	-	Jul	29	12:06:25s -0:06:25 -
Rule	sol88	1988	only	-	Jul	30	12:06:25s -0:06:25 -
Rule	sol88	1988	only	-	Jul	31	12:06:20s -0:06:20 -
Rule	sol88	1988	only	-	Aug	1	12:06:15s -0:06:15 -
Rule	sol88	1988	only	-	Aug	2	12:06:15s -0:06:15 -
Rule	sol88	1988	only	-	Aug	3	12:06:10s -0:06:10 -
Rule	sol88	1988	only	-	Aug	4	12:06:05s -0:06:05 -
Rule	sol88	1988	only	-	Aug	5	12:05:55s -0:05:55 -
Rule	sol88	1988	only	-	Aug	6	12:05:50s -0:05:50 -
Rule	sol88	1988	only	-	Aug	7	12:05:45s -0:05:45 -
Rule	sol88	1988	only	-	Aug	8	12:05:35s -0:05:35 -
Rule	sol88	1988	only	-	Aug	9	12:05:25s -0:05:25 -
Rule	sol88	1988	only	-	Aug	10	12:05:20s -0:05:20 -
Rule	sol88	1988	only	-	Aug	11	12:05:10s -0:05:10 -
Rule	sol88	1988	only	-	Aug	12	12:05:00s -0:05:00 -
Rule	sol88	1988	only	-	Aug	13	12:04:50s -0:04:50 -
Rule	sol88	1988	only	-	Aug	14	12:04:35s -0:04:35 -
Rule	sol88	1988	only	-	Aug	15	12:04:25s -0:04:25 -
Rule	sol88	1988	only	-	Aug	16	12:04:15s -0:04:15 -
Rule	sol88	1988	only	-	Aug	17	12:04:00s -0:04:00 -
Rule	sol88	1988	only	-	Aug	18	12:03:50s -0:03:50 -
Rule	sol88	1988	only	-	Aug	19	12:03:35s -0:03:35 -
Rule	sol88	1988	only	-	Aug	20	12:03:20s -0:03:20 -
Rule	sol88	1988	only	-	Aug	21	12:03:05s -0:03:05 -
Rule	sol88	1988	only	-	Aug	22	12:02:50s -0:02:50 -
Rule	sol88	1988	only	-	Aug	23	12:02:35s -0:02:35 -
Rule	sol88	1988	only	-	Aug	24	12:02:20s -0:02:20 -
Rule	sol88	1988	only	-	Aug	25	12:02:00s -0:02:00 -
Rule	sol88	1988	only	-	Aug	26	12:01:45s -0:01:45 -
Rule	sol88	1988	only	-	Aug	27	12:01:30s -0:01:30 -
Rule	sol88	1988	only	-	Aug	28	12:01:10s -0:01:10 -
Rule	sol88	1988	only	-	Aug	29	12:00:50s -0:00:50 -
Rule	sol88	1988	only	-	Aug	30	12:00:35s -0:00:35 -
Rule	sol88	1988	only	-	Aug	31	12:00:15s -0:00:15 -
Rule	sol88	1988	only	-	Sep	1	11:59:55s 0:00:05 -
Rule	sol88	1988	only	-	Sep	2	11:59:35s 0:00:25 -
Rule	sol88	1988	only	-	Sep	3	11:59:20s 0:00:40 -
Rule	sol88	1988	only	-	Sep	4	11:59:00s 0:01:00 -
Rule	sol88	1988	only	-	Sep	5	11:58:40s 0:01:20 -
Rule	sol88	1988	only	-	Sep	6	11:58:20s 0:01:40 -
Rule	sol88	1988	only	-	Sep	7	11:58:00s 0:02:00 -
Rule	sol88	1988	only	-	Sep	8	11:57:35s 0:02:25 -
Rule	sol88	1988	only	-	Sep	9	11:57:15s 0:02:45 -
Rule	sol88	1988	only	-	Sep	10	11:56:55s 0:03:05 -
Rule	sol88	1988	only	-	Sep	11	11:56:35s 0:03:25 -
Rule	sol88	1988	only	-	Sep	12	11:56:15s 0:03:45 -
Rule	sol88	1988	only	-	Sep	13	11:55:50s 0:04:10 -
Rule	sol88	1988	only	-	Sep	14	11:55:30s 0:04:30 -
Rule	sol88	1988	only	-	Sep	15	11:55:10s 0:04:50 -
Rule	sol88	1988	only	-	Sep	16	11:54:50s 0:05:10 -
Rule	sol88	1988	only	-	Sep	17	11:54:25s 0:05:35 -
Rule	sol88	1988	only	-	Sep	18	11:54:05s 0:05:55 -
Rule	sol88	1988	only	-	Sep	19	11:53:45s 0:06:15 -
Rule	sol88	1988	only	-	Sep	20	11:53:25s 0:06:35 -
Rule	sol88	1988	only	-	Sep	21	11:53:00s 0:07:00 -
Rule	sol88	1988	only	-	Sep	22	11:52:40s 0:07:20 -
Rule	sol88	1988	only	-	Sep	23	11:52:20s 0:07:40 -
Rule	sol88	1988	only	-	Sep	24	11:52:00s 0:08:00 -
Rule	sol88	1988	only	-	Sep	25	11:51:40s 0:08:20 -
Rule	sol88	1988	only	-	Sep	26	11:51:15s 0:08:45 -
Rule	sol88	1988	only	-	Sep	27	11:50:55s 0:09:05 -
Rule	sol88	1988	only	-	Sep	28	11:50:35s 0:09:25 -
Rule	sol88	1988	only	-	Sep	29	11:50:15s 0:09:45 -
Rule	sol88	1988	only	-	Sep	30	11:49:55s 0:10:05 -
Rule	sol88	1988	only	-	Oct	1	11:49:35s 0:10:25 -
Rule	sol88	1988	only	-	Oct	2	11:49:20s 0:10:40 -
Rule	sol88	1988	only	-	Oct	3	11:49:00s 0:11:00 -
Rule	sol88	1988	only	-	Oct	4	11:48:40s 0:11:20 -
Rule	sol88	1988	only	-	Oct	5	11:48:25s 0:11:35 -
Rule	sol88	1988	only	-	Oct	6	11:48:05s 0:11:55 -
Rule	sol88	1988	only	-	Oct	7	11:47:50s 0:12:10 -
Rule	sol88	1988	only	-	Oct	8	11:47:30s 0:12:30 -
Rule	sol88	1988	only	-	Oct	9	11:47:15s 0:12:45 -
Rule	sol88	1988	only	-	Oct	10	11:47:00s 0:13:00 -
Rule	sol88	1988	only	-	Oct	11	11:46:45s 0:13:15 -
Rule	sol88	1988	only	-	Oct	12	11:46:30s 0:13:30 -
Rule	sol88	1988	only	-	Oct	13	11:46:15s 0:13:45 -
Rule	sol88	1988	only	-	Oct	14	11:46:00s 0:14:00 -
Rule	sol88	1988	only	-	Oct	15	11:45:45s 0:14:15 -
Rule	sol88	1988	only	-	Oct	16	11:45:35s 0:14:25 -
Rule	sol88	1988	only	-	Oct	17	11:45:20s 0:14:40 -
Rule	sol88	1988	only	-	Oct	18	11:45:10s 0:14:50 -
Rule	sol88	1988	only	-	Oct	19	11:45:00s 0:15:00 -
Rule	sol88	1988	only	-	Oct	20	11:44:45s 0:15:15 -
Rule	sol88	1988	only	-	Oct	21	11:44:40s 0:15:20 -
Rule	sol88	1988	only	-	Oct	22	11:44:30s 0:15:30 -
Rule	sol88	1988	only	-	Oct	23	11:44:20s 0:15:40 -
Rule	sol88	1988	only	-	Oct	24	11:44:10s 0:15:50 -
Rule	sol88	1988	only	-	Oct	25	11:44:05s 0:15:55 -
Rule	sol88	1988	only	-	Oct	26	11:44:00s 0:16:00 -
Rule	sol88	1988	only	-	Oct	27	11:43:55s 0:16:05 -
Rule	sol88	1988	only	-	Oct	28	11:43:50s 0:16:10 -
Rule	sol88	1988	only	-	Oct	29	11:43:45s 0:16:15 -
Rule	sol88	1988	only	-	Oct	30	11:43:40s 0:16:20 -
Rule	sol88	1988	only	-	Oct	31	11:43:40s 0:16:20 -
Rule	sol88	1988	only	-	Nov	1	11:43:35s 0:16:25 -
Rule	sol88	1988	only	-	Nov	2	11:43:35s 0:16:25 -
Rule	sol88	1988	only	-	Nov	3	11:43:35s 0:16:25 -
Rule	sol88	1988	only	-	Nov	4	11:43:35s 0:16:25 -
Rule	sol88	1988	only	-	Nov	5	11:43:40s 0:16:20 -
Rule	sol88	1988	only	-	Nov	6	11:43:40s 0:16:20 -
Rule	sol88	1988	only	-	Nov	7	11:43:45s 0:16:15 -
Rule	sol88	1988	only	-	Nov	8	11:43:45s 0:16:15 -
Rule	sol88	1988	only	-	Nov	9	11:43:50s 0:16:10 -
Rule	sol88	1988	only	-	Nov	10	11:44:00s 0:16:00 -
Rule	sol88	1988	only	-	Nov	11	11:44:05s 0:15:55 -
Rule	sol88	1988	only	-	Nov	12	11:44:10s 0:15:50 -
Rule	sol88	1988	only	-	Nov	13	11:44:20s 0:15:40 -
Rule	sol88	1988	only	-	Nov	14	11:44:30s 0:15:30 -
Rule	sol88	1988	only	-	Nov	15	11:44:40s 0:15:20 -
Rule	sol88	1988	only	-	Nov	16	11:44:50s 0:15:10 -
Rule	sol88	1988	only	-	Nov	17	11:45:00s 0:15:00 -
Rule	sol88	1988	only	-	Nov	18	11:45:15s 0:14:45 -
Rule	sol88	1988	only	-	Nov	19	11:45:25s 0:14:35 -
Rule	sol88	1988	only	-	Nov	20	11:45:40s 0:14:20 -
Rule	sol88	1988	only	-	Nov	21	11:45:55s 0:14:05 -
Rule	sol88	1988	only	-	Nov	22	11:46:10s 0:13:50 -
Rule	sol88	1988	only	-	Nov	23	11:46:30s 0:13:30 -
Rule	sol88	1988	only	-	Nov	24	11:46:45s 0:13:15 -
Rule	sol88	1988	only	-	Nov	25	11:47:05s 0:12:55 -
Rule	sol88	1988	only	-	Nov	26	11:47:20s 0:12:40 -
Rule	sol88	1988	only	-	Nov	27	11:47:40s 0:12:20 -
Rule	sol88	1988	only	-	Nov	28	11:48:00s 0:12:00 -
Rule	sol88	1988	only	-	Nov	29	11:48:25s 0:11:35 -
Rule	sol88	1988	only	-	Nov	30	11:48:45s 0:11:15 -
Rule	sol88	1988	only	-	Dec	1	11:49:05s 0:10:55 -
Rule	sol88	1988	only	-	Dec	2	11:49:30s 0:10:30 -
Rule	sol88	1988	only	-	Dec	3	11:49:55s 0:10:05 -
Rule	sol88	1988	only	-	Dec	4	11:50:15s 0:09:45 -
Rule	sol88	1988	only	-	Dec	5	11:50:40s 0:09:20 -
Rule	sol88	1988	only	-	Dec	6	11:51:05s 0:08:55 -
Rule	sol88	1988	only	-	Dec	7	11:51:35s 0:08:25 -
Rule	sol88	1988	only	-	Dec	8	11:52:00s 0:08:00 -
Rule	sol88	1988	only	-	Dec	9	11:52:25s 0:07:35 -
Rule	sol88	1988	only	-	Dec	10	11:52:55s 0:07:05 -
Rule	sol88	1988	only	-	Dec	11	11:53:20s 0:06:40 -
Rule	sol88	1988	only	-	Dec	12	11:53:50s 0:06:10 -
Rule	sol88	1988	only	-	Dec	13	11:54:15s 0:05:45 -
Rule	sol88	1988	only	-	Dec	14	11:54:45s 0:05:15 -
Rule	sol88	1988	only	-	Dec	15	11:55:15s 0:04:45 -
Rule	sol88	1988	only	-	Dec	16	11:55:45s 0:04:15 -
Rule	sol88	1988	only	-	Dec	17	11:56:15s 0:03:45 -
Rule	sol88	1988	only	-	Dec	18	11:56:40s 0:03:20 -
Rule	sol88	1988	only	-	Dec	19	11:57:10s 0:02:50 -
Rule	sol88	1988	only	-	Dec	20	11:57:40s 0:02:20 -
Rule	sol88	1988	only	-	Dec	21	11:58:10s 0:01:50 -
Rule	sol88	1988	only	-	Dec	22	11:58:40s 0:01:20 -
Rule	sol88	1988	only	-	Dec	23	11:59:10s 0:00:50 -
Rule	sol88	1988	only	-	Dec	24	11:59:40s 0:00:20 -
Rule	sol88	1988	only	-	Dec	25	12:00:10s -0:00:10 -
Rule	sol88	1988	only	-	Dec	26	12:00:40s -0:00:40 -
Rule	sol88	1988	only	-	Dec	27	12:01:10s -0:01:10 -
Rule	sol88	1988	only	-	Dec	28	12:01:40s -0:01:40 -
Rule	sol88	1988	only	-	Dec	29	12:02:10s -0:02:10 -
Rule	sol88	1988	only	-	Dec	30	12:02:35s -0:02:35 -
Rule	sol88	1988	only	-	Dec	31	12:03:05s -0:03:05 -
Rule	sol89	1989	only	-	Jan	1	12:03:35s -0:03:35 -
Rule	sol89	1989	only	-	Jan	2	12:04:05s -0:04:05 -
Rule	sol89	1989	only	-	Jan	3	12:04:30s -0:04:30 -
Rule	sol89	1989	only	-	Jan	4	12:05:00s -0:05:00 -
Rule	sol89	1989	only	-	Jan	5	12:05:25s -0:05:25 -
Rule	sol89	1989	only	-	Jan	6	12:05:50s -0:05:50 -
Rule	sol89	1989	only	-	Jan	7	12:06:15s -0:06:15 -
Rule	sol89	1989	only	-	Jan	8	12:06:45s -0:06:45 -
Rule	sol89	1989	only	-	Jan	9	12:07:10s -0:07:10 -
Rule	sol89	1989	only	-	Jan	10	12:07:35s -0:07:35 -
Rule	sol89	1989	only	-	Jan	11	12:07:55s -0:07:55 -
Rule	sol89	1989	only	-	Jan	12	12:08:20s -0:08:20 -
Rule	sol89	1989	only	-	Jan	13	12:08:45s -0:08:45 -
Rule	sol89	1989	only	-	Jan	14	12:09:05s -0:09:05 -
Rule	sol89	1989	only	-	Jan	15	12:09:25s -0:09:25 -
Rule	sol89	1989	only	-	Jan	16	12:09:45s -0:09:45 -
Rule	sol89	1989	only	-	Jan	17	12:10:05s -0:10:05 -
Rule	sol89	1989	only	-	Jan	18	12:10:25s -0:10:25 -
Rule	sol89	1989	only	-	Jan	19	12:10:45s -0:10:45 -
Rule	sol89	1989	only	-	Jan	20	12:11:05s -0:11:05 -
Rule	sol89	1989	only	-	Jan	21	12:11:20s -0:11:20 -
Rule	sol89	1989	only	-	Jan	22	12:11:35s -0:11:35 -
Rule	sol89	1989	only	-	Jan	23	12:11:55s -0:11:55 -
Rule	sol89	1989	only	-	Jan	24	12:12:10s -0:12:10 -
Rule	sol89	1989	only	-	Jan	25	12:12:20s -0:12:20 -
Rule	sol89	1989	only	-	Jan	26	12:12:35s -0:12:35 -
Rule	sol89	1989	only	-	Jan	27	12:12:50s -0:12:50 -
Rule	sol89	1989	only	-	Jan	28	12:13:00s -0:13:00 -
Rule	sol89	1989	only	-	Jan	29	12:13:10s -0:13:10 -
Rule	sol89	1989	only	-	Jan	30	12:13:20s -0:13:20 -
Rule	sol89	1989	only	-	Jan	31	12:13:30s -0:13:30 -
Rule	sol89	1989	only	-	Feb	1	12:13:40s -0:13:40 -
Rule	sol89	1989	only	-	Feb	2	12:13:45s -0:13:45 -
Rule	sol89	1989	only	-	Feb	3	12:13:55s -0:13:55 -
Rule	sol89	1989	only	-	Feb	4	12:14:00s -0:14:00 -
Rule	sol89	1989	only	-	Feb	5	12:14:05s -0:14:05 -
Rule	sol89	1989	only	-	Feb	6	12:14:10s -0:14:10 -
Rule	sol89	1989	only	-	Feb	7	12:14:10s -0:14:10 -
Rule	sol89	1989	only	-	Feb	8	12:14:15s -0:14:15 -
Rule	sol89	1989	only	-	Feb	9	12:14:15s -0:14:15 -
Rule	sol89	1989	only	-	Feb	10	12:14:20s -0:14:20 -
Rule	sol89	1989	only	-	Feb	11	12:14:20s -0:14:20 -
Rule	sol89	1989	only	-	Feb	12	12:14:20s -0:14:20 -
Rule	sol89	1989	only	-	Feb	13	12:14:15s -0:14:15 -
Rule	sol89	1989	only	-	Feb	14	12:14:15s -0:14:15 -
Rule	sol89	1989	only	-	Feb	15	12:14:10s -0:14:10 -
Rule	sol89	1989	only	-	Feb	16	12:14:10s -0:14:10 -
Rule	sol89	1989	only	-	Feb	17	12:14:05s -0:14:05 -
Rule	sol89	1989	only	-	Feb	18	12:14:00s -0:14:00 -
Rule	sol89	1989	only	-	Feb	19	12:13:55s -0:13:55 -
Rule	sol89	1989	only	-	Feb	20	12:13:50s -0:13:50 -
Rule	sol89	1989	only	-	Feb	21	12:13:40s -0:13:40 -
Rule	sol89	1989	only	-	Feb	22	12:13:35s -0:13:35 -
Rule	sol89	1989	only	-	Feb	23	12:13:25s -0:13:25 -
Rule	sol89	1989	only	-	Feb	24	12:13:15s -0:13:15 -
Rule	sol89	1989	only	-	Feb	25	12:13:05s -0:13:05 -
Rule	sol89	1989	only	-	Feb	26	12:12:55s -0:12:55 -
Rule	sol89	1989	only	-	Feb	27	12:12:45s -0:12:45 -
Rule	sol89	1989	only	-	Feb	28	12:12:35s -0:12:35 -
Rule	sol89	1989	only	-	Mar	1	12:12:25s -0:12:25 -
Rule	sol89	1989	only	-	Mar	2	12:12:10s -0:12:10 -
Rule	sol89	1989	only	-	Mar	3	12:12:00s -0:12:00 -
Rule	sol89	1989	only	-	Mar	4	12:11:45s -0:11:45 -
Rule	sol89	1989	only	-	Mar	5	12:11:35s -0:11:35 -
Rule	sol89	1989	only	-	Mar	6	12:11:20s -0:11:20 -
Rule	sol89	1989	only	-	Mar	7	12:11:05s -0:11:05 -
Rule	sol89	1989	only	-	Mar	8	12:10:50s -0:10:50 -
Rule	sol89	1989	only	-	Mar	9	12:10:35s -0:10:35 -
Rule	sol89	1989	only	-	Mar	10	12:10:20s -0:10:20 -
Rule	sol89	1989	only	-	Mar	11	12:10:05s -0:10:05 -
Rule	sol89	1989	only	-	Mar	12	12:09:50s -0:09:50 -
Rule	sol89	1989	only	-	Mar	13	12:09:30s -0:09:30 -
Rule	sol89	1989	only	-	Mar	14	12:09:15s -0:09:15 -
Rule	sol89	1989	only	-	Mar	15	12:09:00s -0:09:00 -
Rule	sol89	1989	only	-	Mar	16	12:08:40s -0:08:40 -
Rule	sol89	1989	only	-	Mar	17	12:08:25s -0:08:25 -
Rule	sol89	1989	only	-	Mar	18	12:08:05s -0:08:05 -
Rule	sol89	1989	only	-	Mar	19	12:07:50s -0:07:50 -
Rule	sol89	1989	only	-	Mar	20	12:07:30s -0:07:30 -
Rule	sol89	1989	only	-	Mar	21	12:07:15s -0:07:15 -
Rule	sol89	1989	only	-	Mar	22	12:06:55s -0:06:55 -
Rule	sol89	1989	only	-	Mar	23	12:06:35s -0:06:35 -
Rule	sol89	1989	only	-	Mar	24	12:06:20s -0:06:20 -
Rule	sol89	1989	only	-	Mar	25	12:06:00s -0:06:00 -
Rule	sol89	1989	only	-	Mar	26	12:05:40s -0:05:40 -
Rule	sol89	1989	only	-	Mar	27	12:05:25s -0:05:25 -
Rule	sol89	1989	only	-	Mar	28	12:05:05s -0:05:05 -
Rule	sol89	1989	only	-	Mar	29	12:04:50s -0:04:50 -
Rule	sol89	1989	only	-	Mar	30	12:04:30s -0:04:30 -
Rule	sol89	1989	only	-	Mar	31	12:04:10s -0:04:10 -
Rule	sol89	1989	only	-	Apr	1	12:03:55s -0:03:55 -
Rule	sol89	1989	only	-	Apr	2	12:03:35s -0:03:35 -
Rule	sol89	1989	only	-	Apr	3	12:03:20s -0:03:20 -
Rule	sol89	1989	only	-	Apr	4	12:03:00s -0:03:00 -
Rule	sol89	1989	only	-	Apr	5	12:02:45s -0:02:45 -
Rule	sol89	1989	only	-	Apr	6	12:02:25s -0:02:25 -
Rule	sol89	1989	only	-	Apr	7	12:02:10s -0:02:10 -
Rule	sol89	1989	only	-	Apr	8	12:01:50s -0:01:50 -
Rule	sol89	1989	only	-	Apr	9	12:01:35s -0:01:35 -
Rule	sol89	1989	only	-	Apr	10	12:01:20s -0:01:20 -
Rule	sol89	1989	only	-	Apr	11	12:01:05s -0:01:05 -
Rule	sol89	1989	only	-	Apr	12	12:00:50s -0:00:50 -
Rule	sol89	1989	only	-	Apr	13	12:00:35s -0:00:35 -
Rule	sol89	1989	only	-	Apr	14	12:00:20s -0:00:20 -
Rule	sol89	1989	only	-	Apr	15	12:00:05s -0:00:05 -
Rule	sol89	1989	only	-	Apr	16	11:59:50s 0:00:10 -
Rule	sol89	1989	only	-	Apr	17	11:59:35s 0:00:25 -
Rule	sol89	1989	only	-	Apr	18	11:59:20s 0:00:40 -
Rule	sol89	1989	only	-	Apr	19	11:59:10s 0:00:50 -
Rule	sol89	1989	only	-	Apr	20	11:58:55s 0:01:05 -
Rule	sol89	1989	only	-	Apr	21	11:58:45s 0:01:15 -
Rule	sol89	1989	only	-	Apr	22	11:58:30s 0:01:30 -
Rule	sol89	1989	only	-	Apr	23	11:58:20s 0:01:40 -
Rule	sol89	1989	only	-	Apr	24	11:58:10s 0:01:50 -
Rule	sol89	1989	only	-	Apr	25	11:58:00s 0:02:00 -
Rule	sol89	1989	only	-	Apr	26	11:57:50s 0:02:10 -
Rule	sol89	1989	only	-	Apr	27	11:57:40s 0:02:20 -
Rule	sol89	1989	only	-	Apr	28	11:57:30s 0:02:30 -
Rule	sol89	1989	only	-	Apr	29	11:57:20s 0:02:40 -
Rule	sol89	1989	only	-	Apr	30	11:57:15s 0:02:45 -
Rule	sol89	1989	only	-	May	1	11:57:05s 0:02:55 -
Rule	sol89	1989	only	-	May	2	11:57:00s 0:03:00 -
Rule	sol89	1989	only	-	May	3	11:56:50s 0:03:10 -
Rule	sol89	1989	only	-	May	4	11:56:45s 0:03:15 -
Rule	sol89	1989	only	-	May	5	11:56:40s 0:03:20 -
Rule	sol89	1989	only	-	May	6	11:56:35s 0:03:25 -
Rule	sol89	1989	only	-	May	7	11:56:30s 0:03:30 -
Rule	sol89	1989	only	-	May	8	11:56:30s 0:03:30 -
Rule	sol89	1989	only	-	May	9	11:56:25s 0:03:35 -
Rule	sol89	1989	only	-	May	10	11:56:25s 0:03:35 -
Rule	sol89	1989	only	-	May	11	11:56:20s 0:03:40 -
Rule	sol89	1989	only	-	May	12	11:56:20s 0:03:40 -
Rule	sol89	1989	only	-	May	13	11:56:20s 0:03:40 -
Rule	sol89	1989	only	-	May	14	11:56:20s 0:03:40 -
Rule	sol89	1989	only	-	May	15	11:56:20s 0:03:40 -
Rule	sol89	1989	only	-	May	16	11:56:20s 0:03:40 -
Rule	sol89	1989	only	-	May	17	11:56:20s 0:03:40 -
Rule	sol89	1989	only	-	May	18	11:56:25s 0:03:35 -
Rule	sol89	1989	only	-	May	19	11:56:25s 0:03:35 -
Rule	sol89	1989	only	-	May	20	11:56:30s 0:03:30 -
Rule	sol89	1989	only	-	May	21	11:56:35s 0:03:25 -
Rule	sol89	1989	only	-	May	22	11:56:35s 0:03:25 -
Rule	sol89	1989	only	-	May	23	11:56:40s 0:03:20 -
Rule	sol89	1989	only	-	May	24	11:56:45s 0:03:15 -
Rule	sol89	1989	only	-	May	25	11:56:55s 0:03:05 -
Rule	sol89	1989	only	-	May	26	11:57:00s 0:03:00 -
Rule	sol89	1989	only	-	May	27	11:57:05s 0:02:55 -
Rule	sol89	1989	only	-	May	28	11:57:15s 0:02:45 -
Rule	sol89	1989	only	-	May	29	11:57:20s 0:02:40 -
Rule	sol89	1989	only	-	May	30	11:57:30s 0:02:30 -
Rule	sol89	1989	only	-	May	31	11:57:35s 0:02:25 -
Rule	sol89	1989	only	-	Jun	1	11:57:45s 0:02:15 -
Rule	sol89	1989	only	-	Jun	2	11:57:55s 0:02:05 -
Rule	sol89	1989	only	-	Jun	3	11:58:05s 0:01:55 -
Rule	sol89	1989	only	-	Jun	4	11:58:15s 0:01:45 -
Rule	sol89	1989	only	-	Jun	5	11:58:25s 0:01:35 -
Rule	sol89	1989	only	-	Jun	6	11:58:35s 0:01:25 -
Rule	sol89	1989	only	-	Jun	7	11:58:45s 0:01:15 -
Rule	sol89	1989	only	-	Jun	8	11:59:00s 0:01:00 -
Rule	sol89	1989	only	-	Jun	9	11:59:10s 0:00:50 -
Rule	sol89	1989	only	-	Jun	10	11:59:20s 0:00:40 -
Rule	sol89	1989	only	-	Jun	11	11:59:35s 0:00:25 -
Rule	sol89	1989	only	-	Jun	12	11:59:45s 0:00:15 -
Rule	sol89	1989	only	-	Jun	13	12:00:00s 0:00:00 -
Rule	sol89	1989	only	-	Jun	14	12:00:10s -0:00:10 -
Rule	sol89	1989	only	-	Jun	15	12:00:25s -0:00:25 -
Rule	sol89	1989	only	-	Jun	16	12:00:35s -0:00:35 -
Rule	sol89	1989	only	-	Jun	17	12:00:50s -0:00:50 -
Rule	sol89	1989	only	-	Jun	18	12:01:05s -0:01:05 -
Rule	sol89	1989	only	-	Jun	19	12:01:15s -0:01:15 -
Rule	sol89	1989	only	-	Jun	20	12:01:30s -0:01:30 -
Rule	sol89	1989	only	-	Jun	21	12:01:40s -0:01:40 -
Rule	sol89	1989	only	-	Jun	22	12:01:55s -0:01:55 -
Rule	sol89	1989	only	-	Jun	23	12:02:10s -0:02:10 -
Rule	sol89	1989	only	-	Jun	24	12:02:20s -0:02:20 -
Rule	sol89	1989	only	-	Jun	25	12:02:35s -0:02:35 -
Rule	sol89	1989	only	-	Jun	26	12:02:45s -0:02:45 -
Rule	sol89	1989	only	-	Jun	27	12:03:00s -0:03:00 -
Rule	sol89	1989	only	-	Jun	28	12:03:10s -0:03:10 -
Rule	sol89	1989	only	-	Jun	29	12:03:25s -0:03:25 -
Rule	sol89	1989	only	-	Jun	30	12:03:35s -0:03:35 -
Rule	sol89	1989	only	-	Jul	1	12:03:45s -0:03:45 -
Rule	sol89	1989	only	-	Jul	2	12:04:00s -0:04:00 -
Rule	sol89	1989	only	-	Jul	3	12:04:10s -0:04:10 -
Rule	sol89	1989	only	-	Jul	4	12:04:20s -0:04:20 -
Rule	sol89	1989	only	-	Jul	5	12:04:30s -0:04:30 -
Rule	sol89	1989	only	-	Jul	6	12:04:40s -0:04:40 -
Rule	sol89	1989	only	-	Jul	7	12:04:50s -0:04:50 -
Rule	sol89	1989	only	-	Jul	8	12:05:00s -0:05:00 -
Rule	sol89	1989	only	-	Jul	9	12:05:10s -0:05:10 -
Rule	sol89	1989	only	-	Jul	10	12:05:20s -0:05:20 -
Rule	sol89	1989	only	-	Jul	11	12:05:25s -0:05:25 -
Rule	sol89	1989	only	-	Jul	12	12:05:35s -0:05:35 -
Rule	sol89	1989	only	-	Jul	13	12:05:40s -0:05:40 -
Rule	sol89	1989	only	-	Jul	14	12:05:50s -0:05:50 -
Rule	sol89	1989	only	-	Jul	15	12:05:55s -0:05:55 -
Rule	sol89	1989	only	-	Jul	16	12:06:00s -0:06:00 -
Rule	sol89	1989	only	-	Jul	17	12:06:05s -0:06:05 -
Rule	sol89	1989	only	-	Jul	18	12:06:10s -0:06:10 -
Rule	sol89	1989	only	-	Jul	19	12:06:15s -0:06:15 -
Rule	sol89	1989	only	-	Jul	20	12:06:20s -0:06:20 -
Rule	sol89	1989	only	-	Jul	21	12:06:20s -0:06:20 -
Rule	sol89	1989	only	-	Jul	22	12:06:25s -0:06:25 -
Rule	sol89	1989	only	-	Jul	23	12:06:25s -0:06:25 -
Rule	sol89	1989	only	-	Jul	24	12:06:30s -0:06:30 -
Rule	sol89	1989	only	-	Jul	25	12:06:30s -0:06:30 -
Rule	sol89	1989	only	-	Jul	26	12:06:30s -0:06:30 -
Rule	sol89	1989	only	-	Jul	27	12:06:30s -0:06:30 -
Rule	sol89	1989	only	-	Jul	28	12:06:30s -0:06:30 -
Rule	sol89	1989	only	-	Jul	29	12:06:25s -0:06:25 -
Rule	sol89	1989	only	-	Jul	30	12:06:25s -0:06:25 -
Rule	sol89	1989	only	-	Jul	31	12:06:20s -0:06:20 -
Rule	sol89	1989	only	-	Aug	1	12:06:20s -0:06:20 -
Rule	sol89	1989	only	-	Aug	2	12:06:15s -0:06:15 -
Rule	sol89	1989	only	-	Aug	3	12:06:10s -0:06:10 -
Rule	sol89	1989	only	-	Aug	4	12:06:05s -0:06:05 -
Rule	sol89	1989	only	-	Aug	5	12:06:00s -0:06:00 -
Rule	sol89	1989	only	-	Aug	6	12:05:50s -0:05:50 -
Rule	sol89	1989	only	-	Aug	7	12:05:45s -0:05:45 -
Rule	sol89	1989	only	-	Aug	8	12:05:35s -0:05:35 -
Rule	sol89	1989	only	-	Aug	9	12:05:30s -0:05:30 -
Rule	sol89	1989	only	-	Aug	10	12:05:20s -0:05:20 -
Rule	sol89	1989	only	-	Aug	11	12:05:10s -0:05:10 -
Rule	sol89	1989	only	-	Aug	12	12:05:00s -0:05:00 -
Rule	sol89	1989	only	-	Aug	13	12:04:50s -0:04:50 -
Rule	sol89	1989	only	-	Aug	14	12:04:40s -0:04:40 -
Rule	sol89	1989	only	-	Aug	15	12:04:30s -0:04:30 -
Rule	sol89	1989	only	-	Aug	16	12:04:15s -0:04:15 -
Rule	sol89	1989	only	-	Aug	17	12:04:05s -0:04:05 -
Rule	sol89	1989	only	-	Aug	18	12:03:50s -0:03:50 -
Rule	sol89	1989	only	-	Aug	19	12:03:35s -0:03:35 -
Rule	sol89	1989	only	-	Aug	20	12:03:25s -0:03:25 -
Rule	sol89	1989	only	-	Aug	21	12:03:10s -0:03:10 -
Rule	sol89	1989	only	-	Aug	22	12:02:55s -0:02:55 -
Rule	sol89	1989	only	-	Aug	23	12:02:40s -0:02:40 -
Rule	sol89	1989	only	-	Aug	24	12:02:20s -0:02:20 -
Rule	sol89	1989	only	-	Aug	25	12:02:05s -0:02:05 -
Rule	sol89	1989	only	-	Aug	26	12:01:50s -0:01:50 -
Rule	sol89	1989	only	-	Aug	27	12:01:30s -0:01:30 -
Rule	sol89	1989	only	-	Aug	28	12:01:15s -0:01:15 -
Rule	sol89	1989	only	-	Aug	29	12:00:55s -0:00:55 -
Rule	sol89	1989	only	-	Aug	30	12:00:40s -0:00:40 -
Rule	sol89	1989	only	-	Aug	31	12:00:20s -0:00:20 -
Rule	sol89	1989	only	-	Sep	1	12:00:00s 0:00:00 -
Rule	sol89	1989	only	-	Sep	2	11:59:45s 0:00:15 -
Rule	sol89	1989	only	-	Sep	3	11:59:25s 0:00:35 -
Rule	sol89	1989	only	-	Sep	4	11:59:05s 0:00:55 -
Rule	sol89	1989	only	-	Sep	5	11:58:45s 0:01:15 -
Rule	sol89	1989	only	-	Sep	6	11:58:25s 0:01:35 -
Rule	sol89	1989	only	-	Sep	7	11:58:05s 0:01:55 -
Rule	sol89	1989	only	-	Sep	8	11:57:45s 0:02:15 -
Rule	sol89	1989	only	-	Sep	9	11:57:20s 0:02:40 -
Rule	sol89	1989	only	-	Sep	10	11:57:00s 0:03:00 -
Rule	sol89	1989	only	-	Sep	11	11:56:40s 0:03:20 -
Rule	sol89	1989	only	-	Sep	12	11:56:20s 0:03:40 -
Rule	sol89	1989	only	-	Sep	13	11:56:00s 0:04:00 -
Rule	sol89	1989	only	-	Sep	14	11:55:35s 0:04:25 -
Rule	sol89	1989	only	-	Sep	15	11:55:15s 0:04:45 -
Rule	sol89	1989	only	-	Sep	16	11:54:55s 0:05:05 -
Rule	sol89	1989	only	-	Sep	17	11:54:35s 0:05:25 -
Rule	sol89	1989	only	-	Sep	18	11:54:10s 0:05:50 -
Rule	sol89	1989	only	-	Sep	19	11:53:50s 0:06:10 -
Rule	sol89	1989	only	-	Sep	20	11:53:30s 0:06:30 -
Rule	sol89	1989	only	-	Sep	21	11:53:10s 0:06:50 -
Rule	sol89	1989	only	-	Sep	22	11:52:45s 0:07:15 -
Rule	sol89	1989	only	-	Sep	23	11:52:25s 0:07:35 -
Rule	sol89	1989	only	-	Sep	24	11:52:05s 0:07:55 -
Rule	sol89	1989	only	-	Sep	25	11:51:45s 0:08:15 -
Rule	sol89	1989	only	-	Sep	26	11:51:25s 0:08:35 -
Rule	sol89	1989	only	-	Sep	27	11:51:05s 0:08:55 -
Rule	sol89	1989	only	-	Sep	28	11:50:40s 0:09:20 -
Rule	sol89	1989	only	-	Sep	29	11:50:20s 0:09:40 -
Rule	sol89	1989	only	-	Sep	30	11:50:00s 0:10:00 -
Rule	sol89	1989	only	-	Oct	1	11:49:45s 0:10:15 -
Rule	sol89	1989	only	-	Oct	2	11:49:25s 0:10:35 -
Rule	sol89	1989	only	-	Oct	3	11:49:05s 0:10:55 -
Rule	sol89	1989	only	-	Oct	4	11:48:45s 0:11:15 -
Rule	sol89	1989	only	-	Oct	5	11:48:30s 0:11:30 -
Rule	sol89	1989	only	-	Oct	6	11:48:10s 0:11:50 -
Rule	sol89	1989	only	-	Oct	7	11:47:50s 0:12:10 -
Rule	sol89	1989	only	-	Oct	8	11:47:35s 0:12:25 -
Rule	sol89	1989	only	-	Oct	9	11:47:20s 0:12:40 -
Rule	sol89	1989	only	-	Oct	10	11:47:00s 0:13:00 -
Rule	sol89	1989	only	-	Oct	11	11:46:45s 0:13:15 -
Rule	sol89	1989	only	-	Oct	12	11:46:30s 0:13:30 -
Rule	sol89	1989	only	-	Oct	13	11:46:15s 0:13:45 -
Rule	sol89	1989	only	-	Oct	14	11:46:00s 0:14:00 -
Rule	sol89	1989	only	-	Oct	15	11:45:50s 0:14:10 -
Rule	sol89	1989	only	-	Oct	16	11:45:35s 0:14:25 -
Rule	sol89	1989	only	-	Oct	17	11:45:20s 0:14:40 -
Rule	sol89	1989	only	-	Oct	18	11:45:10s 0:14:50 -
Rule	sol89	1989	only	-	Oct	19	11:45:00s 0:15:00 -
Rule	sol89	1989	only	-	Oct	20	11:44:50s 0:15:10 -
Rule	sol89	1989	only	-	Oct	21	11:44:40s 0:15:20 -
Rule	sol89	1989	only	-	Oct	22	11:44:30s 0:15:30 -
Rule	sol89	1989	only	-	Oct	23	11:44:20s 0:15:40 -
Rule	sol89	1989	only	-	Oct	24	11:44:10s 0:15:50 -
Rule	sol89	1989	only	-	Oct	25	11:44:05s 0:15:55 -
Rule	sol89	1989	only	-	Oct	26	11:44:00s 0:16:00 -
Rule	sol89	1989	only	-	Oct	27	11:43:50s 0:16:10 -
Rule	sol89	1989	only	-	Oct	28	11:43:45s 0:16:15 -
Rule	sol89	1989	only	-	Oct	29	11:43:40s 0:16:20 -
Rule	sol89	1989	only	-	Oct	30	11:43:40s 0:16:20 -
Rule	sol89	1989	only	-	Oct	31	11:43:35s 0:16:25 -
Rule	sol89	1989	only	-	Nov	1	11:43:35s 0:16:25 -
Rule	sol89	1989	only	-	Nov	2	11:43:35s 0:16:25 -
Rule	sol89	1989	only	-	Nov	3	11:43:30s 0:16:30 -
Rule	sol89	1989	only	-	Nov	4	11:43:35s 0:16:25 -
Rule	sol89	1989	only	-	Nov	5	11:43:35s 0:16:25 -
Rule	sol89	1989	only	-	Nov	6	11:43:35s 0:16:25 -
Rule	sol89	1989	only	-	Nov	7	11:43:40s 0:16:20 -
Rule	sol89	1989	only	-	Nov	8	11:43:45s 0:16:15 -
Rule	sol89	1989	only	-	Nov	9	11:43:50s 0:16:10 -
Rule	sol89	1989	only	-	Nov	10	11:43:55s 0:16:05 -
Rule	sol89	1989	only	-	Nov	11	11:44:00s 0:16:00 -
Rule	sol89	1989	only	-	Nov	12	11:44:05s 0:15:55 -
Rule	sol89	1989	only	-	Nov	13	11:44:15s 0:15:45 -
Rule	sol89	1989	only	-	Nov	14	11:44:25s 0:15:35 -
Rule	sol89	1989	only	-	Nov	15	11:44:35s 0:15:25 -
Rule	sol89	1989	only	-	Nov	16	11:44:45s 0:15:15 -
Rule	sol89	1989	only	-	Nov	17	11:44:55s 0:15:05 -
Rule	sol89	1989	only	-	Nov	18	11:45:10s 0:14:50 -
Rule	sol89	1989	only	-	Nov	19	11:45:20s 0:14:40 -
Rule	sol89	1989	only	-	Nov	20	11:45:35s 0:14:25 -
Rule	sol89	1989	only	-	Nov	21	11:45:50s 0:14:10 -
Rule	sol89	1989	only	-	Nov	22	11:46:05s 0:13:55 -
Rule	sol89	1989	only	-	Nov	23	11:46:25s 0:13:35 -
Rule	sol89	1989	only	-	Nov	24	11:46:40s 0:13:20 -
Rule	sol89	1989	only	-	Nov	25	11:47:00s 0:13:00 -
Rule	sol89	1989	only	-	Nov	26	11:47:20s 0:12:40 -
Rule	sol89	1989	only	-	Nov	27	11:47:35s 0:12:25 -
Rule	sol89	1989	only	-	Nov	28	11:47:55s 0:12:05 -
Rule	sol89	1989	only	-	Nov	29	11:48:20s 0:11:40 -
Rule	sol89	1989	only	-	Nov	30	11:48:40s 0:11:20 -
Rule	sol89	1989	only	-	Dec	1	11:49:00s 0:11:00 -
Rule	sol89	1989	only	-	Dec	2	11:49:25s 0:10:35 -
Rule	sol89	1989	only	-	Dec	3	11:49:50s 0:10:10 -
Rule	sol89	1989	only	-	Dec	4	11:50:15s 0:09:45 -
Rule	sol89	1989	only	-	Dec	5	11:50:35s 0:09:25 -
Rule	sol89	1989	only	-	Dec	6	11:51:00s 0:09:00 -
Rule	sol89	1989	only	-	Dec	7	11:51:30s 0:08:30 -
Rule	sol89	1989	only	-	Dec	8	11:51:55s 0:08:05 -
Rule	sol89	1989	only	-	Dec	9	11:52:20s 0:07:40 -
Rule	sol89	1989	only	-	Dec	10	11:52:50s 0:07:10 -
Rule	sol89	1989	only	-	Dec	11	11:53:15s 0:06:45 -
Rule	sol89	1989	only	-	Dec	12	11:53:45s 0:06:15 -
Rule	sol89	1989	only	-	Dec	13	11:54:10s 0:05:50 -
Rule	sol89	1989	only	-	Dec	14	11:54:40s 0:05:20 -
Rule	sol89	1989	only	-	Dec	15	11:55:10s 0:04:50 -
Rule	sol89	1989	only	-	Dec	16	11:55:40s 0:04:20 -
Rule	sol89	1989	only	-	Dec	17	11:56:05s 0:03:55 -
Rule	sol89	1989	only	-	Dec	18	11:56:35s 0:03:25 -
Rule	sol89	1989	only	-	Dec	19	11:57:05s 0:02:55 -
Rule	sol89	1989	only	-	Dec	20	11:57:35s 0:02:25 -
Rule	sol89	1989	only	-	Dec	21	11:58:05s 0:01:55 -
Rule	sol89	1989	only	-	Dec	22	11:58:35s 0:01:25 -
Rule	sol89	1989	only	-	Dec	23	11:59:05s 0:00:55 -
Rule	sol89	1989	only	-	Dec	24	11:59:35s 0:00:25 -
Rule	sol89	1989	only	-	Dec	25	12:00:05s -0:00:05 -
Rule	sol89	1989	only	-	Dec	26	12:00:35s -0:00:35 -
Rule	sol89	1989	only	-	Dec	27	12:01:05s -0:01:05 -
Rule	sol89	1989	only	-	Dec	28	12:01:35s -0:01:35 -
Rule	sol89	1989	only	-	Dec	29	12:02:00s -0:02:00 -
Rule	sol89	1989	only	-	Dec	30	12:02:30s -0:02:30 -
Rule	sol89	1989	only	-	Dec	31	12:03:00s -0:03:00 -
Rule	Arg	1930	only	-	Dec	 1	0:00	1:00	S
Rule	Arg	1931	only	-	Apr	 1	0:00	0	-
Rule	Arg	1931	only	-	Oct	15	0:00	1:00	S
Rule	Arg	1932	1940	-	Mar	 1	0:00	0	-
Rule	Arg	1932	1939	-	Nov	 1	0:00	1:00	S
Rule	Arg	1940	only	-	Jul	 1	0:00	1:00	S
Rule	Arg	1941	only	-	Jun	15	0:00	0	-
Rule	Arg	1941	only	-	Oct	15	0:00	1:00	S
Rule	Arg	1943	only	-	Aug	 1	0:00	0	-
Rule	Arg	1943	only	-	Oct	15	0:00	1:00	S
Rule	Arg	1946	only	-	Mar	 1	0:00	0	-
Rule	Arg	1946	only	-	Oct	 1	0:00	1:00	S
Rule	Arg	1963	only	-	Oct	 1	0:00	0	-
Rule	Arg	1963	only	-	Dec	15	0:00	1:00	S
Rule	Arg	1964	1966	-	Mar	 1	0:00	0	-
Rule	Arg	1964	1966	-	Oct	15	0:00	1:00	S
Rule	Arg	1967	only	-	Apr	 1	0:00	0	-
Rule	Arg	1967	1968	-	Oct	Sun>=1	0:00	1:00	S
Rule	Arg	1968	1969	-	Apr	Sun>=1	0:00	0	-
Rule	Arg	1974	only	-	Jan	23	0:00	1:00	S
Rule	Arg	1974	only	-	May	 1	0:00	0	-
Rule	Arg	1974	1976	-	Oct	Sun>=1	0:00	1:00	S
Rule	Arg	1975	1977	-	Apr	Sun>=1	0:00	0	-
Rule	Arg	1985	only	-	Nov	 2	0:00	1:00	S
Rule	Arg	1986	only	-	Mar	14	0:00	0	-
Rule	Arg	1986	1987	-	Oct	25	0:00	1:00	S
Rule	Arg	1987	only	-	Feb	13	0:00	0	-
Rule	Arg	1988	only	-	Feb	 7	0:00	0	-
Rule	Arg	1988	only	-	Dec	 1	0:00	1:00	S
Rule	Arg	1989	1993	-	Mar	Sun>=1	0:00	0	-
Rule	Arg	1989	1992	-	Oct	Sun>=15	0:00	1:00	S
Rule	Arg	1999	only	-	Oct	Sun>=1	0:00	1:00	S
Rule	Arg	2000	only	-	Mar	Sun>=1	0:00	0	-
Rule	Brazil	1931	only	-	Oct	 3	11:00	1:00	S
Rule	Brazil	1932	1933	-	Apr	 1	 0:00	0	-
Rule	Brazil	1932	only	-	Oct	 3	 0:00	1:00	S
Rule	Brazil	1949	1952	-	Dec	 1	 0:00	1:00	S
Rule	Brazil	1950	only	-	Apr	16	 1:00	0	-
Rule	Brazil	1951	1952	-	Apr	 1	 0:00	0	-
Rule	Brazil	1953	only	-	Mar	 1	 0:00	0	-
Rule	Brazil	1963	only	-	Dec	 9	 0:00	1:00	S
Rule	Brazil	1964	only	-	Mar	 1	 0:00	0	-
Rule	Brazil	1965	only	-	Jan	31	 0:00	1:00	S
Rule	Brazil	1965	only	-	Mar	31	 0:00	0	-
Rule	Brazil	1965	only	-	Dec	 1	 0:00	1:00	S
Rule	Brazil	1966	1968	-	Mar	 1	 0:00	0	-
Rule	Brazil	1966	1967	-	Nov	 1	 0:00	1:00	S
Rule	Brazil	1985	only	-	Nov	 2	 0:00	1:00	S
Rule	Brazil	1986	only	-	Mar	15	 0:00	0	-
Rule	Brazil	1986	only	-	Oct	25	 0:00	1:00	S
Rule	Brazil	1987	only	-	Feb	14	 0:00	0	-
Rule	Brazil	1987	only	-	Oct	25	 0:00	1:00	S
Rule	Brazil	1988	only	-	Feb	 7	 0:00	0	-
Rule	Brazil	1988	only	-	Oct	16	 0:00	1:00	S
Rule	Brazil	1989	only	-	Jan	29	 0:00	0	-
Rule	Brazil	1989	only	-	Oct	15	 0:00	1:00	S
Rule	Brazil	1990	only	-	Feb	11	 0:00	0	-
Rule	Brazil	1990	only	-	Oct	21	 0:00	1:00	S
Rule	Brazil	1991	only	-	Feb	17	 0:00	0	-
Rule	Brazil	1991	only	-	Oct	20	 0:00	1:00	S
Rule	Brazil	1992	only	-	Feb	 9	 0:00	0	-
Rule	Brazil	1992	only	-	Oct	25	 0:00	1:00	S
Rule	Brazil	1993	only	-	Jan	31	 0:00	0	-
Rule	Brazil	1993	1995	-	Oct	Sun>=11	 0:00	1:00	S
Rule	Brazil	1994	1995	-	Feb	Sun>=15	 0:00	0	-
Rule	Brazil	1996	only	-	Feb	11	 0:00	0	-
Rule	Brazil	1996	only	-	Oct	 6	 0:00	1:00	S
Rule	Brazil	1997	only	-	Feb	16	 0:00	0	-
Rule	Brazil	1997	only	-	Oct	 6	 0:00	1:00	S
Rule	Brazil	1998	only	-	Mar	 1	 0:00	0	-
Rule	Brazil	1998	only	-	Oct	11	 0:00	1:00	S
Rule	Brazil	1999	only	-	Feb	21	 0:00	0	-
Rule	Brazil	1999	only	-	Oct	 3	 0:00	1:00	S
Rule	Brazil	2000	only	-	Feb	27	 0:00	0	-
Rule	Brazil	2000	max	-	Oct	Sun>=8	 0:00	1:00	S
Rule	Brazil	2001	max	-	Feb	Sun>=15	 0:00	0	-
Rule	Chile	1918	only	-	Sep	 1	0:00	1:00	S
Rule	Chile	1919	only	-	Jul	 2	0:00	0	-
Rule	Chile	1927	1931	-	Sep	 1	0:00	1:00	S
Rule	Chile	1928	1932	-	Apr	 1	0:00	0	-
Rule	Chile	1969	1997	-	Oct	Sun>=9	0:00	1:00	S
Rule	Chile	1970	1998	-	Mar	Sun>=9	0:00	0	-
Rule	Chile	1998	only	-	Sep	27	0:00	1:00	S
Rule	Chile	1999	only	-	Apr	 4	0:00	0	-
Rule	Chile	1999	max	-	Oct	Sun>=9	0:00	1:00	S
Rule	Chile	2000	max	-	Mar	Sun>=9	0:00	0	-
Rule	CO	1992	only	-	May	 2	0:00	1:00	S
Rule	CO	1992	only	-	Dec	31	0:00	0	-
Rule	Falk	1937	1938	-	Sep	lastSun	0:00	1:00	S
Rule	Falk	1938	1942	-	Mar	Sun>=19	0:00	0	-
Rule	Falk	1939	only	-	Oct	1	0:00	1:00	S
Rule	Falk	1940	1942	-	Sep	lastSun	0:00	1:00	S
Rule	Falk	1943	only	-	Jan	1	0:00	0	-
Rule	Falk	1983	only	-	Sep	lastSun	0:00	1:00	S
Rule	Falk	1984	1985	-	Apr	lastSun	0:00	0	-
Rule	Falk	1984	only	-	Sep	16	0:00	1:00	S
Rule	Falk	1985	1995	-	Sep	Sun>=9	0:00	1:00	S
Rule	Falk	1986	max	-	Apr	Sun>=16	0:00	0	-
Rule	Falk	1996	max	-	Sep	Sun>=8	0:00	1:00	S
Rule	Para	1975	1988	-	Oct	 1	0:00	1:00	S
Rule	Para	1975	1978	-	Mar	 1	0:00	0	-
Rule	Para	1979	1991	-	Apr	 1	0:00	0	-
Rule	Para	1989	only	-	Oct	22	0:00	1:00	S
Rule	Para	1990	only	-	Oct	 1	0:00	1:00	S
Rule	Para	1991	only	-	Oct	 6	0:00	1:00	S
Rule	Para	1992	only	-	Mar	 1	0:00	0	-
Rule	Para	1992	only	-	Oct	 5	0:00	1:00	S
Rule	Para	1993	only	-	Mar	31	0:00	0	-
Rule	Para	1993	1995	-	Oct	 1	0:00	1:00	S
Rule	Para	1994	1995	-	Feb	lastSun	0:00	0	-
Rule	Para	1996	only	-	Mar	 1	0:00	0	-
Rule	Para	1997	only	-	Feb	lastSun	0:00	0	-
Rule	Para	1998	only	-	Mar	 1	0:00	0	-
Rule	Para	1996	1998	-	Oct	Sun>=1	0:00	1:00	S
Rule	Para	1999	max	-	Feb	lastSun	0:00	0	-
Rule	Para	1999	only	-	Oct	10	0:00	1:00	S
Rule	Para	2000	max	-	Oct	Sun>=1	0:00	1:00	S
Rule	Peru	1938	only	-	Jan	 1	0:00	1:00	S
Rule	Peru	1938	only	-	Apr	 1	0:00	0	-
Rule	Peru	1938	1939	-	Sep	lastSun	0:00	1:00	S
Rule	Peru	1939	1940	-	Mar	Sun>=24	0:00	0	-
Rule	Peru	1987	only	-	Jan	 1	0:00	1:00	S
Rule	Peru	1987	only	-	Apr	 1	0:00	0	-
Rule	Peru	1990	only	-	Jan	 1	0:00	1:00	S
Rule	Peru	1990	only	-	Apr	 1	0:00	0	-
Rule	Peru	1994	only	-	Jan	 1	0:00	1:00	S
Rule	Peru	1994	only	-	Apr	 1	0:00	0	-
Rule	Uruguay	1923	only	-	Oct	 2	 0:00	0:30	HS
Rule	Uruguay	1924	1926	-	Apr	 1	 0:00	0	-
Rule	Uruguay	1924	1925	-	Oct	 1	 0:00	0:30	HS
Rule	Uruguay	1933	1935	-	Oct	lastSun	 0:00	0:30	HS
Rule	Uruguay	1934	1936	-	Mar	Sat>=25	23:30s	0	-
Rule	Uruguay	1936	only	-	Nov	 1	 0:00	0:30	HS
Rule	Uruguay	1937	1941	-	Mar	lastSun	 0:00	0	-
Rule	Uruguay	1937	1940	-	Oct	lastSun	 0:00	0:30	HS
Rule	Uruguay	1941	only	-	Aug	 1	 0:00	0	-
Rule	Uruguay	1942	only	-	Jan	 1	 0:00	0:30	HS
Rule	Uruguay	1942	only	-	Dec	14	 0:00	1:00	S
Rule	Uruguay	1943	only	-	Mar	14	 0:00	0	-
Rule	Uruguay	1959	only	-	May	24	 0:00	1:00	S
Rule	Uruguay	1959	only	-	Nov	15	 0:00	0	-
Rule	Uruguay	1960	only	-	Jan	17	 0:00	1:00	S
Rule	Uruguay	1960	only	-	Mar	 6	 0:00	0	-
Rule	Uruguay	1965	1967	-	Apr	Sun>=1	 0:00	1:00	S
Rule	Uruguay	1965	only	-	Sep	26	 0:00	0	-
Rule	Uruguay	1966	1967	-	Oct	31	 0:00	0	-
Rule	Uruguay	1968	1970	-	May	27	 0:00	0:30	HS
Rule	Uruguay	1968	1970	-	Dec	 2	 0:00	0	-
Rule	Uruguay	1972	only	-	Apr	24	 0:00	1:00	S
Rule	Uruguay	1972	only	-	Aug	15	 0:00	0	-
Rule	Uruguay	1974	only	-	Mar	10	 0:00	0:30	HS
Rule	Uruguay	1974	only	-	Dec	22	 0:00	1:00	S
Rule	Uruguay	1976	only	-	Oct	 1	 0:00	0	-
Rule	Uruguay	1977	only	-	Dec	 4	 0:00	1:00	S
Rule	Uruguay	1978	only	-	Apr	 1	 0:00	0	-
Rule	Uruguay	1979	only	-	Oct	 1	 0:00	1:00	S
Rule	Uruguay	1980	only	-	May	 1	 0:00	0	-
Rule	Uruguay	1987	only	-	Dec	14	 0:00	1:00	S
Rule	Uruguay	1988	only	-	Mar	14	 0:00	0	-
Rule	Uruguay	1988	only	-	Dec	11	 0:00	1:00	S
Rule	Uruguay	1989	only	-	Mar	12	 0:00	0	-
Rule	Uruguay	1989	only	-	Oct	29	 0:00	1:00	S
Rule	Uruguay	1990	1992	-	Mar	Sun>=1	 0:00	0	-
Rule	Uruguay	1990	1991	-	Oct	Sun>=21	 0:00	1:00	S
Rule	Uruguay	1992	only	-	Oct	18	 0:00	1:00	S
Rule	Uruguay	1993	only	-	Feb	28	 0:00	0	-
Rule	SystemV	min	1973	-	Apr	lastSun	2:00	1:00	D
Rule	SystemV	min	1973	-	Oct	lastSun	2:00	0	S
Rule	SystemV	1974	only	-	Jan	6	2:00	1:00	D
Rule	SystemV	1974	only	-	Nov	lastSun	2:00	0	S
Rule	SystemV	1975	only	-	Feb	23	2:00	1:00	D
Rule	SystemV	1975	only	-	Oct	lastSun	2:00	0	S
Rule	SystemV	1976	max	-	Apr	lastSun	2:00	1:00	D
Rule	SystemV	1976	max	-	Oct	lastSun	2:00	0	S
