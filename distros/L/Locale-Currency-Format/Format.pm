package Locale::Currency::Format;

require 5.006_00;

use strict;

use Exporter;

$Locale::Currency::Format::VERSION = '1.35';

@Locale::Currency::Format::ISA     = qw(Exporter);
@Locale::Currency::Format::EXPORT  = qw(
    currency_format
    currency_name
    currency_set
    currency_symbol
    decimal_precision
    decimal_separator
    thousands_separator
    FMT_NOZEROS
    FMT_STANDARD
    FMT_COMMON
    FMT_SYMBOL
    FMT_HTML
    FMT_NAME
    SYM_UTF
    SYM_HTML
);

@Locale::Currency::Format::EXPORT_OK = qw($error);

%Locale::Currency::Format::EXPORT_TAGS = (
  DEFAULT => [@Locale::Currency::Format::EXPORT],
  default => [@Locale::Currency::Format::EXPORT],
);

$Locale::Currency::Format::error = q{};

# Macros for format options
sub FMT_NOZEROS()  { 0x0001 }
sub FMT_STANDARD() { 0x0002 }
sub FMT_SYMBOL()   { 0x0004 }
sub FMT_COMMON()   { 0x0008 }
sub FMT_HTML()     { 0x0010 }
sub FMT_NAME()     { 0x0020 }

# Macros for symbol options
sub SYM_UTF()      { 0x0001 }
sub SYM_HTML()     { 0x0002 }

# Constants
my $EMPTY = q{};
my $SPACE = q{ };

# File variables
my ($name, $frac_len, $thou_sep, $dec_sep,
    $space_sep, $utf_sym, $htm_sym, $com_sym, $pre) = (0..8);

my %original;
my %currency;
my @currency_codes;

*::_error = \$Locale::Currency::Format::error; 

sub currency_format {
    my ($code, $amt, $style) = @_;

    if (!defined $amt) {
        $::_error = 'Undefined currency amount';
        return; 
    }

    if (!defined $code) {
        $::_error = 'Undefined currency code';
        return; 
    }

    my $ucc = uc $code;
    my $cur = $currency{$ucc};
    if (!$cur) {
        $::_error = 'Invalid currency code';
        return;
    }

    $amt = format_number(
                $amt,
                $cur->[$frac_len] || 0,         # round-off precision
                $style ? !($style & 0x1) : 1,   # trailing zero or no
                $cur->[$thou_sep],              # thousand separator
                $cur->[$dec_sep]                # decimal separator
           );

    $style = $style ? $style & 0x00FE : FMT_STANDARD; 

    return    $style == FMT_SYMBOL && $cur->[$utf_sym]
            ? join($cur->[$space_sep], $cur->[$pre] ? ($cur->[$utf_sym], $amt)
                                                    : ($amt, $cur->[$utf_sym]))
            : $style == FMT_HTML && $cur->[$htm_sym]
            ? join($cur->[$space_sep], $cur->[$pre] ? ($cur->[$htm_sym], $amt)
                                                    : ($amt, $cur->[$htm_sym]))
            : $style == FMT_COMMON && $cur->[$com_sym]
            ? join($cur->[$space_sep], $cur->[$pre] ? ($cur->[$com_sym], $amt)
                                                    : ($amt, $cur->[$com_sym]))
            : $style == FMT_NAME
            ? join($SPACE, $amt, $cur->[$name])
            : join($SPACE, $amt, $ucc)
            ;
}

sub currency_symbol {
    my ($code, $type) = @_;

    if (!defined $code) {
        $::_error = 'Undefined currency code';
        return;
    }
    
    $type = SYM_UTF unless $type;
    if ($type != SYM_HTML and $type != SYM_UTF) {
        $::_error = 'Invalid symbol type';
        return;
    }

    my $cur = $currency{uc $code};
    if (!$cur) {
        $::_error = 'Invalid currency code';
        return;
    }

    my $sym = $type == SYM_UTF ? $cur->[$utf_sym] : $cur->[$htm_sym];
    if (!$sym) {
        $::_error = 'Non-existant currency'
                  . ($type == SYM_UTF ? ' UTF ' : ' HTML ')
                  . 'symbol';
        return;
    }

    return $sym;
}

sub currency_name {
    my ( $code ) = @_;

    if ( !defined $code ) {
        $::_error = 'Undefined currency code';
        return;
    }

    my $cur = $currency{ uc $code };
    if ( !$cur ) {
        $::_error = 'Invalid currency code';
        return;
    }

    my $name =  $cur->[0];
    if ( !$name ) {
        $::_error = 'Non-existant currency name';
        return;
    }
    return $name;
}

sub currency_list {
    return \@currency_codes;
}

sub decimal_precision {
    my ($code) = @_;

    if (!defined $code) {
        $::_error = 'Undefined currency code';
        return;
    }

    my $cur = $currency{uc $code};
    if (!$cur) {
        $::_error = 'Invalid currency code';
        return;
    }

    my $precision = $cur->[$frac_len];
    if (!$precision) {
        $::_error = 'Non-existant decimal precision';
        return;
    }

    return $precision;
}

sub decimal_separator {
    my ($code) = @_;

    if (!defined $code) {
        $::_error = 'Undefined currency code';
        return;
    }

    my $cur = $currency{uc $code};
    if (!$cur) {
        $::_error = 'Invalid currency code';
        return;
    }

    my $separator = $cur->[$dec_sep];
    if (!$separator) {
        $::_error = 'Non-existant decimal separator';
        return;
    }

    return $separator;
}

sub thousands_separator {
    my ($code) = @_;

    if (!defined $code) {
        $::_error = 'Undefined currency code';
        return;
    }

    my $cur = $currency{uc $code};
    if (!$cur) {
        $::_error = 'Invalid currency code';
        return;
    }

    my $separator = $cur->[$thou_sep];
    if (!$separator) {
        $::_error = 'Non-existant thousands separator';
        return;
    }

    return $separator;
}

sub currency_set {
    my ($code, $tmpl, $style) = @_;

    if (!$code) {
        $::_error = 'Undefined currency code';
        return;
    }
    if ($tmpl
        and (!$style 
             or !grep { $style == $_ } (FMT_SYMBOL, FMT_HTML, FMT_COMMON))
       ) {
        $::_error = 'Format must be of FMT_SYMBOL, FMT_HTML, FMT_COMMON';
        return;
    }

    my $ucc = uc $code;
    my $cur = $currency{$ucc};
    if (!$cur) {
        $::_error = 'Invalid currency code';
        return;
    }

    if (!$tmpl) {
        $currency{$ucc} = $original{$ucc} if $original{$ucc};
        @currency_codes = keys %currency;
        return $ucc;
    }

    if ($tmpl !~ m{ \A
                    ([^#]*)         # 1 - preceding symbol (may contain space)
                    \#              #     followed by a #
                    ([^#]+)         # 2 - thousand separator
                    \#{3}           #     followed by 3 #'s
                    (?:             # 
                        ([^#]+)     # 3 - decimal separator
                        (\#+)       # 4 - fractional
                    )*              #
                    ([^#]*)         # 5 - trailing symbol (may contain space)
                    \Z
                  }xms
            or ($1 and $5)
        ) {
        $::_error = 'Irregular currency format';
        return;
    }

    # Let's save an original copy if it has yet been done
    $original{$ucc}   = [@$cur] unless $original{$ucc};

    # Set fields based on template
    $cur->[$pre]      = $1 ? 1 : 0 if $1 or $5;
    $cur->[$thou_sep] = $2;
    $cur->[$dec_sep ] = $3 || $EMPTY;
    $cur->[$frac_len] = $4 ? length($4) : 0;
    if (($1 || $5) =~ m{\A (\s*) (.+) (\s*) \Z}xms) {
        $cur->[$space_sep] = $1 || $3;
        if ($style == FMT_SYMBOL) {
            $cur->[$utf_sym] = $2;
        }
        elsif ($style == FMT_HTML) {
            $cur->[$htm_sym] = $2;
        }
        elsif ($style == FMT_COMMON) {
            $cur->[$com_sym] = $2;    
        }
    }
    @currency_codes = keys %currency;
    return $ucc;
}

# These functions are copied directly out of Number::Format due to a bug that 
# lets locale settings take higher precedence to user's specific manipulation.
# In addition, this will exclude the unnecessary POSIX module used by 
# Number::Format.

sub round {
    my ($number, $precision) = @_;
    
    $precision = 2 unless defined $precision;
    $number    = 0 unless defined $number;

    my $sign = $number <=> 0;
    my $multiplier = (10 ** $precision);
    my $result = abs($number);
    $result = int(($result * $multiplier) + .5000001) / $multiplier;
    $result = -$result if $sign < 0;
    return $result;
}

sub format_number {
    my ($number, $precision, $trailing_zeroes, $ksep, $dsep) = @_;

    # Set defaults and standardize number
    $precision = 2 unless defined $precision;
    $trailing_zeroes = 1 unless defined $trailing_zeroes;

    # Handle negative numbers
    my $sign = $number <=> 0;
    $number = abs($number) if $sign < 0;
    $number = round($number, $precision); # round off $number

    # Split integer and decimal parts of the number and add commas
    my $integer = int($number);
    my $decimal;
    # Note: In perl 5.6 and up, string representation of a number
    # automagically includes the locale decimal point.  This way we
    # will detect the decimal part correctly as long as the decimal
    # point is 1 character.
    $decimal = substr($number, length($integer)+1)
        if (length($integer) < length($number));
    $decimal = $EMPTY unless defined $decimal;

    # Add trailing 0's if $trailing_zeroes is set.
    $decimal .= '0'x( $precision - length($decimal) )
        if $trailing_zeroes && $precision > length($decimal);

    # Add leading 0's so length($integer) is divisible by 3
    $integer = '0'x(3 - (length($integer) % 3)).$integer
      	unless length($integer) % 3 == 0;

    # Split $integer into groups of 3 characters and insert commas
    $integer = join($ksep, grep {$_ ne $EMPTY} split(/(...)/, $integer));

    # Strip off leading zeroes and/or comma
    $integer =~ s/^0+//;
    $integer = '0' if $integer eq $EMPTY;

    # Combine integer and decimal parts and return the result.
    my $result = ((defined $decimal && length $decimal) ?
                  join($dsep, $integer, $decimal) :
                  $integer);

    return ($sign < 0) ? format_negative($result) : $result;
}

sub format_negative {
    my($number, $format) = @_;
    $format = '-x' unless defined $format;
    $number =~ s/^-//;
    $format =~ s/x/$number/;
    return $format;
}



#===========================================================================
# ISO 4217 and common world currency symbols 
#===========================================================================
# code => 0       1       2       3       4        5       6       7       8
#        name frac_len thou_sep dec_sep space_sep utf_sym htm_sym com_sym pre
%currency = (
AED => ["UAE Dirham",2,",","."," ",$EMPTY,$EMPTY,"Dhs.",1],
AFA => ["Afghani",0,$EMPTY,$EMPTY,"\x{060B}","&#x060B;",,$EMPTY,$EMPTY],
ALL => ["Lek",2,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
AMD => ["Armenian Dram",2,",",".","",$EMPTY,$EMPTY,"AMD",0],
ANG => ["Antillian Guilder",2,".",","," ","\x{0192}","&#x0192;","NAf.",1],
AON => ["New Kwanza",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
ARS => ["Argentine Peso",2,".",",","","\x{20B1}","&#x20B1;","\$",1],
ATS => ["Schilling",2,".",","," ",$EMPTY,$EMPTY,"öS",1],
AUD => ["Australian Dollar",2," ",".","","\x{0024}","&#x0024;","\$",1],
AWG => ["Aruban Guilder",2,",","."," ","\x{0192}","&#x0192;","AWG",1],
AZN => ["Azerbaijanian Manat",2,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,"m",$EMPTY],
BAM => ["Convertible Marks",2,",",".","",$EMPTY,$EMPTY,"AZM",0],
BBD => ["Barbados Dollar",2,$EMPTY,$EMPTY,"","\x{0024}","&#x0024;",$EMPTY,$EMPTY],
BDT => ["Taka",2,",","."," ",$EMPTY,$EMPTY,"Bt.",1],
BEF => ["Belgian Franc",0,".",""," ","\x{20A3}","&#x20A3;","BEF",1],
BGN => ["Lev",2," ",","," ",$EMPTY,$EMPTY,"lv",0],
BHD => ["Bahraini Dinar",3,",","."," ",$EMPTY,$EMPTY,"BD",1],
BIF => ["Burundi Franc",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
BMD => ["Bermudian Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
BND => ["Brunei Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
BOB => ["Bolivian Boliviano",2,",",".","",$EMPTY,$EMPTY,"Bs",1],
BRL => ["Brazilian Real",2,".",","," ","\x{0052}\x{0024}","R\$","R\$",1],
BSD => ["Bahamian Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
BTN => ["Bhutan Ngultrum",2,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
BWP => ["Pula",2,",",".","",$EMPTY,$EMPTY,"P",1],
BYR => ["Belarussian Ruble",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
BZD => ["Belize Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
CAD => ["Canadian Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
CDF => ["Franc Congolais",2,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
CHF => ["Swiss Franc",2,"'","."," ",$EMPTY,$EMPTY,"SFr.",1],
CLP => ["Chilean Peso",0,".","","","\x{20B1}","&#x20B1;","\$",1],
CNY => ["Yuan Renminbi",2,",",".","","\x{5713}","&#x5713;","Y",1],
COP => ["Colombian Peso",2,".",",","","\x{20B1}","&#x20B1;","\$",1],
CRC => ["Costa Rican Colon",2,".",","," ","\x{20A1}","&#x20A1;","₡",1],
CUP => ["Cuban Peso",2,",","."," ","\x{20B1}","&#x20B1;","\$",1],
CVE => ["Cape Verde Escudo",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
CYP => ["Cyprus Pound",2,".",",","","\x{00A3}","&#x00A3;","£",1],
CZK => ["Czech Koruna",2,".",","," ",$EMPTY,$EMPTY,"Kc",0],
DEM => ["Deutsche Mark",2,".",",","",$EMPTY,$EMPTY,"DM",0],
DJF => ["Djibouti Franc",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
DKK => ["Danish Krone",2,".",",","",$EMPTY,$EMPTY,"kr.",1],
DOP => ["Dominican Peso",2,",","."," ","\x{20B1}","&#x20B1;","\$",1],
DZD => ["Algerian Dinar",2,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
ECS => ["Sucre",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
EEK => ["Kroon",2," ",","," ",$EMPTY,$EMPTY,"EEK",0],
EGP => ["Egyptian Pound",2,",","."," ","\x{00A3}","&#x00A3;","L.E.",1],
ERN => ["Nakfa",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
ESP => ["Spanish Peseta",0,".",""," ","\x{20A7}","&#x20A7;","Ptas",0],
ETB => ["Ethiopian Birr",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
EUR => ["Euro",2,".",",","","\x{20AC}","&#x20AC;","EUR",1],
FIM => ["Markka",2," ",","," ",$EMPTY,$EMPTY,"mk",0],
FJD => ["Fiji Dollar",0,$EMPTY,$EMPTY,"","\x{0024}","&#x0024;",$EMPTY,$EMPTY],
FKP => ["Pound",0,$EMPTY,$EMPTY,"","\x{00A3}","&#x00A3;",$EMPTY,$EMPTY],
FRF => ["French Franc",2," ",","," ","\x{20A3}","&#x20A3;","FRF",0],
GBP => ["Pound Sterling",2,",",".","","\x{00A3}","&#x00A3;","£",1],
GEL => ["Lari",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
GHS => ["Cedi",2,",",".","","\x{20B5}","&#x20B5;","₵",1],
GIP => ["Gibraltar Pound",2,",",".","","\x{00A3}","&#x00A3;","£",1],
GMD => ["Dalasi",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
GNF => ["Guinea Franc",$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY],
GRD => ["Drachma",2,".",","," ","\x{20AF}","&#x20AF;","GRD",0],
GTQ => ["Quetzal",2,",",".","",$EMPTY,$EMPTY,"Q.",1],
GWP => ["Guinea-Bissau Peso",$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY],
GYD => ["Guyana Dollar",0,$EMPTY,$EMPTY,"","\x{0024}","&#x0024;",$EMPTY,$EMPTY],
HKD => ["Hong Kong Dollar",2,",",".","","\x{0024}","&#x0024;","HK\$",1],
HNL => ["Lempira",2,",","."," ",$EMPTY,$EMPTY,"L",1],
HRK => ["Kuna",2,".",","," ",$EMPTY,$EMPTY,"kn",0],
HTG => ["Gourde",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
HUF => ["Forint",0,".",""," ",$EMPTY,$EMPTY,"Ft",0],
IDR => ["Rupiah",0,".","","",$EMPTY,$EMPTY,"Rp.",1],
IEP => ["Irish Pound",2,",",".","","\x{00A3}","&#x00A3;","£",1],
ILS => ["New Israeli Sheqel",2,",","."," ","\x{20AA}","&#x20AA;","NIS",0],
INR => ["Indian Rupee",2,",",".","","\x{20A8}","&#x20A8;","Rs.",1],
IQD => ["Iraqi Dinar",3,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
IRR => ["Iranian Rial",2,",","."," ","\x{FDFC}","&#xFDFC;","Rls",1],
ISK => ["Iceland Krona",2,".",","," ",$EMPTY,$EMPTY,"kr",0],
ITL => ["Italian Lira",0,".",""," ","\x{20A4}","&#x20A4;","L.",1],
JMD => ["Jamaican Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
JOD => ["Jordanian Dinar",3,",","."," ",$EMPTY,$EMPTY,"JD",1],
JPY => ["Yen",0,",","","","\x{00A5}","&#x00A5;","¥",1],
KES => ["Kenyan Shilling",2,",",".","",$EMPTY,$EMPTY,"Kshs.",1],
KGS => ["Som",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
KHR => ["Riel",2,$EMPTY,$EMPTY,"","\x{17DB}","&#x17DB;",$EMPTY,$EMPTY],
KMF => ["Comoro Franc",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
KPW => ["North Korean Won",0,$EMPTY,$EMPTY,"","\x{20A9}","&#x20A9;",$EMPTY,$EMPTY],
KRW => ["Won",0,",","","","\x{20A9}","&#x20A9;","\\",1],
KWD => ["Kuwaiti Dinar",3,",","."," ",$EMPTY,$EMPTY,"KD",1],
KYD => ["Cayman Islands Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
KZT => ["Tenge",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
LAK => ["Kip",0,$EMPTY,$EMPTY,"","\x{20AD}","&#x20AD;",$EMPTY,$EMPTY],
LBP => ["Lebanese Pound",0," ","","","\x{00A3}","&#x00A3;","L.L.",0],
LKR => ["Sri Lanka Rupee",0,$EMPTY,$EMPTY,"","\x{0BF9}","&#x0BF9;",$EMPTY,$EMPTY],
LRD => ["Liberian Dollar",0,$EMPTY,$EMPTY,"","\x{0024}","&#x0024;",$EMPTY,$EMPTY],
LSL => ["Lesotho Maloti",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
LTL => ["Lithuanian Litas",2," ",","," ",$EMPTY,$EMPTY,"Lt",0],
LUF => ["Luxembourg Franc",0,"'",""," ","\x{20A3}","&#x20A3;","F",0],
LVL => ["Latvian Lats",2,",","."," ",$EMPTY,$EMPTY,"Ls",1],
LYD => ["Libyan Dinar",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
MAD => ["Moroccan Dirham",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
MDL => ["Moldovan Leu",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
MGF => ["Malagasy Franc",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
MKD => ["Denar",2,",","."," ",$EMPTY,$EMPTY,"MKD",0],
MMK => ["Kyat",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
MNT => ["Tugrik",0,$EMPTY,$EMPTY,"","\x{20AE}","&#x20AE;",$EMPTY,$EMPTY],
MOP => ["Pataca",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
MRO => ["Ouguiya",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
MTL => ["Maltese Lira",2,",",".","","\x{20A4}","&#x20A4;","Lm",1],
MUR => ["Mauritius Rupee",0,",","","","\x{20A8}","&#x20A8;","Rs",1],
MVR => ["Rufiyaa",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
MWK => ["Kwacha",2,",",".","",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
MXN => ["Mexican Peso",2,",","."," ","\x{0024}","&#x0024;","\$",1],
MYR => ["Malaysian Ringgit",2,",",".","",$EMPTY,$EMPTY,"RM",1],
MZN => ["Metical",2,".",","," ",$EMPTY,$EMPTY,"Mt",0],
NAD => ["Namibian Dollar",0,$EMPTY,$EMPTY,"","\x{0024}","&#x0024;",$EMPTY,$EMPTY],
NGN => ["Naira",0,$EMPTY,$EMPTY,"","\x{20A6}","&#x20A6;",$EMPTY,$EMPTY],
NIO => ["Cordoba Oro",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
NLG => ["Netherlands Guilder",2,".",","," ","\x{0192}","&#x0192;","f",1],
NOK => ["Norwegian Krone",2,".",","," ","kr","kr","kr",1],
NPR => ["Nepalese Rupee",2,",","."," ","\x{20A8}","&#x20A8;","Rs.",1],
NZD => ["New Zealand Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
OMR => ["Rial Omani",3,",","."," ","\x{FDFC}","&#xFDFC;","RO",1],
PAB => ["Balboa",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
PEN => ["Nuevo Sol",2,",","."," ","S/.","S/.","S/.",1],
PGK => ["Kina",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
PHP => ["Philippine Peso",2,",",".","","\x{20B1}","&#x20B1;","PHP",1],
PKR => ["Pakistan Rupee",2,",",".","","\x{20A8}","&#x20A8;","Rs.",1],
PLN => ["Zloty",2," ",","," ",$EMPTY,$EMPTY,"zl",0],
PTE => ["Portuguese Escudo",0,".",""," ",$EMPTY,$EMPTY,"Esc",0],
PYG => ["Guarani",0,$EMPTY,$EMPTY,"","\x{20B2}","&#x20B2;","Gs.",$EMPTY],
QAR => ["Qatari Rial",0,$EMPTY,$EMPTY,"","\x{FDFC}","&#xFDFC;",$EMPTY,$EMPTY],
RON => ["Leu",2,".",","," ",$EMPTY,$EMPTY,"lei",0],
RSD => ["Serbian Dinar",2,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,"din",0],
RUB => ["Russian Ruble",2,".",",",$EMPTY,"\x{0440}\x{0443}\x{0431}","&#x0440;&#x0443;&#x0431;","RUB",1],
RWF => ["Rwanda Franc",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
SAC => ["S. African Rand Commerc.",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
SAR => ["Saudi Riyal",2,",","."," ","\x{FDFC}","&#xFDFC;","SR",1],
SBD => ["Solomon Islands Dollar",0,$EMPTY,$EMPTY,"","\x{0024}","&#x0024;",$EMPTY,$EMPTY],
SCR => ["Seychelles Rupee",0,$EMPTY,$EMPTY,"","\x{20A8}","&#x20A8;",$EMPTY,$EMPTY],
SDG => ["Sudanese Dinar",$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,"LSd",$EMPTY],
SDP => ["Sudanese Pound",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
SEK => ["Swedish Krona",2," ",","," ",$EMPTY,$EMPTY,"kr",0],
SGD => ["Singapore Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
SHP => ["St Helena Pound",0,$EMPTY,$EMPTY,"","\x{00A3}","&#x00A3;",$EMPTY,$EMPTY],
SIT => ["Tolar",2,".",","," ",$EMPTY,$EMPTY,"SIT",0],
SKK => ["Slovak Koruna",2," ",","," ",$EMPTY,$EMPTY,"Sk",0],
SLL => ["Leone",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
SOS => ["Somali Shilling",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
SRG => ["Surinam Guilder",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
STD => ["Dobra",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
SVC => ["El Salvador Colon",2,",",".","","\x{20A1}","&#x20A1;","¢",1],
SYP => ["Syrian Pound",0,$EMPTY,$EMPTY,"","\x{00A3}","&#x00A3;",$EMPTY,$EMPTY],
SZL => ["Lilangeni",2,"",".","",$EMPTY,$EMPTY,"E",1],
THB => ["Baht",2,",","."," ","\x{0E3F}","&#x0E3F;","Bt",0],
TJR => ["Tajik Ruble",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
TJS => ["Somoni",$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY],
TMM => ["Manat",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
TND => ["Tunisian Dinar",3,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
TOP => ["Pa'anga",2,",","."," ",$EMPTY,$EMPTY,"\$",1],
TPE => ["Timor Escudo",$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY],
TRY => ["Turkish Lira",0,",","","","\x{20A4}","&#x20A4;","TL",0],
TTD => ["Trinidad and Tobago Dollar",0,$EMPTY,$EMPTY,"","\x{0024}","&#x0024;",$EMPTY,$EMPTY],
TWD => ["New Taiwan Dollar",0,$EMPTY,$EMPTY,"","\x{0024}","&#x0024;",$EMPTY,$EMPTY],
TZS => ["Tanzanian Shilling",2,",","."," ",$EMPTY,$EMPTY,"TZs",0],
UAH => ["Hryvnia",2," ",",","","\x{20B4}","&#x20B4",$EMPTY,0],
UGX => ["Uganda Shilling",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
USD => ["US Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
UYU => ["Peso Uruguayo",2,".",",","","\x{20B1}","&#x20B1;","\$",1],
UZS => ["Uzbekistan Sum",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
VEF => ["Bolivar",2,".",","," ",$EMPTY,$EMPTY,"Bs.F",1],
VND => ["Dong",2,".",","," ","\x{20AB}","&#x20AB;","Dong",0],
VUV => ["Vatu",0,",","","",$EMPTY,$EMPTY,"VT",0],
WST => ["Tala",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
XAF => ["CFA Franc BEAC",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
XCD => ["East Caribbean Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
XOF => ["CFA Franc BCEAO",$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY],
XPF => ["CFP Franc",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
YER => ["Yemeni Rial",0,$EMPTY,$EMPTY,"","\x{FDFC}","&#xFDFC;",$EMPTY,$EMPTY],
YUN => ["New Dinar",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
ZAR => ["Rand",2," ","."," ","\x{0052}","&#x0052;","R",1],
ZMK => ["Kwacha",0,$EMPTY,$EMPTY,"",$EMPTY,$EMPTY,$EMPTY,$EMPTY],
ZRN => ["New Zaire",$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY,$EMPTY],
ZWD => ["Zimbabwe Dollar ",2," ",".","","\x{0024}","&#x0024;","Z\$",1],
);
@currency_codes = keys %currency;

1;

__END__

=head1 NAME

Locale::Currency::Format - Perl functions for formatting monetary values

=head1 SYNOPSIS

  use Locale::Currency::Format;

  $amt = currency_format('USD', 1000);             # => 1,000.00 USD
  $amt = currency_format('EUR', 1000, FMT_COMMON); # => EUR1.000,00
  $amt = currency_format('USD', 1000, FMT_SYMBOL); # => $1,000.00

  $sym = currency_symbol('USD');                   # => $
  $sym = currency_symbol('GBP', SYM_HTML);         # => &#163;

  $decimals = decimal_precision('USD');            # => 2
  $decimals = decimal_precision('BHD');            # => 3

  $thou_sep = thousands_separator('USD');          # => ,
  $thou_sep = thousands_separator('EUR');          # => .

  $dec_sep = decimal_separator('USD');             # => .
  $dec_sep = decimal_separator('EUR');             # => ,

  currency_set('USD', '#.###,## $', FMT_COMMON);   # => set custom format
  currency_format('USD', 1000, FMT_COMMON);        # => 1.000,00 $
  currency_set('USD');                             # => reset default format
 
The following example illustrates how to use Locale::Currency::Format
with Mason. Skip it if you are not interested in Mason. A simple Mason
component might look like this: 

  Total: <% 123456789, 'eur' |c %> 

  <%init>
    use Locale::Currency::Format;

    $m->interp->set_escape(c => \&escape_currency);

    sub escape_currency {
      my ($amt, $code) = ${$_[0]} =~ /(.*?)([A-Za-z]{3})/;
      ${$_[0]} = currency_format($code, $amt, FMT_HTML);
    }
  </%init>

=head1 DESCRIPTION

B<Locale::Currency::Format> is a light-weight Perl module that enables Perl code to display monetary values in the formats recognized internationally and/or locally.

=over 2

=item C<currency_format(CODE, AMOUNT [, FORMAT])>

B<currency_format> takes two mandatory parameters, namely currency code and 
amount respectively, and optionally a third parameter indicating which
format is desired. Upon failure, it returns I<undef> and an error message is
stored in B<$Locale::Currency::Format::error>.

    CODE
        A 3-letter currency code as specified in ISO 4217.
        Note that old code such as DEM, FRF and so on can also
        be valid.

    AMOUNT
        A numeric value.

    FORMAT
        There are five different format options FMT_STANDARD,
        FMT_COMMON, FMT_SYMBOL, FMT_HTML and FMT_NAME. If it is
        omitted, the default format is FMT_STANDARD.

        FMT_STANDARD Ex: 1,000.00 USD, 1.000.000,00 EUR
        FMT_SYMBOL   Ex: $1,000.00
        FMT_COMMON   Ex: 1.000 Dong (Vietnam), BEF 1.000 (Belgium)
        FMT_HTML     Ex: &#xA3;1,000.00  (pound-sign HTML escape)
        FMT_NAME     Ex: 1,000.00 US Dollar

        NOTE: By default the trailing zeros after the decimal
        point will be added. To turn it off, do a bitwise C<or>
        of FMT_NOZEROS with one of the five options above.
        Ex: FMT_STANDARD | FMT_NOZEROS  will give 1,000 USD
           
=item C<currency_symbol(CODE [, TYPE])>

For conveniences, the function B<currency_symbol> is provided for currency symbol
lookup given a 3-letter currency code. Optionally, one can specify which
format the symbol should be returned - Unicode-based character or HTML escape.
Default is a Unicode-based character. Upon failure, it returns I<undef> and an error message is stored in B<$Locale::Currency::Format::error>.

    CODE
        A 3-letter currency code as specified in ISO 4217

    TYPE
        There are two available types SYM_UTF and SYM_HTML
        SYM_UTF  returns the symbol (if exists) as an Unicode
		 character
        SYM_HTML returns the symbol (if exists) as a HTML escape

=item C<currency_name(CODE)>

For conveniences, the function B<currency_name> is provided for currency name
lookup given a 3-letter currency code. Upon failure, it returns I<undef> and an error message is stored in B<$Locale::Currency::Format::error>.

    CODE
        A 3-letter currency code as specified in ISO 4217

=item C<decimal_precision(CODE)>

For conveniences, the function B<decimal_precision> is provided to lookup the decimal
precision for a given 3-letter currency code.

Upon failure, it returns I<undef> and an error message is stored in B<$Locale::Currency::Format::error>.

    CODE
        A 3-letter currency code as specified in ISO 4217

=item C<decimal_separator(CODE)>

For conveniences, the function B<decimal_separator> is provided to lookup the decimal
separator for a given 3-letter currency code.

Upon failure, it returns I<undef> and an error message is stored in B<$Locale::Currency::Format::error>.

    CODE
        A 3-letter currency code as specified in ISO 4217

=item C<thousands_separator(CODE)>

For conveniences, the function B<thousands_separator> is provided to lookup the thousands 
separator for a given 3-letter currency code.

Upon failure, it returns I<undef> and an error message is stored in B<$Locale::Currency::Format::error>.

    CODE
        A 3-letter currency code as specified in ISO 4217

=item C<currency_set(CODE [, TEMPLATE, FORMAT])>

B<currency_set> can be used to set a custom format for a currency instead of the provided format. For example, in many non-English speaking countries, the US dollars might be displayed as B<2.999,99 $> instead of the usual B<$2,999.99>. In order to accomplish this, one will need to do as follows:

    use Locale::Currency::Format qw(:default $error);

    my $currency = 'USD';
    my $template = '#.###,## $';
    if (currency_set($currency, $template, FMT_COMMON)) {
        print currency_format($currency, 2999.99, FMT_COMMON), "\n";
    }
    else {
        print "cannot set currency format for $currency: $error\n";
    }

The arguments to B<currency_set> are:

    CODE
        A 3-letter currency code as specified in ISO 4217

    TEMPLATE
        A template in the form #.###,##$, #.### kr, etc.

        If a unicode character is used, make sure that
        the template is double-quoted.
        Ex: currency_set('GBP', "\x{00A3}#,###.##", FMT_SYMBOL)

        If an HTML symbol is wanted, escape its equivalent HTML code.
        Ex: currency_set('GBP', '&#x00A3;#,###.##', FMT_HTML)

    FORMAT
        This argument is required if TEMPLATE is present.
        The formats FMT_SYMBOL, FMT_COMMON, FMT_HTML are accepted.

        NOTE!
        FMT_STANDARD and FMT_NAME will always be in the form
        <amount><space><code|name> such as 1,925.95 AUD. Hence,
        currency_set returns an error if FMT_STANDARD or FMT_NAME
        is specified as FORMAT.

        With FMT_COMMON, you can always achieve what you would
        have done with FMT_STANDARD and FMT_NAME, as follows
             
        my $amt = 1950.95;
        currency_set('USD', 'USD #.###,##', FMT_COMMON);
        print currency_format('USD', $amt, FMT_COMMON); # USD 1,950.95
        currency_set('USD', 'US Dollar #.###,##', FMT_COMMON);
        print currency_format('USD', $amt, FMT_COMMON); # US Dollar 1,950.95

Invoking B<currency_set> with one argument will reset all formats to their original settings.

For example

    currency_set('USD')

will clear all previous custom settings for the US currency (ie. FMT_SYMBOL, FMT_HTML, FMT_COMMON).

=back

=head2 A WORD OF CAUTION

Please be aware that some currencies might have missing common format. In that case, B<currency_format> will fall back to B<FMT_STANDARD> format.

Also, be aware that some currencies do not have monetary symbol.

As countries merge together or split into smaller ones, currencies can be added or removed by the ISO. Please help keep the list up to date by sending your feedback to the email address at the bottom.

To see the error, examine $Locale::Currency::Format::error

    use Locale::Currency::Format;
    my $value = currency_format('USD', 1000);
    print $value ? $value : $Locale::Currency::Format::error

    OR

    use Locale::Currency::Format qw(:DEFAULT $error);
    my $value = currency_format('USD', 1000);
    print $value ? $value : $error 

Lastly, please refer to L<perluniintro> and L<perlunicode> for displaying Unicode characters if you intend to use B<FMT_SYMBOL> and B<currency_symbol>. Otherwise, it reads "No worries, mate!"

=head1 SEE ALSO

L<Locale::Currency>, L<Math::Currency>, L<Number::Format>, L<perluniintro>, L<perlunicode>

=head1 ISSUES

Pull requests are greatly appreciated at https://github.com/tann/locale-currency-format

=head1 CONTRIBUTOR(S)

Please add your name to this list when sending a pull request.

James Kiser <james.kiser@gmail.com>

Lars Wirzenius <lars@catalyst.net.nz>

=head1 AUTHOR

Tan D Nguyen <https://github.com/tann>

=head1 COPYRIGHT

This library is free software. You may distribute under the terms of either the GNU General Public License or the Artistic License.

=cut 
