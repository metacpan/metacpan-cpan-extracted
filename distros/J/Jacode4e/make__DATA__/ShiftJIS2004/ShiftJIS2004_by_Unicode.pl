######################################################################
#
# ShiftJIS2004_by_Unicode.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# Shift_JIS-2004 to Unicode table
# http://x0213.org/codetable/sjis-0213-2004-std.txt

use strict;
use File::Basename;

my %ShiftJIS2004_by_Unicode = ();

open(FILE,"@{[File::Basename::dirname(__FILE__)]}/http.__x0213.org_codetable_sjis-0213-2004-std.txt") || die;
while (<FILE>) {
    chomp;
    next if /^#/;
    my($shift_jis_2004, $Unicode, $Unicode_name) = split(/\t/, $_);
    next if $Unicode_name eq '#UNDEFINED';
    next if $Unicode_name eq '#DBCS LEAD BYTE';
    if ($shift_jis_2004 =~ /^0x([0123456789ABCDEF]{2}|[0123456789ABCDEF]{4})$/) {
        my $shift_jis_2004_hex = $1;
        if ($Unicode =~ /^$/) {
        }
        elsif ($Unicode =~ /^U\+([0123456789ABCDEF]{4,6})\+([0123456789ABCDEF]{4,6})$/) {
            $ShiftJIS2004_by_Unicode{"$1+$2"} = $shift_jis_2004_hex;
        }
        elsif ($Unicode =~ /^U\+([0123456789ABCDEF]{4,6})$/) {
            $ShiftJIS2004_by_Unicode{"$1"} = $shift_jis_2004_hex;
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

sub ShiftJIS2004_by_Unicode {
    my($unicode) = @_;
    return $ShiftJIS2004_by_Unicode{$unicode};
}

sub keys_of_ShiftJIS2004_by_Unicode {
    return keys %ShiftJIS2004_by_Unicode;
}

sub values_of_ShiftJIS2004_by_Unicode {
    return values %ShiftJIS2004_by_Unicode;
}

1;

__END__
