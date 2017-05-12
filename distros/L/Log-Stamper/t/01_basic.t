use strict;
use warnings;
use Test::More 0.88;

use Log::Stamper;

$Log::Stamper::GMTIME = 1;

my $GMTIME = 1030429942 - 7*3600;

# Year
my $formatter = Log::Stamper->new("yyyy yy yyyy");
is($formatter->format($GMTIME), "2002 02 2002");

# Month
$formatter = Log::Stamper->new("MM M MMMM yyyy");
is($formatter->format($GMTIME), "08 8 August 2002");

# Month
$formatter = Log::Stamper->new("MMM yyyy");
is($formatter->format($GMTIME), "Aug 2002");

# Day-of-Month
$formatter = Log::Stamper->new("d ddd dd dddd yyyy");
is($formatter->format($GMTIME), "26 026 26 0026 2002");

# am/pm Hour
$formatter = Log::Stamper->new("h hh hhh hhhh");
is($formatter->format($GMTIME), "11 11 011 0011");

# 24 Hour
$formatter = Log::Stamper->new("H HH HHH HHHH");
is($formatter->format($GMTIME), "23 23 023 0023");

# Minute
$formatter = Log::Stamper->new("m mm mmm mmmm");
is($formatter->format($GMTIME), "32 32 032 0032");

# Second
$formatter = Log::Stamper->new("s ss sss ssss");
is($formatter->format($GMTIME), "22 22 022 0022");

# Day of Week
$formatter = Log::Stamper->new("E EE EEE EEEE");
is($formatter->format($GMTIME), "Mon Mon Mon Monday");
is($formatter->format($GMTIME+24*60*60*1), "Tue Tue Tue Tuesday");
is($formatter->format($GMTIME+24*60*60*2), "Wed Wed Wed Wednesday");
is($formatter->format($GMTIME+24*60*60*3), "Thu Thu Thu Thursday");
is($formatter->format($GMTIME+24*60*60*4), "Fri Fri Fri Friday");
is($formatter->format($GMTIME+24*60*60*5), "Sat Sat Sat Saturday");
is($formatter->format($GMTIME+24*60*60*6), "Sun Sun Sun Sunday");

# Day of Year
$formatter = Log::Stamper->new("D DD DDD DDDD");
is($formatter->format($GMTIME), "238 238 238 0238");

# AM/PM
$formatter = Log::Stamper->new("a aa");
is($formatter->format($GMTIME), "PM PM");

# Milliseconds
$formatter = Log::Stamper->new("S SS SSS SSSS SSSSS SSSSSS");
is($formatter->format($GMTIME, 123456), "1 12 123 1234 12345 123456");

# Unknown
$formatter = Log::Stamper->new("xx K");
is($formatter->format($GMTIME), "xx -- 'K' not (yet) implemented --");

# DDD bugfix
$formatter = Log::Stamper->new("DDD");
   # 1/1/2006
is($formatter->format(1136106000), "001");
$formatter = Log::Stamper->new("D");
   # 1/1/2006
is($formatter->format(1136106000), "1");

###########################################
# Allowing literal text in L4p >= 1.19
###########################################
my @tests = (
    q!yyyy-MM-dd'T'HH:mm:ss.SSS'Z'! => q!%04d-%02d-%02dT%02d:%02d:%02d.%sZ!,
    q!yyyy-MM-dd''HH:mm:ss.SSS''!   => q!%04d-%02d-%02d%02d:%02d:%02d.%s!,
    q!yyyy-MM-dd''''HH:mm:ss.SSS!   => q!%04d-%02d-%02d'%02d:%02d:%02d.%s!,
    q!yyyy-MM-dd''''''HH:mm:ss.SSS! => q!%04d-%02d-%02d''%02d:%02d:%02d.%s!,
    q!yyyy-MM-dd,HH:mm:ss.SSS!      => q!%04d-%02d-%02d,%02d:%02d:%02d.%s!,
    q!HH:mm:ss,SSS!                 => q!%02d:%02d:%02d,%s!,
    q!dd MMM yyyy HH:mm:ss,SSS!     => q!%02d %.3s %04d %02d:%02d:%02d,%s!,
    q!hh 'o''clock' a!              => q!%02d o'clock %1s!,
    q!hh 'o'clock' a!               => q!(undef)!,
    q!yyyy-MM-dd 'at' HH:mm:ss!     => q!%04d-%02d-%02d at %02d:%02d:%02d!,
);

#' calm down up vim syntax highlighting

while ( my ( $src, $expected ) = splice @tests, 0, 2 ) {
    my $df = eval { Log::Stamper->new( $src ) };
    my $err = '';
    if ( $@ )
    {
        chomp $@;
        $err = "(error: $@)";
    }
    my $got = $df->{fmt} || '(undef)';
    is($got, $expected, "literal $src");
}

done_testing;
