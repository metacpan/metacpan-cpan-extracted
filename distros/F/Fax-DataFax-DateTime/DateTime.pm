package Fax::DataFax::DateTime;

use strict;
use Carp;
use warnings;
# use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

our @ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
our @EXPORT = qw(

);
our @EXPORT_OK = qw( check_user_time fmtTime cvtTime get_date_format
  cvtYY2Y4 _YY2Y4 getLastDateInMonth 
);
our %EXPORT_TAGS = ( 
    common   => [qw(fmtTime cvtTime cvtYY2Y4 _YY2Y4
                getLastDateInMonth get_date_format
                 )],
    qc_time  => [qw(check_user_time)],
    chk_time => [qw(check_user_time)],
    cvt_time => [qw(cvtTime cvtYY2Y4 _YY2Y4)],
);

my %MON=('JAN'=>1,'FEB'=>2,'MAR'=>3,'APR'=>4,'MAY'=>5,'JUN'=>6,
         'JUL'=>7,'AUG'=>8,'SEP'=>9,'OCT'=>10,'NOV'=>11,'DEC'=>12);
my @Z = split(' ', '31 28 31 30 31 30 31 31 30 31 30 31', 9999);

our $VERSION = '0.01';

use Time::Local;

# bootstrap Fax::DataFax::DateTime $VERSION;


=head1 NAME

Fax::DataFax::DateTime - Perl extension for miscellanous methods. 

=head1 SYNOPSIS

  use Fax::DataFax::DateTime;

No automatically exported routines. You have to specifically to import
the methods into your package.

  use Fax::DataFax::DateTime qw(:qc_time fmtTime);
  use Fax::DataFax::DateTime /:qc_time/;
  use Fax::DataFax::DateTime ':qc_time';

Notation and Conventions

   $drh    Driver handle object (rarely seen or used in applications)
   $h      Any of the $??h handle types above
   $rc     General Return Code  (boolean: true=ok, false=error)
   $rv     General Return Value (typically an integer)
   @ary    List of values returned from the database, typically a row 
           of data
   $rows   Number of rows processed (if available, else -1)
   $fh     A filehandle
   undef   NULL values are represented by undefined values in perl
   \%attr  Reference to a hash of attribute values passed to methods

=head1 DESCRIPTION

This is a package containing common methods for processing date and
time. 

Exported routines:

  fmtTime    - format times 
  cvtTime    - convert time from one format to another
  cvtYY2Y4   - convert year from two-digits to four digits
  check_user_time - check DataFax user and time

Exported TAGS:

  common    => [fmtTime cvtTime cvtYY2Y4],
  qc_time   => [check_user_time],
  chk_time  => [check_user_time],
  cvt_time  => [cvtTime cvtYY2Y4],

=cut

# -------------------------------------------------------------------

=head2 Export Tag: common  

The I<:common> tag includes methods for dealing with date and time.

  use Fax::DataFax::DateTime qw(:common);

It includes the following methods:

=over 4

=item *  getLastDateInMonth($dt, $gap, $typ)

Input variables:

  $dt  - date in the format of YYYYMMDD.hhmmss
  $gap - number of months
  $typ - input type: default - YYYYMM or YYYYMMDD
                     1 - YYMMDD or YYMM
                     5 - YYYY/MM/DD hh:mm:ss

Variables used or routines called: 

  cvtYY2Y4 - convert two-digits to four digits year.

How to use:

  my $dom = $self->getLastDateInMonth('19990125',2); 

Return: the last day in a month in the format of YYYYMMLD. 

=back

=cut

sub getLastDateInMonth {
    my $self = shift;
    my($dt, $gap, $typ) = @_;
    my($Y,$M,@a,$dd);
    # Input variables:
    #   dt  - date in the format of YYYYMMDD.hhmmss
    #   gap - number of months
    #   typ - input type: default - YYYYMM or YYYYMMDD
    # Local variables:
    #   $Y  - year in YYYY
    #   $M  - month in MM
    #   @a  - temp array
    #   @z  - number of days in each month
    # Return: YYYYMMDD
    # Purpose: get the last day in a month in the format of YYYYMMLD.
    #
    if (! $gap) { $gap = 0 }
    if (! $typ) { $typ = 0 }
    if ($typ == 1) {           # $dt in YYMMDD or YYMM
        $Y = $self->cvtYY2Y4(substr($dt, 0, 2)) + 0;
        $M = substr($dt, 2, 2) + $gap;
    } elsif ($typ == 5) {      # dt in YYYY/MM/DD hh:mm:ss
        # dt in YYYY/MM/DD hh:mm:ss
        @a = split('/',$dt,100);
        if (length($a[0])==2) { $a[0] = $self->cvtYY2Y4($a[0]) }
        $Y = $a[0] + 0;
        $M = $a[1] + $gap;
    } else {                   # dt in YYYYMM,YYYYMMDD,YYYYMMDD.hhmmss
        $Y = substr($dt, 0, 4) + 0;
        $M = substr($dt, 4, 2) + $gap;
    }
    if ($M > 12) {
        $Y = $Y + int($M / 12);
        $M = $M % 12;
        if ($M == 0) { --$Y; $M = 12; }
    }
    if ($Y % 4 == 0 && $M == 2) {
        $dd = $Z[$M-1] + 1;    # leap year and Feb is 29 days
    } else {
        $dd = $Z[$M-1];
    }
    sprintf('%04d%02d%02d', $Y, $M, $dd);
}

=over 4

=item *  get_date_format($r1, $r2, $r3, $ds)

Input variables:

  $r1 - date range 1: 'min:max'
  $r2 - date range 2: 'min:max'
  $r3 - date range 3: 'min:max'
  $ds - date separator

Variables used or routines called: 

  None. 

How to use:

  # the $dft = 'MM/DD/YY' 
  my $dft = $self->get_date_format('1:12','1:31','1:2'); 
  # the $dft = 'MM/DD/YYYY' 
     $dft = $self->get_date_format('1:12','1:31','0:2002'); 

Return: the date format.

=back

=cut

sub get_date_format {
    my $self = shift;
    my ($r1, $r2, $r3, $ds) = @_;
    # Input variables:
    #   $r1 - date range 1: 'min:max'
    #   $r2 - date range 2: 'min:max'
    #   $r3 - date range 3: 'min:max'
    #   $ds - date separator
    #
    my ($mn1, $mx1) = split /:/, $r1;
    my ($mn2, $mx2) = split /:/, $r2;
    my ($mn3, $mx3) = split /:/, $r3;
    $ds = '/' if !$ds;
    my ($msg, $dft, $d1, $d2, $d3) = ("", "", "", "", "");
    if (($mn1>31 && $mx1<=99) || ($mn1>99 && $mx1<10000)) {  
        # 1st fd is YY or YYYY
        if ($mn1>31 && $mx1<=99) {      # 1st fd is YY
            $d1 = 'YY'; 
        } else { $d1 = 'YYYY'; }        # 1st fd is YYYY
        if ($mn2>=1 && $mx2<=12) {      # 2nd fd is MM
            $d2 = 'MM'; 
        } elsif ($mn2>=1 && $mx2<=31) { # 2nd fd is DD
            $d2 = 'DD';
        } 
        if ($d1 eq 'MM' && $mn3>=1 && $mx3<=12) {  # 3rd fd is DD
            $d3 = 'DD';
        } elsif ($mn3>=1 && $mx3<=12) { # 3rd fd is MM
            $d3 = 'MM'; 
        } elsif ($mn3>=1 && $mx3<=31) {  # 3rd fd is DD 
            $d3 = 'DD';
        }
    } elsif ($mn1>=1 && $mx1<=12) {     # 1st fd is MM
        $d1 = 'MM'; 
        if ($mx2>31 && $mx2<=99) {          # 2nd fd is YY
            $d2 = 'YY';
        } elsif ($mx2>99 && $mx2<10000) {   # 2nd fd is YYYY
            $d2 = 'YY';
        } elsif ($mn2>=1 && $mx2<=31) {     # 2nd fd is DD
            $d2 = 'DD';
        } 
        if ($d2 eq 'DD' && $mx3<=99) {      # 3nd fd is YY
            $d3 = 'YY';
        } elsif ($mn3>31 && $mx3<=99) {     # 3nd fd is YY
            $d3 = 'YY';
        } elsif ($mn3>99 && $mx3<10000) {   # 3nd fd is YYYY
            $d3 = 'YYYY';
        } elsif ($mn3>=1 && $mx3<=31) {     # 3nd fd is DD
            $d3 = 'DD';
        } 
    } elsif ($mn1>=1 && $mx1<=31) {     # 1st fd is DD
        $d1 = 'DD'; 
        if ($mx2>31 && $mx2<=99) {          # 2nd fd is YY
            $d2 = 'YY';
        } elsif ($mx2>99 && $mx2<10000) {   # 2nd fd is YYYY
            $d2 = 'YY';
        } elsif ($mn2>=1 && $mx2<=12) {     # 2nd fd is MM
            $d2 = 'MM';
        } 
        if ($d2 eq 'MM' && $mx3<=99) {      # 3nd fd is YY
            $d3 = 'YY';
        } elsif ($mx3>31 && $mx3<=99) {     # 3nd fd is YY
            $d3 = 'YY';
        } elsif ($mx3>99 && $mx3<10000) {   # 3nd fd is YYYY
            $d3 = 'YYYY';
        } elsif ($mn3>=1 && $mx3<=12) {     # 3nd fd is MM
            $d3 = 'MM';
        } 
    } else {                                # 1st fd is YY (32~99)?
        $d1 = 'YY'; 
        if ($mn2>=1 && $mx2<=12) {      # 2nd fd is MM
            $d2 = 'MM'; 
        } elsif ($mn2>=1 && $mx2<=31) { # 2nd fd is DD
            $d2 = 'DD';
        } 
        if ($d1 eq 'MM' && $mn3>=1 && $mx3<=12) {  # 3rd fd is DD
            $d3 = 'DD';
        } elsif ($mn3>=1 && $mx3<=12) { # 3rd fd is MM
            $d3 = 'MM'; 
        } elsif ($mn3>=1 && $mx3<=31) {  # 3rd fd is DD 
            $d3 = 'DD';
        }
    } 
    if ($d1 && $d2 && $d3 && ($d1 ne $d2) && ($d2 ne $d3)) {
        $dft = join $ds, $d1, $d2, $d3;
    } else {
        $msg = "illegal date: $d1($r1), $d2($r2), $d3($r3)";
    }
    return ($dft) ? $dft : $msg;
}

# -------------------------------------------------------------------

=head2 Export Tag: qc_time  

The I<:qc_time> tag includes methods for dealing with date and time 
in processing journal and QC files.

  use Fax::DataFax::DateTime qw(:qc_time);

It includes the following methods:

=over 4

=item *  check_user_time($str, $typ)

Input variables:

  $str - string in the format of 'dfuser YY/MM/DD hh:mm:ss'
  $typ - time format. default: YY/MM/DD hh:mm:ss
         1 - time is in: YYMMDD.hhmmss
         2 - time is in: YYYYMMDD.hhmmss

Variables used or routines called: None.

How to use:

  my ($usr, $tm) = 
    $self->check_user_time('dfuser 99/01/25 14:25:35'); 

Return: user and time in YYYYMMDD.hhmmss format

=back

=cut

sub check_user_time {
    my ($self, $str, $typ) = @_;
    # Input variables:
    #   str  -  string: dfuser YY/MM/DD hh:mm:ss
    #   typ  - date and time format
    # Return: user and time in the format of YYYYMMDD.hhmmss
    #
    return if !$str;
    return if ($str =~ /^\s*$/); 
    $typ = 0 if !$typ;
    my $cy = 31; 
    my ($usr,$yr,$mm,$dd,$hh,$mi,$ss) =  ("",0,0,0,0,0,0);
    my $r0 = '([\w|\?]+) (\d\d)/(\d\d)/(\d\d) (\d\d):(\d\d):(\d\d)';
    my $r1 = '([\w|\?]+) (\d\d)(\d\d)(\d\d).(\d\d)(\d\d)(\d\d)';
    my $r2 = '([\w|\?]+) (\d{4})(\d\d)(\d\d).(\d\d)(\d\d)(\d\d)';
    if ($typ == 1) {      # user YYMMDD.hhmmss
       ($usr,$yr,$mm,$dd,$hh,$mi,$ss) = ($str=~ m{$r1});
    }elsif ($typ == 2) {      # user YYYYMMDD.hhmmss
       ($usr,$yr,$mm,$dd,$hh,$mi,$ss) = ($str=~ m{$r2});
    } else {              # user YY/MM/DD hh:mm:ss
       ($usr,$yr,$mm,$dd,$hh,$mi,$ss) = ($str=~ m{$r0});
    }
    if (!defined($yr)) { $yr = ""; }
    if (!defined($mm)) { $mm = ""; }
    if (!defined($dd)) { $dd = ""; }
    return if (!"$yr$mm$dd"); 
    if ($yr>$cy && $yr<100) { $yr +=1900; 
    } elsif ($yr<=$cy)      { $yr +=2000; }
    my $tm = sprintf "%04d%02d%02d.%02d%02d%02d", $yr, $mm, $dd, $hh, 
            $mi, $ss; 
    return ($usr, $tm);
}

=over 4

=item *  fmtTime($ptm, $otp)

Input variables:

  $ptm - Perl time 
  $otp - output type: default - YYYYMMDD.hhmmss 
                       1 - YYYY/MM/DD hh:mm:ss
                       5 - MM/DD/YYYY hh:mm:ss
                      11 - Wed Mar 31 08:59:27 1999

Variables used or routines called: None

How to use:

  # return current time in YYYYMMDD.hhmmss
  my $t1 = $self->fmtTime;  
  # return current time in YYYY/MM/DD hh:mm:ss
  my $t2 = $self->fmtTime(time,1);  

Return: date and time in the format specified. 

=back

=cut

sub fmtTime {
    my $self = shift;
    my ($ptm,$otp) = @_;
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst,$r);
    #
    # Input variables:
    #   $ptm - Perl time
    #   $otp - output type: default - YYYYMMDD.hhmmss
    #                       1 - YYYY/MM/DD hh:mm:ss
    #                       5 - MM/DD/YYYY hh:mm:ss
    #                       11 - Wed Mar 31 08:59:27 1999
    # Local variables:
    #   $sec  - seconds (0~59)
    #   $min  - minutes (0~59)
    #   $hour - hours (0~23)
    #   $mday - day in month (1~31)
    #   $mon  - months (0~11)
    #   $year - year in YY
    #   $wday - day in a week (0~6: S M T W T F S)
    #   $yday - day in a year (1~366)
    #   $isdst -
    # Global variables used: None
    # Global variables modified: None
    # Calls-To:
    #   &cvtYY2YYYY($year)
    # Return: a formated time.
    # Purpose: format perl time to readable time.
    # 
    if (!$ptm) { $ptm = time }
    if (!$otp) { $otp = 0 }
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
        localtime($ptm);
    $year = ($year<31) ? $year+2000 : $year+1900;
    if ($otp==1) {      # output format: YYYY/MM/DD hh:mm:ss
        $r = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $year, $mon+1,
            $mday, $hour, $min, $sec;
    } elsif ($otp==2) { # output format: YYYYMMDD_hhmmss
        $r = sprintf "%04d%02d%02d_%02d%02d%02d", $year, $mon+1,
            $mday, $hour, $min, $sec;
    } elsif ($otp==5) { # output format: MM/DD/YYYY hh:mm:ss
        $r = sprintf "%02d/%02d/%04d %02d:%02d:%02d", $mon+1,
            $mday, $year, $hour, $min, $sec;
    } elsif ($otp==11) {
        $r = scalar localtime($ptm);
    } else {            # output format: YYYYMMDD.hhmmss
        $r = sprintf "%04d%02d%02d.%02d%02d%02d", $year, $mon+1,
            $mday, $hour, $min, $sec;
    }
    return $r;
}

=over 4

=item *  cvtTime($tm, $itp, $otp)

Input variables:

  $tm  - Time in the format of $itp
  $itp - Input time type 
  $otp - Output type
    Time types: 
    default - YYYYMMDD.hhmmss 
       1 - YYYY/MM/DD hh:mm:ss
       2 - YYYYMMDD_hhmmss
       3 - YYYY.MM.DD hh:mm:ss
       5 - MM/DD/YYYY hh:mm:ss
      11 - WWW Mon DD hh:mm:ss YYYY (Wed Mar 31 08:59:27 1999)
      99 - Perl time, i.e., non-leap second since the epoch

Variables used or routines called: None

How to use:

  # return current time in YYYYMMDD.hhmmss
  my $t1 = $self->fmtTime;  
  # return current time in YYYY/MM/DD hh:mm:ss
  my $t2 = $self->fmtTime(time,1);  

Return: date and time in the format specified. 

=back

=cut

sub cvtTime {
    my $self = shift;
    my ($tm, $itp, $otp) = @_;
    # print "$tm, $itp, $otp\n";
    if (!$tm) { carp "WARN: no time specified.\n"; return; }
    $itp = 0 if !$itp;
    $otp = 0 if !$otp;
    # Local variables:
    #   $sec  - seconds (0~59)
    #   $min  - minutes (0~59)
    #   $hour - hours (0~23)
    #   $mday - day in month (1~31)
    #   $mon  - months (0~11)
    #   $mm   - months (1~12)
    #   $mmm  - Months(Jan,Feb, etc.) 
    #   $yr   - year in YY
    #   $year - year in YYYY
    #   $wday - day in a week (0~6: S M T W T F S)
    #   $yday - day in a year (1~366)
    #   $isdst -
    # 
    my %MON=('JAN'=>1,'FEB'=>2,'MAR'=>3,'APR'=>4,'MAY'=>5,'JUN'=>6,
         'JUL'=>7,'AUG'=>8,'SEP'=>9,'OCT'=>10,'NOV'=>11,'DEC'=>12);
    my ($yr, $year, $mm, $mmm, $dd, $hh, $mi, $ss, $www, $re, $r); 
    my ($mon, $wday,$yday,$isdst);
    if ($itp==1) {         # time format:  YYYY/MM/DD hh:mm:ss
        $re = qr{(\d{4,4})/(\d\d)/(\d\d) (\d\d):(\d\d):(\d\d)};   
        ($year, $mm, $dd, $hh, $mi, $ss) = ( $tm =~ $re );   
    } elsif ($itp==2) {    # time format:  YYYYMMDD_hhmmss
        $re = qr{(\d{4,4})(\d\d)(\d\d)_(\d\d)(\d\d)(\d\d)};   
        ($year, $mm, $dd, $hh, $mi, $ss) = ( $tm =~ $re );   
    } elsif ($itp==3) {    # time format:  YYYY.MM.DD hh:mm:ss
        $re = qr{(\d{4,4})\.(\d\d)\.(\d\d)\s+(\d\d):(\d\d):(\d\d)};   
        ($year, $mm, $dd, $hh, $mi, $ss) = ( $tm =~ $re );   
    } elsif ($itp==5) {    # time format:  MM/DD/YYYY hh:mm:ss
        $re = qr{(\d\d)/(\d\d)/(\d{4,4}) (\d\d):(\d\d):(\d\d)};   
        ($mm, $dd, $year, $hh, $mi, $ss) = ( $tm =~ $re );   
    } elsif ($itp==11) {   # time format:  WWW Mon DD hh:mm:ss YYYY
        $re = qr/(\w+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)/;   
        ($www, $mmm, $dd, $hh, $mi, $ss, $year) = ( $tm =~ $re );   
         $mm = $MON{uc($mmm)};
    } elsif ($itp==99) {   # time format:  non-leap seconds 
        ($ss,$mi,$hh,$dd,$mon,$yr,$wday,$yday,$isdst) =
                                 localtime($tm);
        $mm = $mon + 1;
        $year = 1900 + $yr;
    } else {               # time format:  YYYYMMDD.hhmmss
        $re = qr{(\d{4,4})(\d\d)(\d\d)\.(\d\d)(\d\d)(\d\d)};   
        ($year, $mm, $dd, $hh, $mi, $ss) = ( $tm =~ $re );   
        $hh = 0 if !$hh; $mi = 0 if !$mi; $ss = 0 if !$ss;
    }
    my $fmt = "%04d%02d%02d.%02d%02d%02d"; 
    if ($otp==1) {      # output format: YYYY/MM/DD hh:mm:ss
        $fmt = "%04d/%02d/%02d %02d:%02d:%02d"; 
        $r = sprintf $fmt, $year, $mm, $dd, $hh, $mi, $ss;
    } elsif ($otp==2) {
        $fmt = "%04d%02d%02d_%02d%02d%02d"; 
        $r = sprintf $fmt, $year, $mm, $dd, $hh, $mi, $ss;
    } elsif ($otp==3) {    # time format:  YYYY.MM.DD hh:mm:ss
        $fmt = "%04d.%02d.%02d %02d:%02d:%02d"; 
        $r = sprintf $fmt, $year, $mm, $dd, $hh, $mi, $ss;
    } elsif ($otp==5) { # output format: MM/DD/YYYY hh:mm:ss
        $fmt = "%02d/%02d/%04d %02d:%02d:%02d"; 
        $r = sprintf $fmt, $mm, $dd, $year, $hh, $mi, $ss;
    } elsif ($otp==11) {
        $r = scalar localtime(time);
    } elsif ($otp==99) {   
        $r = timelocal($ss,$mi,$hh,$dd,$mon,$year);
    } else {
        $r = sprintf $fmt, $year, $mm, $dd, $hh, $mi, $ss;
    }
    return $r;
}

=over 4

=item *  cvtYY2Y4($tm,$itp,$otp)

Input variables:

  $tm  - Time in the format of $itp
  $itp - Input time type 
  $otp - Output type
    Time types input and output types
             $itp                   $otp
  default - YY                   => YYYY
      1 - YY/MM/DD hh:mm:ss      => YYYY/MM/DD hh:mm:ss
      2 - YYMMDD_hhmmss          => YYYYMMDD_hhmmss
      5 - MM/DD/YY hh:mm:ss      => MM/DD/YYYY hh:mm:ss
     11 - WWW Mon DD hh:mm:ss YY => WWW Mon DD hh:mm:ss YYYY
         (Wed Mar 31 08:59:27 99)   (Wed Mar 31 08:59:27 1999)
     21 - YYMMDD.hhmmss          => YYMMDD.hhmmss
     22 - YYMMDD                 => YYYYMMDD
     23 - YYMM                   => YYYYMM
     24 - YY                     => YYYY

Variables used or routines called: 

    df_param - get DataFax parameters from DataFax.ini

How to use:

  # return current time in YYYYMMDD.hhmmss
  my $t1 = $self->fmtTime;  
  # return current time in YYYY/MM/DD hh:mm:ss
  my $t2 = $self->fmtTime(time,1);  

Return: date and time in the format specified. 

=back

=cut

sub cvtYY2Y4 {
    my $self = shift;
    my ($tm, $itp, $otp) = @_;
    return if not defined($tm);
    $itp = 0 if !$itp;
    $otp = 0 if !$otp;
    my $pvtyr = $self->df_param('pivotyear');
       $pvtyr = 31 if !$pvtyr;
    my ($yr, $y4, $mo, $dd, $hh, $mm, $ss); 
    # deal with default first
    if (!$itp && !$otp) { return $self->_YY2Y4($tm); }
    if ($itp && !$otp) { $otp = $itp; }

    my ($www, $mmm, $year, $re, $mi);
    if ($itp==1) {         # time format:  YY/MM/DD hh:mm:ss
        $re = qr{(\d{2,2})/(\d\d)/(\d\d) (\d\d):(\d\d):(\d\d)};   
        ($year, $mm, $dd, $hh, $mi, $ss) = ( $tm =~ $re );   
    } elsif ($itp==2) {    # time format:  YYMMDD_hhmmss
        $re = qr{(\d{2,2})(\d\d)(\d\d)_(\d\d)(\d\d)(\d\d)};   
        ($year, $mm, $dd, $hh, $mi, $ss) = ( $tm =~ $re );   
    } elsif ($itp==5) {    # time format:  MM/DD/YY hh:mm:ss
        $re = qr{(\d\d)/(\d\d)/(\d{2,2}) (\d\d):(\d\d):(\d\d)};   
        ($mm, $dd, $year, $hh, $mi, $ss) = ( $tm =~ $re );   
    } elsif ($itp==11) {   # time format:  WWW Mon DD hh:mm:ss YY
        $re = qr/(\w+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d\d)/;   
        ($www, $mmm, $dd, $hh, $mi, $ss, $year) = ( $tm =~ $re );   
         $mm = $MON{uc($mmm)};
    } elsif ($itp==21) {    # time format:  YYMMDD.hhmmss
        $re = qr{(\d{2,2})(\d\d)(\d\d)\.(\d\d)(\d\d)(\d\d)};   
        ($year, $mm, $dd, $hh, $mi, $ss) = ( $tm =~ $re );   
    } elsif ($itp==22) {    # time format:  YYMMDD
        $re = qr{(\d{2,2})(\d\d)(\d\d)};   
        ($year, $mm, $dd, $hh, $mi, $ss) = ( $tm =~ $re );   
    } elsif ($itp==23) {    # time format:  YYMM
        $re = qr{(\d{2,2})(\d\d)};   
        ($year, $mm, $dd, $hh, $mi, $ss) = ( $tm =~ $re );   
    } elsif ($itp==24) {    # time format:  YY
        $re = qr{(\d{2,2})};   
        ($year, $mm, $dd, $hh, $mi, $ss) = ( $tm =~ $re );   
    }
    $year = $self->_YY2Y4($year);
    my $fmt = "%04d%02d%02d.%02d%02d%02d"; 
    my $r = "";
    if ($otp==1) {      # output format: YYYY/MM/DD hh:mm:ss
        $fmt = "%04d/%02d/%02d %02d:%02d:%02d"; 
        $r = sprintf $fmt, $year, $mm, $dd, $hh, $mi, $ss;
    } elsif ($otp==2) {
        $fmt = "%04d%02d%02d_%02d%02d%02d"; 
        $r = sprintf $fmt, $year, $mm, $dd, $hh, $mi, $ss;
    } elsif ($otp==5) { # output format: MM/DD/YYYY hh:mm:ss
        $fmt = "%02d/%02d/%04d %02d:%02d:%02d"; 
        $r = sprintf $fmt, $mm, $dd, $year, $hh, $mi, $ss;
    } elsif ($otp==11) { # output format: WWW Mon DD hh:mm:ss YYYY
        $r = scalar localtime(time);
    } elsif ($otp==21) { # output format: YYYYMMDD.hhmmss
        $r = sprintf $fmt, $year, $mm, $dd, $hh, $mi, $ss;
    } elsif ($otp==22) { # output format: YYYYMMDD
        $fmt = "%04d%02d%02d"; 
        $r = sprintf $fmt, $year, $mm, $dd;
    } elsif ($otp==23) { # output format: YYYYMM
        $fmt = "%04d%02d"; 
        $r = sprintf $fmt, $year, $mm;
    } elsif ($otp==24) { # output format: YYYYMM
        $fmt = "%04d"; 
        $r = sprintf $fmt, $year;
    } else {
        $r = sprintf $fmt, $year, $mm, $dd, $hh, $mi, $ss;
    }
    return $r;
}

sub _YY2Y4 {
    my $self = shift;
    my ($yr, $py) = @_;
    $py = 31 if !$py;
    if ($yr <= $py) {              # $yr between 00~31 ==> 2000~2031
        $yr += 2000;
    } elsif ($yr>$py && $yr<100) { # $yr between 32~99 ==> 1932~1999
        $yr += 1900;
    } elsif ($yr==100) {           # $yr = 100         ==> 2000
        $yr = 2000; 
    } else {                       # $yr > 100         ==> 2001~oo
        $yr += 1900;
    }
    return sprintf("%04d", $yr);
}


sub getWksInYear {
    my $self = shift;
    my($year,$mon, $mday, $otyp) = @_;
    my($days, $tmp, @t, $r);
    #
    # Input variables:
    #   $year - year in YY or YYYY
    #   $mon - month from 1 to 12
    #   $mday - day in a month from 1 to 31
    #   $otyp - output type: 2=YYWW 4=YYYYWW others=WW
    # Local variables:
    #   $days - total days in the year for tm
    #   $tmp  - variable for temporarily holding a value
    #   @t    - temp array
    #   $r    - return string
    # Global variables used or defined:  None
    # Calls to:
    #   &cvtYY2Y4($year,$itp) 
    # Return: 
    #   WW or YYWW or YYYYWW based on output type
    # Purpose: get week numbers in a year. Valid week number is 0 to 53.
    # History:
    #   03/29/1999 - converted and modified from funcdate.awk.
    #
    if (!$otyp) { $otyp=0 }
    use Time::Local;      # so we can use timelocal sub
    #
    # localtime : ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
    # timelocal : does the reverse of localtime
    #
    # get days of a year for the date
    @t = localtime(timelocal(0,0,0,$mday,$mon-1,$year));
    $days = $t[7];
    # get the day of the year for the first Saturday in the $year
    @t = localtime(timelocal(0,0,0,1,0,$year));
    $tmp = 7 - $t[6];
    if ($days > $tmp) {
        $tmp = int(($days - $tmp) / 7) + 1;
    } else {
        $tmp = 0;
    }
    if ($otyp==2) {
        if (length($year)==2) {
            $r = sprintf('%02d%02d', $year, $tmp);
        } elsif (length($year)==4) {
            $r = sprintf('%02d%02d', substr($year,2,2), $tmp);
        } else { $r = 0 }
    } elsif ($otyp==4) {
        if (length($year)==2) {
            $r = sprintf('%04d%02d', $self->cvtYY2Y4($year,24), $tmp);
        } elsif (length($year)==4) {
            $r = sprintf('%04d%02d', $year, $tmp);
        } else { $r = 0; }
    } else {
        $r = sprintf('%02d', $tmp);
    }
    return $r;
}


# -------------------------------------------------------------------

# Autoload methods go after =cut, and are processed by the autosplit 
# program.

1;   # ensure that the module can be successfully used.

__END__

# Below is the stub of documentation for your module. You better edit 
# it!

=head1 AUTHOR

Hanming Tu, hanming_tu@yahoo.com

=head1 SEE ALSO 

DateTime::Precise, Time::Local, 
perltoot(1), perlobj(1), perlbot(1), perlsub(1), perldata(1),
perlsub(1), perlmod(1), perlmodlib(1), perlref(1), perlreftut(1).

=cut

