######################################################################
#
# KEIS78_by_KEIS83.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# Appendix B.2 Character code differences
# http://itdoc.hitachi.co.jp/manuals/3020/3020759580/G5950334.HTM

use strict;
use File::Basename;

if ($0 eq __FILE__) {
    open(DUMP,">$0.dump") || die;
    binmode(DUMP);
}

my %KEIS78_by_KEIS83 = ();

for my $file (qw(
    http.__itdoc.hitachi.co.jp_manuals_3020_3020759580_G5950334.HTM_table_B3.txt
    http.__itdoc.hitachi.co.jp_manuals_3020_3020759580_G5950334.HTM_table_B4.txt
)) {
    open(FILE,"@{[File::Basename::dirname(__FILE__)]}/$file") || die;
    while (<FILE>) {
        chomp;
        next if /^#/;
        @_ = grep(/./, map { /^([0123456789ABCDEF]{4})/ ? $1 : () } split(/\t/,$_));
        while (my($keis83,$keis78) = splice(@_,0,2)) {
            if (($keis83) = $keis83 =~ /^([0123456789ABCDEF]{4})/) {
            }
            else {
                die "KIES83=($keis83), KIES78=($keis78)";
            }
            if (($keis78) = $keis78 =~ /^([0123456789ABCDEF]{4})/) {
            }
            else {
                die "KIES83=($keis83), KIES78=($keis78)";
            }

            if (not defined $KEIS78_by_KEIS83{$keis83}) {
                $KEIS78_by_KEIS83{$keis83} = $keis78;
printf DUMP "%-4s %-4s \n", $keis83, $keis78;
            }
        }
    }
    close(FILE);
}

close(DUMP);

if (scalar(keys %KEIS78_by_KEIS83) != (25*2+18*2-14)) {
    die sprintf "scalar(keys %KEIS78_by_KEIS83) != (25*2+18*2-14) only (%d)\n", scalar(keys %KEIS78_by_KEIS83);
}

sub KEIS78_by_KEIS83 {
    my($keis83) = @_;

    if ($keis83 eq '') {
        return '';
    }
    elsif (defined $KEIS78_by_KEIS83{$keis83}) {
        return $KEIS78_by_KEIS83{$keis83};
    }
    else {
        return '';
    }
}

1;

__END__
