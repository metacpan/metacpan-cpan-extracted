######################################################################
#
# make_KEIS78.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib $FindBin::Bin;

# KEIS78
require 'KEIS/make_KEIS83.pl';
require 'KEIS/KEIS78_by_KEIS83.pl';

if ($0 eq __FILE__) {
    open(DUMP,">$0.dump") || die;
    binmode(DUMP);
}

my %unicode = map { $_ => 1 } (
    keys_of_KEIS83_by_Unicode(),
);

my %KEIS78_by_Unicode = ();
my %done = ();

for my $unicode (sort { (length($a) <=> length($b)) || ($a cmp $b) } keys %unicode) {
    if ((KEIS78_by_KEIS83(KEIS83_by_Unicode($unicode)) ne '') and not $done{KEIS78_by_KEIS83(KEIS83_by_Unicode($unicode))}) {
        $done{$KEIS78_by_Unicode{$unicode} = KEIS78_by_KEIS83(KEIS83_by_Unicode($unicode))} = 1;
printf DUMP "%-4s %-9s %-4s %-4s \n", $KEIS78_by_Unicode{$unicode}, $unicode, $KEIS78_by_Unicode{$unicode}, '----';
    }
    elsif ((KEIS83_by_Unicode($unicode) ne '') and not $done{KEIS83_by_Unicode($unicode)}) {
        $done{$KEIS78_by_Unicode{$unicode} = KEIS83_by_Unicode($unicode)} = 1;
printf DUMP "%-4s %-9s %-4s %-4s \n", $KEIS78_by_Unicode{$unicode}, $unicode, '----', $KEIS78_by_Unicode{$unicode};
    }
}

close(DUMP);

sub KEIS78_by_Unicode {
    my($unicode) = @_;
    return $KEIS78_by_Unicode{$unicode};
}

sub keys_of_KEIS78_by_Unicode {
    return keys %KEIS78_by_Unicode;
}

sub values_of_KEIS78_by_Unicode {
    return values %KEIS78_by_Unicode;
}

1;

__END__
