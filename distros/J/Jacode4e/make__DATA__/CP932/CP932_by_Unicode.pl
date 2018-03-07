######################################################################
#
# CP932_by_Unicode.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# cp932 to Unicode table
# ftp://ftp.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP932.TXT
# https://support.microsoft.com/ja-jp/help/170559/prb-conversion-problem-between-shift-jis-and-unicode

use strict;
use File::Basename;

my %CP932_by_Unicode = ();

open(FILE,"@{[File::Basename::dirname(__FILE__)]}/ftp.__ftp.unicode.org_Public_MAPPINGS_VENDORS_MICSFT_WINDOWS_CP932.TXT") || die;
while (<FILE>) {
    chomp;
    next if /^#/;
    my($cp932, $Unicode, $Unicode_name) = split(/\t/, $_);
    next if $Unicode_name eq '#UNDEFINED';
    next if $Unicode_name eq '#DBCS LEAD BYTE';
    if ($cp932 =~ /^0x([0123456789ABCDEF]{2}|[0123456789ABCDEF]{4})$/) {
        my $cp932_hex = $1;
        if ($Unicode =~ /^0x([0123456789ABCDEF]{4})$/) {
            $CP932_by_Unicode{$1} = $cp932_hex;
        }
        else {
            die;
        }
    }
    else {
        die;
    }
}
close(FILE);

open(FILE,"@{[File::Basename::dirname(__FILE__)]}/prb-conversion-problem-between-shift-jis-and-unicode.txt") || die;
while (<FILE>) {
    chomp;
    next if /^#/;
    if (my($cp932a, $Unicode, $cp932b) = / 0x([0123456789abcdef]{4}) .+? U\+([0123456789abcdef]{4}) .+? 0x([0123456789abcdef]{4}) /x) {
        $CP932_by_Unicode{ uc($Unicode) } = uc($cp932b);
    }
}
close(FILE);

# WAVE DASH
#
# 2014-October-6
# The character U+301C WAVE DASH was encoded to represent JIS C 6226-1978
# 1-33. However, the representative glyph is inverted relative to the
# original source. The glyph will be modified in future editions to match the
# JIS source. The glyph shown below on the left is the incorrect glyph.
# The corrected glyph is shown on the right. (See document L2/14-198 for
# further context for this change.) 
#
# http://www.unicode.org/versions/Unicode8.0.0/erratafixed.html

delete $CP932_by_Unicode{'FF5E'};   # FULLWIDTH TILDE
$CP932_by_Unicode{'301C'} = '8160'; # WAVE DASH

sub CP932_by_Unicode {
    my($unicode) = @_;
    return $CP932_by_Unicode{$unicode};
}

sub keys_of_CP932_by_Unicode {
    return keys %CP932_by_Unicode;
}

sub values_of_CP932_by_Unicode {
    return values %CP932_by_Unicode;
}

1;

__END__
