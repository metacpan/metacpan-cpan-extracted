######################################################################
#
# KEIS90_by_SJIS.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# Appendix E Handling of character codes in PDE - Form Designer (applies only to distributed type PDE)
# http://itdoc.hitachi.co.jp/manuals/3020/30203p0360/PDEF0203.HTM

use strict;
use File::Basename;

if ($0 eq __FILE__) {
    open(DUMP,">$0.dump") || die;
    binmode(DUMP);
}

my %KEIS90_by_SJIS = ();

for my $file (qw(
    http.__itdoc.hitachi.co.jp_manuals_3020_30203P0360_PDEF0203.HTM_table_E1.txt
    http.__itdoc.hitachi.co.jp_manuals_3020_30203P0360_PDEF0203.HTM_table_E3.txt
    http.__itdoc.hitachi.co.jp_manuals_3020_30203P0360_PDEF0203.HTM_table_E5.txt
    http.__itdoc.hitachi.co.jp_manuals_3020_30203P0360_PDEF0203.HTM_table_E7.txt
)) {
    open(FILE,"@{[File::Basename::dirname(__FILE__)]}/$file") || die;
    while (<FILE>) {
        chomp;
        next if /^#/;
        @_ = grep(/./, map { /^([0123456789ABCDEF]{4})/ ? $1 : () } split(/\t/,$_));
        while (my($keis90,$sjis) = splice(@_,0,2)) {
            if ($keis90 !~ /^[0123456789ABCDEF]{4}$/) {
                die "KEIS90=($keis90), SJIS=($sjis)";
            }
            if ($sjis !~ /^[0123456789ABCDEF]{4}$/) {
                die "KEIS90=($keis90), SJIS=($sjis)";
            }
            $KEIS90_by_SJIS{$sjis} = $keis90;
printf DUMP "%-4s %-4s \n", $sjis, $keis90;
        }
    }
    close(FILE);
}

close(DUMP);

if (scalar(keys %KEIS90_by_SJIS) != (34+22*2+4*2+1*2)) {
    die sprintf "scalar(keys %KEIS90_by_SJIS) != (34+22*2+4*2+1*2) only (%d)\n", scalar(keys %KEIS90_by_SJIS);
}

sub KEIS90_by_SJIS {
    my($sjis) = @_;

    if ($sjis eq '') {
        return '';
    }
    elsif (defined $KEIS90_by_SJIS{$sjis}) {
        return $KEIS90_by_SJIS{$sjis};
    }
    else {
        return '';
    }
}

1;

__END__
