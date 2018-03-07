######################################################################
#
# make_JIPSE.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib $FindBin::Bin;

# JIPS(E)
require 'EBCDIC/EBCDIC_NEC_by_JIS8.pl';
require 'JIPS/make_JIPSJ.pl';

if ($0 eq __FILE__) {
    open(DUMP,">$0.dump") || die;
    binmode(DUMP);
}

my %unicode = map { $_ => 1 } (
    keys_of_JIPSJ_by_Unicode(),
);

my %JIPSE_by_Unicode = ();
my %done = ();

for my $unicode (sort { (length($a) <=> length($b)) || ($a cmp $b) } keys %unicode) {
    if (((EBCDIC_NEC_by_JIS8(substr(JIPSJ_by_Unicode($unicode),0,2)) . EBCDIC_NEC_by_JIS8(substr(JIPSJ_by_Unicode($unicode),2,2))) ne '') and not $done{EBCDIC_NEC_by_JIS8(substr(JIPSJ_by_Unicode($unicode),0,2)) . EBCDIC_NEC_by_JIS8(substr(JIPSJ_by_Unicode($unicode),2,2))}) {
        $done{$JIPSE_by_Unicode{$unicode} = EBCDIC_NEC_by_JIS8(substr(JIPSJ_by_Unicode($unicode),0,2)) . EBCDIC_NEC_by_JIS8(substr(JIPSJ_by_Unicode($unicode),2,2))} = 1;
printf DUMP "%-4s %-9s %-4s \n", $JIPSE_by_Unicode{$unicode}, $unicode, $JIPSE_by_Unicode{$unicode};
    }
}

close(DUMP);

sub JIPSE_by_Unicode {
    my($unicode) = @_;
    return $JIPSE_by_Unicode{$unicode};
}

sub keys_of_JIPSE_by_Unicode {
    return keys %JIPSE_by_Unicode;
}

sub values_of_JIPSE_by_Unicode {
    return values %JIPSE_by_Unicode;
}

1;

__END__
