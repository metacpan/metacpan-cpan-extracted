######################################################################
#
# make_CP00930.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib $FindBin::Bin;

# CP00930
require 'CP00930/CP00300_by_Unicode.pl';

if ($0 eq __FILE__) {
    open(DUMP,">$0.dump") || die;
    binmode(DUMP);
}

my %unicode = map { $_ => 1 } (
    keys_of_CP00300_by_Unicode(),
);

my %CP00930_by_Unicode = ();
my %done = ();

for my $unicode (sort { (length($a) <=> length($b)) || ($a cmp $b) } keys %unicode) {
    if ((CP00300_by_Unicode($unicode) ne '') and not $done{CP00300_by_Unicode($unicode)}) {
        $done{$CP00930_by_Unicode{$unicode} = CP00300_by_Unicode($unicode)} = 1;
printf DUMP "%-4s %-9s %-4s %-4s \n", $CP00930_by_Unicode{$unicode}, $unicode, '----', $CP00930_by_Unicode{$unicode};
    }
}

close(DUMP);

sub CP00930_by_Unicode {
    my($unicode) = @_;
    return $CP00930_by_Unicode{$unicode};
}

sub keys_of_CP00930_by_Unicode {
    return keys %CP00930_by_Unicode;
}

sub values_of_CP00930_by_Unicode {
    return values %CP00930_by_Unicode;
}

1;

__END__
