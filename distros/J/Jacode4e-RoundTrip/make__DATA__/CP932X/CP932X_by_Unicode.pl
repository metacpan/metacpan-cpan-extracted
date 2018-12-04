######################################################################
#
# CP932X_by_Unicode.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib $FindBin::Bin;

# CP932X
require 'CP932/CP932_by_Unicode.pl';
require 'ShiftJIS2004/ShiftJIS2004_by_Unicode.pl';

if ($0 eq __FILE__) {
    open(DUMP,">$0.dump") || die;
    binmode(DUMP);
}

my %unicode = map { $_ => 1 } (
    keys_of_CP932_by_Unicode(),
    keys_of_ShiftJIS2004_by_Unicode(),
);

my %CP932X_by_Unicode = ();
my %done = ();

for my $unicode (sort { (length($a) <=> length($b)) || ($a cmp $b) } keys %unicode) {
    if (CP932_by_Unicode($unicode) eq '9C5A') {
        $done{$CP932X_by_Unicode{$unicode} = '9C5A' . '9C5A'} = 1;
printf DUMP "%-8s %-9s %-8s %-4s %-8s \n", $CP932X_by_Unicode{$unicode}, $unicode, $CP932X_by_Unicode{$unicode}, '----', '----';
    }
    elsif ((CP932_by_Unicode($unicode) ne '') and not $done{CP932_by_Unicode($unicode)}) {
        $done{$CP932X_by_Unicode{$unicode} = CP932_by_Unicode($unicode)} = 1;
printf DUMP "%-8s %-9s %-8s %-4s %-8s \n", $CP932X_by_Unicode{$unicode}, $unicode, '----', $CP932X_by_Unicode{$unicode}, '----';
    }
    elsif ((ShiftJIS2004_by_Unicode($unicode) ne '') and not $done{ShiftJIS2004_by_Unicode($unicode)}) {
        $done{$CP932X_by_Unicode{$unicode} = '9C5A' . ShiftJIS2004_by_Unicode($unicode)} = 1;
printf DUMP "%-8s %-9s %-8s %-4s %-8s \n", $CP932X_by_Unicode{$unicode}, $unicode, '----', '----', $CP932X_by_Unicode{$unicode};
    }
}

close(DUMP);

sub CP932X_by_Unicode {
    my($unicode) = @_;
    return $CP932X_by_Unicode{$unicode};
}

sub keys_of_CP932X_by_Unicode {
    return keys %CP932X_by_Unicode;
}

sub values_of_CP932X_by_Unicode {
    return values %CP932X_by_Unicode;
}

1;

__END__
