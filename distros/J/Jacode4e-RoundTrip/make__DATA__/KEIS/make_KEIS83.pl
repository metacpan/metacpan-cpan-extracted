######################################################################
#
# make_KEIS83.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib $FindBin::Bin;

# KEIS83
require 'KEIS/KEIS83_by_CP932.pl';
require 'CP932/CP932_by_Unicode.pl';
require 'JIS/JISX0208GR_by_CP932.pl';
require 'KEIS/KEIS83_by_Unicode_CultiCoLtd.pl';

if ($0 eq __FILE__) {
    open(DUMP,">$0.dump") || die;
    binmode(DUMP);
    open(DIFF,">$0.diff") || die;
    binmode(DIFF);
}

my %KEIS83_by_Unicode_OVERRIDE = (
    '301C' => 'A1C1',
    'FF5E' => '',
    '5C2D' => 'B6C6',
    '69D9' => 'CBEA',
    '9065' => 'CDDA',
    '7476' => 'E0F6',
    '582F' => 'F4A1',
    '69C7' => 'F4A2',
    '9059' => 'F4A3',
    '7464' => 'F4A4',
    '51DC' => '',
    '7199' => '64B8',
    '2225' => 'A1C2',
    'FF0D' => 'A1DD',
    '2016' => '',
    '2212' => '',
);

my %unicode = map { $_ => 1 } (
    keys_of_CP932_by_Unicode(),
    keys_of_KEIS83_by_Unicode_CultiCoLtd(),
    keys %KEIS83_by_Unicode_OVERRIDE,
);

my %KEIS83_by_Unicode = ();
my %done = ();

for my $unicode (sort { (length($a) <=> length($b)) || ($a cmp $b) } keys %unicode) {
    if (exists($KEIS83_by_Unicode_OVERRIDE{$unicode}) and ($KEIS83_by_Unicode_OVERRIDE{$unicode} eq '')) {
        $done{$KEIS83_by_Unicode_OVERRIDE{$unicode}} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s ", $KEIS83_by_Unicode{$unicode}, $unicode, '----', '----', '----', '----', '----';
printf DUMP "\n";
    }
    elsif (($KEIS83_by_Unicode_OVERRIDE{$unicode} ne '') and not $done{$KEIS83_by_Unicode_OVERRIDE{$unicode}}) {
        $done{$KEIS83_by_Unicode{$unicode} = $KEIS83_by_Unicode_OVERRIDE{$unicode}} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s ", $KEIS83_by_Unicode{$unicode}, $unicode, $KEIS83_by_Unicode{$unicode}, '----', '----', '----', '----';
    }
    elsif ((KEIS83_by_CP932(CP932_by_Unicode($unicode)) ne '') and not $done{KEIS83_by_CP932(CP932_by_Unicode($unicode))}) {
        $done{$KEIS83_by_Unicode{$unicode} = KEIS83_by_CP932(CP932_by_Unicode($unicode))} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s ", $KEIS83_by_Unicode{$unicode}, $unicode, '----', $KEIS83_by_Unicode{$unicode}, '----', '----', '----';
    }
    elsif ((KEIS83_by_Unicode_CultiCoLtd($unicode) ne '') and not $done{KEIS83_by_Unicode_CultiCoLtd($unicode)}) {
        if (0) {
        }
        elsif (
            (JISX0208GR_by_CP932(CP932_by_Unicode($unicode)) ne '') and
            (KEIS83_by_Unicode_CultiCoLtd($unicode)          ne '') and
            (JISX0208GR_by_CP932(CP932_by_Unicode($unicode)) eq KEIS83_by_Unicode_CultiCoLtd($unicode)) and
            not $done{JISX0208GR_by_CP932(CP932_by_Unicode($unicode))}
        ) {
            $done{$KEIS83_by_Unicode{$unicode} = JISX0208GR_by_CP932(CP932_by_Unicode($unicode))} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s ", $KEIS83_by_Unicode{$unicode}, $unicode, '----', '----', $KEIS83_by_Unicode{$unicode}, '----', '----';
        }
        elsif (
            (KEIS83_by_Unicode_CultiCoLtd($unicode)          ne '') and
            (JISX0208GR_by_CP932(CP932_by_Unicode($unicode)) eq '') and
            not $done{KEIS83_by_Unicode_CultiCoLtd($unicode)}
        ) {
            $done{$KEIS83_by_Unicode{$unicode} = KEIS83_by_Unicode_CultiCoLtd($unicode)} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s ", $KEIS83_by_Unicode{$unicode}, $unicode, '----', '----', '----', $KEIS83_by_Unicode{$unicode}, '----';
        }
        elsif (
            (JISX0208GR_by_CP932(CP932_by_Unicode($unicode)) ne '') and
            (KEIS83_by_Unicode_CultiCoLtd($unicode)          eq '') and
            not $done{JISX0208GR_by_CP932(CP932_by_Unicode($unicode))}
        ) {
            $done{$KEIS83_by_Unicode{$unicode} = JISX0208GR_by_CP932(CP932_by_Unicode($unicode))} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s ", $KEIS83_by_Unicode{$unicode}, $unicode, '----', '----', '----', '----', $KEIS83_by_Unicode{$unicode};
        }
        elsif (
            (JISX0208GR_by_CP932(CP932_by_Unicode($unicode)) ne '') and
            (KEIS83_by_Unicode_CultiCoLtd($unicode)          ne '') and
            (JISX0208GR_by_CP932(CP932_by_Unicode($unicode)) ne KEIS83_by_Unicode_CultiCoLtd($unicode)) and
            not $done{JISX0208GR_by_CP932(CP932_by_Unicode($unicode))}
        ) {
die sprintf "Unicode=($unicode), CultiCoLtd=(%s) JISX0208GR=(%s)\n", KEIS83_by_Unicode_CultiCoLtd($unicode), JISX0208GR_by_CP932(CP932_by_Unicode($unicode));
        }
    }

    if ((KEIS83_by_Unicode_CultiCoLtd($unicode) ne '') and (KEIS83_by_CP932(CP932_by_Unicode($unicode)) ne '')) {
        if (KEIS83_by_Unicode_CultiCoLtd($unicode) ne KEIS83_by_CP932(CP932_by_Unicode($unicode))) {
die sprintf "Unicode=($unicode), CultiCoLtd=(%s) Handmade=(%s)\n", KEIS83_by_Unicode_CultiCoLtd($unicode), KEIS83_by_CP932(CP932_by_Unicode($unicode));
        }
    }

printf DUMP "\n" if $KEIS83_by_Unicode{$unicode};

    if (
        ($KEIS83_by_Unicode{$unicode} ne '') and
        (KEIS83_by_Unicode_CultiCoLtd($unicode) ne '') and
        ($KEIS83_by_Unicode{$unicode} ne KEIS83_by_Unicode_CultiCoLtd($unicode)) and
    1) {
        printf DIFF ("[%s] (%s) (%s) (%s)\n",
            (CP932_by_Unicode($unicode) ne '') ? pack('H*',CP932_by_Unicode($unicode)) : (' ' x 2),
            $unicode || (' ' x 4),
            $KEIS83_by_Unicode{$unicode} || (' ' x 4),
            KEIS83_by_Unicode_CultiCoLtd($unicode) || (' ' x 4),
        );
    }
}

close(DUMP);
close(DIFF);

sub KEIS83_by_Unicode {
    my($unicode) = @_;
    return $KEIS83_by_Unicode{$unicode};
}

sub keys_of_KEIS83_by_Unicode {
    return keys %KEIS83_by_Unicode;
}

sub values_of_KEIS83_by_Unicode {
    return values %KEIS83_by_Unicode;
}

1;

__END__
