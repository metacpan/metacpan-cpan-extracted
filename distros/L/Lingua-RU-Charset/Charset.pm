package Lingua::RU::Charset;

################################################################################
# Nothing is exported by def. - use :CHARSET, :CONVERT, :CHARCASE or sub names #
################################################################################

use strict;
use vars qw ($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
require Exporter;

$VERSION     = 0.02;
@ISA         = qw (Exporter);

@EXPORT_OK   = qw (ENG KOI WIN ALT ISO MAC RUS UNI UTF charset
                   any2koi win2koi alt2koi iso2koi mac2koi rus2koi uni2koi utf2koi
                   koi2win any2win alt2win iso2win mac2win rus2win uni2win utf2win
                   koi2alt win2alt any2alt iso2alt mac2alt rus2alt uni2alt utf2alt
                   koi2iso win2iso alt2iso any2iso mac2iso rus2iso uni2iso utf2iso
                   koi2mac win2mac alt2mac iso2mac any2mac rus2mac uni2mac utf2mac
                   koi2rus win2rus alt2rus iso2rus mac2rus any2rus uni2rus utf2rus
                   koi2uni win2uni alt2uni iso2uni mac2uni rus2uni any2uni utf2uni
                   koi2utf win2utf alt2utf iso2utf mac2utf rus2utf uni2utf any2utf
		   koi2lc  win2lc  alt2lc  iso2lc  mac2lc  rus2lc  uni2lc  utf2lc
		   koi2uc  win2uc  alt2uc  iso2uc  mac2uc  rus2uc  uni2uc  utf2uc);

%EXPORT_TAGS = (CHARSET  => [ qw (ENG KOI WIN ALT ISO MAC RUS UNI UTF charset) ],
                CONVERT  => [ qw (any2koi win2koi alt2koi iso2koi mac2koi rus2koi uni2koi utf2koi
				  koi2win any2win alt2win iso2win mac2win rus2win uni2win utf2win
				  koi2alt win2alt any2alt iso2alt mac2alt rus2alt uni2alt utf2alt
				  koi2iso win2iso alt2iso any2iso mac2iso rus2iso uni2iso utf2iso
				  koi2mac win2mac alt2mac iso2mac any2mac rus2mac uni2mac utf2mac
				  koi2rus win2rus alt2rus iso2rus mac2rus any2rus uni2rus utf2rus
				  koi2uni win2uni alt2uni iso2uni mac2uni rus2uni any2uni utf2uni
				  koi2utf win2utf alt2utf iso2utf mac2utf rus2utf uni2utf any2utf) ],
                CHARCASE => [ qw (koi2lc  win2lc  alt2lc  iso2lc  mac2lc  rus2lc  uni2lc  utf2lc
				  koi2uc  win2uc  alt2uc  iso2uc  mac2uc  rus2uc  uni2uc  utf2uc) ]);


################################################################################
# Hash tables with frequencies of russian letter pairs                         #
################################################################################

my (%KOI, %WIN, %ALT, %ISO, %MAC, %RUS, %UNI, %UTF);       # TODO

################################################################################
# Define charsets returned by the charset subroutine below                     #
################################################################################

sub ENG { 0 }                          # unknown charset
sub KOI { 1 }                          # KOI8-r
sub WIN { 2 }                          # Windows-1251
sub ALT { 3 }                          # CP866
sub ISO { 4 }                          # ISO-8859-5
sub MAC { 5 }                          # X-Mac-Cyrillic
sub RUS { 6 }                          # russian text in english letters
sub UNI { 7 }                          # Unicode
sub UTF { 8 }                          # UTF-8

################################################################################
# Try detecting charset by counting pairs of russian letters                   #
################################################################################

sub charset { 0 }                      # TODO

################################################################################
# Convert a KOI8-r string or a list of strings into the Windows-1251 charset   #
################################################################################

sub koi2win
{
    my @str = @_;                      # copy the arguments

    map { tr/\xA3\xB3\xC0-\xFF/\xB8\xA8\xFE\xE0\xE1\xF6\xE4\xE5\xF4\xE3\xF5\xE8-\xEF\xFF\xF0-\xF3\xE6\xE2\xFC\xFB\xE7\xF8\xFD\xF9\xF7\xFA\xDE\xC0\xC1\xD6\xC4\xC5\xD4\xC3\xD5\xC8-\xCF\xDF\xD0-\xD3\xC6\xC2\xDC\xDB\xC7\xD8\xDD\xD9\xD7\xDA/ } @str;

    return @str;
}

################################################################################
# Convert a Windows-1251 string or a list of strings into the KOI8-r charset   #
################################################################################

sub win2koi
{
    my @str = @_;                      # copy the arguments

    map { tr/\xB8\xA8\xFE\xE0\xE1\xF6\xE4\xE5\xF4\xE3\xF5\xE8-\xEF\xFF\xF0-\xF3\xE6\xE2\xFC\xFB\xE7\xF8\xFD\xF9\xF7\xFA\xDE\xC0\xC1\xD6\xC4\xC5\xD4\xC3\xD5\xC8-\xCF\xDF\xD0-\xD3\xC6\xC2\xDC\xDB\xC7\xD8\xDD\xD9\xD7\xDA/\xA3\xB3\xC0-\xFF/ } @str;

    return @str;
}

################################################################################
# Convert a KOI8-r string or a list of strings into the CP-866 charset         #
################################################################################

sub koi2alt
{
    my @str = @_;                      # copy the arguments

    map { tr/\xA3\xB3\xC0-\xFF/\xF1\xF0\xEE\xA0\xA1\xE6\xA4\xA5\xE4\xA3\xE5\xA8-\xAF\xEF\xE0-\xE3\xA6\xA2\xEC\xEB\xA7\xE8\xED\xE9\xE7\xEA\x9E\x80\x81\x96\x84\x85\x94\x83\x95\x88-\x8F\x9F\x90-\x93\x86\x82\x9C\x9B\x87\x98\x9D\x99\x97\x9A/ } @str;

    return @str;
}

################################################################################
# Convert a CP-866 string or a list of strings into the KOI8-r charset         #
################################################################################

sub alt2koi
{
    my @str = @_;                      # copy the arguments

    map { tr/\xF1\xF0\xEE\xA0\xA1\xE6\xA4\xA5\xE4\xA3\xE5\xA8-\xAF\xEF\xE0-\xE3\xA6\xA2\xEC\xEB\xA7\xE8\xED\xE9\xE7\xEA\x9E\x80\x81\x96\x84\x85\x94\x83\x95\x88-\x8F\x9F\x90-\x93\x86\x82\x9C\x9B\x87\x98\x9D\x99\x97\x9A/\xA3\xB3\xC0-\xFF/ } @str;

    return @str;
}

################################################################################
# Convert a KOI8-r string or a list of strings into the ISO-8859-5 charset     #
################################################################################

sub koi2iso
{
    my @str = @_;                      # copy the arguments

    map { tr/\xA3\xB3\xC0-\xFF/\xF1\xA1\xEE\xD0\xD1\xE6\xD4\xD5\xE4\xD3\xE5\xD8-\xDF\xEF\xE0-\xE3\xD6\xD2\xEC\xEB\xD7\xE8\xED\xE9\xE7\xEA\xCE\xB0\xB1\xC6\xB4\xB5\xC4\xB3\xC5\xB8-\xBF\xCF\xC0-\xC3\xB6\xB2\xCC\xCB\xB7\xC8\xCD\xC9\xC7\xCA/ } @str;

    return @str;
}

################################################################################
# Convert a ISO-8859-5 string or a list of strings into the KOI8-r charset     #
################################################################################

sub iso2koi
{
    my @str = @_;                      # copy the arguments

    map { tr/\xF1\xA1\xEE\xD0\xD1\xE6\xD4\xD5\xE4\xD3\xE5\xD8-\xDF\xEF\xE0-\xE3\xD6\xD2\xEC\xEB\xD7\xE8\xED\xE9\xE7\xEA\xCE\xB0\xB1\xC6\xB4\xB5\xC4\xB3\xC5\xB8-\xBF\xCF\xC0-\xC3\xB6\xB2\xCC\xCB\xB7\xC8\xCD\xC9\xC7\xCA/\xA3\xB3\xC0-\xFF/ } @str;

    return @str;
}

################################################################################
# Convert a KOI8-r string or a list of strings into the X-Mac-Cyrillic charset #
################################################################################

sub koi2mac
{
    my @str = @_;                      # copy the arguments

    map { tr/\xA3\xB3\xC0-\xFF/\xDE\xDD\xFE\xE0\xE1\xF6\xE4\xE5\xF4\xE3\xF5\xE8-\xEF\xDF\xF0-\xF3\xE6\xE2\xFC\xFB\xE7\xF8\xFD\xF9\xF7\xFA\x9E\x80\x81\x96\x84\x85\x94\x83\x95\x88-\x8F\x9F\x90-\x93\x86\x82\x9C\x9B\x87\x98\x9D\x99\x97\x9A/ } @str;

    return @str;
}

################################################################################
# Convert a X-Mac-Cyrillic string or a list of strings into the KOI8-r charset #
################################################################################

sub mac2koi
{
    my @str = @_;                      # copy the arguments

    map { tr/\xDE\xDD\xFE\xE0\xE1\xF6\xE4\xE5\xF4\xE3\xF5\xE8-\xEF\xDF\xF0-\xF3\xE6\xE2\xFC\xFB\xE7\xF8\xFD\xF9\xF7\xFA\x9E\x80\x81\x96\x84\x85\x94\x83\x95\x88-\x8F\x9F\x90-\x93\x86\x82\x9C\x9B\x87\x98\x9D\x99\x97\x9A/\xA3\xB3\xC0-\xFF/ } @str;

    return @str;
}

################################################################################
# Convert a KOI8-r string or a list of strings into the "russkij" charset      #
################################################################################

sub koi2rus
{
    my @str = @_;                      # copy the arguments

    map { tr/\xA3\xB3\xC1-\xD0\xD2-\xD5\xD7-\xDA\xDC\xDF\xE1-\xF0\xF2-\xF5\xF7-\xFA\xFC\xFF/eEabcdefgxijklmnoprstuv`ize'ABCDEFGXIJKLMNOPRSTUV`IZE'/ } @str;

    map { s/\xC0/ju/g  } @str;
    map { s/\xD1/ja/g  } @str;
    map { s/\xD6/zh/g  } @str;
    map { s/\xDB/sh/g  } @str;
    map { s/\xDD/sch/g } @str;
    map { s/\xDE/ch/g  } @str;
    map { s/\xE0/Ju/g  } @str;
    map { s/\xF1/Ja/g  } @str;
    map { s/\xF6/Zh/g  } @str;
    map { s/\xFB/Sh/g  } @str;
    map { s/\xFD/Sch/g } @str;
    map { s/\xFE/Ch/g  } @str;

    return @str;
}

################################################################################
# Convert a "russkij" string or a list of strings into the KOI8-r charset      #
################################################################################

sub rus2koi
{
    @_;                                                    # TODO
}

################################################################################
# Convert a KOI8-r string or a list of strings to lower case                   #
################################################################################

sub koi2lc
{
    my @str = @_;                      # copy the arguments

    map { tr/\xB3\xE0-\xFF/\xA3\xC0-\xDF/ } @str;

    return @str;
}

################################################################################
# Convert a KOI8-r string or a list of strings to upper case                   #
################################################################################

sub koi2uc
{
    my @str = @_;                      # copy the arguments

    map { tr/\xA3\xC0-\xDF/\xB3\xE0-\xFF/ } @str;

    return @str;
}

################################################################################
# Convert a Windows-1251 string or a list of strings to lower case             #
################################################################################

sub win2lc
{
    my @str = @_;                      # copy the arguments

    map { tr/\xA8\xC0-\xDF/\xB8\xE0-\xFF/ } @str;

    return @str;
}

################################################################################
# Convert a Windows-1251 string or a list of strings to upper case             #
################################################################################

sub win2uc
{
    my @str = @_;                      # copy the arguments

    map { tr/\xB8\xE0-\xFF/\xA8\xC0-\xDF/ } @str;

    return @str;
}

################################################################################
# Convert a CP-866 string or a list of strings to lower case                   #
################################################################################

sub alt2lc
{
    my @str = @_;                      # copy the arguments

    map { tr/\xF0\x80-\x9F/\xF1\xA0-\xAF\xE0-\xEF/ } @str;

    return @str;
}

################################################################################
# Convert a CP-866 string or a list of strings to upper case                   #
################################################################################

sub alt2uc
{
    my @str = @_;                      # copy the arguments

    map { tr/\xF1\xA0-\xAF\xE0-\xEF/\xF0\x80-\x9F/ } @str;

    return @str;
}

################################################################################
# Convert a ISO-8859-5 string or a list of strings to lower case               #
################################################################################

sub iso2lc
{
    my @str = @_;                      # copy the arguments

    map { tr/\xA1\xB0-\xCF/\xF1\xD0-\xEF/ } @str;

    return @str;
}

################################################################################
# Convert a ISO-8859-5 string or a list of strings to upper case               #
################################################################################

sub iso2uc
{
    my @str = @_;                      # copy the arguments

    map { tr/\xF1\xD0-\xEF/\xA1\xB0-\xCF/ } @str;

    return @str;
}

################################################################################
# Convert a X-Mac-Cyrillic string or a list of strings to lower case           #
################################################################################

sub mac2lc
{
    my @str = @_;                      # copy the arguments

    map { tr/\xDD\x80-\xDF/\xDE\xE0-\xFE\xDF/ } @str;

    return @str;
}

################################################################################
# Convert a X-Mac-Cyrillic string or a list of strings to upper case           #
################################################################################

sub mac2uc
{
    my @str = @_;                      # copy the arguments

    map { tr/\xDE\xE0-\xFE\xDF/\xDD\x80-\xDF/ } @str;

    return @str;
}

################################################################################
# Convert a "russkij" string or a list of strings to lower case                #
################################################################################

sub rus2lc
{
    my @str = @_;                      # copy the arguments

    map { tr/A-Z/a-z/ } @str;

    return @str;                                # TODO
}

################################################################################
# Convert a "russkij" string or a list of strings to upper case                #
################################################################################

sub rus2uc
{
    my @str = @_;                      # copy the arguments

    map { tr/a-z/A-Z/ } @str;

    return @str;                                # TODO
}

################################################################################
# Convert a Unicode string or a list of strings to lower case                  #
################################################################################

sub uni2lc                                                 # modify last byte
{
    my $byte;
    my @str = @_;                      # copy the arguments

    map { s#\G(.)(.)# $byte = $2; $byte =~ tr/\x01\x10-\x2F/\x51\x30-\x4F/; $1 != 0x4F ? "$1$2" : "$1$byte" #esg } @str;

    return @str;
}

################################################################################
# Convert a Unicode string or a list of strings to upper case                  #
################################################################################

sub uni2uc
{
    my $byte;
    my @str = @_;                      # copy the arguments

    map { s#\G(.)(.)# $byte = $2; $byte =~ tr/\x51\x30-\x4F/\x01\x10-\x2F/; $1 != 0x4F ? "$1$2" : "$1$byte" #esg } @str;

    return @str;
}

################################################################################
# Convert a UTF-8 string or a list of strings to lower case                    #
################################################################################

sub utf2lc
{
    @_;                                                    # TODO
}

################################################################################
# Convert a UTF-8 string or a list of strings to upper case                    #
################################################################################

sub utf2uc
{
    @_;                                                    # TODO
}

1;

__END__

=head1 NAME

Lingua::RU::Charset - Perl extension for detecting and converting various russian character sets: KOI8-r, Windows-1251, CP866, ISO-8859-5, X-Mac-Cyrillic, russian text in english letters, russian part of Unicode and UTF-8. This module can be especially useful for computers with broken cyrillic locales (like foreign web hosts).

=head1 SYNOPSIS

  use Lingua::RU::Charset qw (:CHARSET);
  use Lingua::RU::Charset qw (:CONVERT);
  use Lingua::RU::Charset qw (:CONVERT :CHARCASE);
  use Lingua::RU::Charset qw (any2koi koi2lc koi2uc);

=head1 DESCRIPTION

More documentation and examples coming soon...

=head1 NOTE

Unfortunately I don't have time to implement the Unicode and UTF-8 subroutines.
But I am sure that such functions would be useful for interesting Perl scripts 
exchanging russian data with Java servlets. So you are welcome to submit some code!

=head1 AUTHOR

Alex Farber, <alex@kawo2.rwth-aachen.de>

=head1 SEE ALSO

"The Cyrillic Charset Soup" article by Roman Czyborra located at
http://czyborra.com/charsets/cyrillic.html lists various cyrillic charsets.
The russian texts for counting frequencies of letter pairs have been taken from 
"The Eugene Peskin's Electronic Library" located at http://www.online.ru/sp/rel/russian/
Please consider also visiting my home page at http://simplex.ru/news/ where 
I collect links to articles and news about Perl, Python, JavaScript, databases etc.

=cut
