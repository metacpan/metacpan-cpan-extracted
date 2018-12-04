######################################################################
#
# NEC_CP932_by_Unicode.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# cp932 to Unicode table
# ftp://ftp.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP932.TXT
# https://support.microsoft.com/ja-jp/help/170559/prb-conversion-problem-between-shift-jis-and-unicode

use strict;
use File::Basename;

my %NEC_CP932_by_Unicode = ();

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
            $NEC_CP932_by_Unicode{$1} = $cp932_hex;
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
        if (0) {
        }

        # NEC Row 13
        elsif (('8740' le $cp932a) and ($cp932a le '879c')) {
            $NEC_CP932_by_Unicode{ uc($Unicode) } = uc $cp932a;
        }

        # NEC Row 89 - Row 92
        elsif (('ed40' le $cp932a) and ($cp932a le 'eefc')) {
            $NEC_CP932_by_Unicode{ uc($Unicode) } = uc $cp932a;
        }

        # IBM's own
        elsif (('fa40' le $cp932a) and ($cp932a le 'fc4b')) {
        }
    }
}
close(FILE);

sub NEC_CP932_by_Unicode {
    my($unicode) = @_;
    return $NEC_CP932_by_Unicode{$unicode};
}

sub keys_of_NEC_CP932_by_Unicode {
    return keys %NEC_CP932_by_Unicode;
}

sub values_of_NEC_CP932_by_Unicode {
    return values %NEC_CP932_by_Unicode;
}

1;

__END__
