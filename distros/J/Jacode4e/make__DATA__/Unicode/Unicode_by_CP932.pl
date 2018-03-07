######################################################################
#
# Unicode_by_CP932.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# cp932 to Unicode table
# ftp://ftp.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP932.TXT

use strict;
use File::Basename;

my %Unicode_by_CP932 = ();

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
            $Unicode_by_CP932{$cp932_hex} = $1;
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

$Unicode_by_CP932{'8160'} = '301C'; # WAVE DASH

sub Unicode_by_CP932 {
    my($cp932) = @_;
    return $Unicode_by_CP932{$cp932};
}

sub keys_of_Unicode_by_CP932 {
    return keys %Unicode_by_CP932;
}

sub values_of_Unicode_by_CP932 {
    return values %Unicode_by_CP932;
}

1;

__END__
