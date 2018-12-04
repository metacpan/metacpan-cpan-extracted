######################################################################
#
# make_KEIS90.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib $FindBin::Bin;

# KEIS90
require 'KEIS/make_KEIS83.pl';
require 'CP932/CP932_by_Unicode.pl';
require 'KEIS/KEIS90_by_SJIS.pl';

if ($0 eq __FILE__) {
    open(DUMP,">$0.dump") || die;
    binmode(DUMP);
}

my %unicode = map { $_ => 1 } (
    keys_of_KEIS83_by_Unicode(),
    '51DC',
    '7199',
);

my %KEIS90_by_Unicode = ();
my %done = ();

for my $unicode (sort { (length($a) <=> length($b)) || ($a cmp $b) } keys %unicode) {
    if (0) {
    }
    elsif ($unicode eq '51DC') {
        $done{$KEIS90_by_Unicode{$unicode} = 'F4A5'} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s \n", $KEIS90_by_Unicode{$unicode}, $unicode, $KEIS90_by_Unicode{$unicode}, '----', '----', '----';
    }
    elsif ($unicode eq '7199') {
        $done{$KEIS90_by_Unicode{$unicode} = 'F4A6'} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s \n", $KEIS90_by_Unicode{$unicode}, $unicode, $KEIS90_by_Unicode{$unicode}, '----', '----', '----';
    }
    elsif (
        (KEIS90_by_SJIS(CP932_by_Unicode($unicode)) ne '') and
        (KEIS83_by_Unicode($unicode)                ne '') and
        (KEIS90_by_SJIS(CP932_by_Unicode($unicode)) eq KEIS83_by_Unicode($unicode)) and
        not $done{KEIS83_by_Unicode($unicode)}
    ) {
        $done{$KEIS90_by_Unicode{$unicode} = KEIS83_by_Unicode($unicode)} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s \n", $KEIS90_by_Unicode{$unicode}, $unicode, '----', $KEIS90_by_Unicode{$unicode}, '----', '----';
    }
    elsif (
        (KEIS90_by_SJIS(CP932_by_Unicode($unicode)) ne '') and
        (KEIS83_by_Unicode($unicode)                ne '') and
        (KEIS90_by_SJIS(CP932_by_Unicode($unicode)) ne KEIS83_by_Unicode($unicode)) and
        not $done{KEIS83_by_Unicode($unicode)}
    ) {
die sprintf "Unicode=($unicode), KEIS90_by_SJIS=(%s) KEIS90_by_SJIS, CP932_by_Unicode=(%s)\n", KEIS90_by_SJIS(CP932_by_Unicode($unicode)), KEIS90_by_SJIS(CP932_by_Unicode($unicode));
    }
    elsif (
        (KEIS90_by_SJIS(CP932_by_Unicode($unicode)) eq '') and
        (KEIS83_by_Unicode($unicode)                ne '') and
        not $done{KEIS83_by_Unicode($unicode)}
    ) {
        $done{$KEIS90_by_Unicode{$unicode} = KEIS83_by_Unicode($unicode)} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s \n", $KEIS90_by_Unicode{$unicode}, $unicode, '----', '----', $KEIS90_by_Unicode{$unicode}, '----';
    }
    elsif (
        (KEIS90_by_SJIS(CP932_by_Unicode($unicode)) ne '') and
        (KEIS83_by_Unicode($unicode)                eq '') and
        not $done{KEIS90_by_SJIS(CP932_by_Unicode($unicode))}
    ) {
        $done{$KEIS90_by_Unicode{$unicode} = KEIS90_by_SJIS(CP932_by_Unicode($unicode))} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s \n", $KEIS90_by_Unicode{$unicode}, $unicode, '----', '----', '----', $KEIS90_by_Unicode{$unicode};
    }
}

close(DUMP);

sub KEIS90_by_Unicode {
    my($unicode) = @_;
    return $KEIS90_by_Unicode{$unicode};
}

sub keys_of_KEIS90_by_Unicode {
    return keys %KEIS90_by_Unicode;
}

sub values_of_KEIS90_by_Unicode {
    return values %KEIS90_by_Unicode;
}

1;

__END__
