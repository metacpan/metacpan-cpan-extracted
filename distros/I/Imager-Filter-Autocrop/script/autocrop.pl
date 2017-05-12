#!/usr/bin/env perl
use strict;
use warnings;
use Imager;
use Imager::Filter::Autocrop;
use Getopt::Long;

my $VERSION = '1.23';

binmode(STDOUT, ":encoding(UTF-8)");
if (my $rv = run()) {
    print "$rv\n";
    exit 255;
}
exit 0;

sub run {
    my %opt = ();
    my $args = @ARGV;
    GetOptions (\%opt, 'in=s', 'out=s', 'color=s', 'fuzz=i', 'border=i', 'jpegquality=i', 'detect', 'silent', 'help') || return "Use --help to see available parameters.";
    usage_and_exit() unless ($args and !$opt{'help'});
    my %detect = ();
    print "[#] Imager::Filter::Autocrop v$VERSION\n" unless $opt{silent};
    return "Color is not specified correctly." if (defined $opt{color} and $opt{color}!~/^(#)?[a-fA-f0-9]{3}(?:[a-fA-f0-9]{3})?$/);
    $opt{color} = "#$opt{color}" if (defined $opt{color} and !$1);
    return "Fuzz is not specified correctly." if ($opt{fuzz} and ($opt{fuzz}=~/\D/ or $opt{fuzz} > 255));
    return "Border is not specified correctly." if ($opt{border} and $opt{border}=~/\D/);
    return "JPEG quality is not specified correctly." if ($opt{jpegquality} and ($opt{jpegquality}=~/\D/ or $opt{jpegquality} > 100));
    return "Source image should be specified." unless $opt{in};
    return "Source image is not readable." unless (-f $opt{in} and -r _);
    return "Output image name should be specified." if (!$opt{out} and !$opt{detect});
    print "Processing image '$opt{in}' - " . ($opt{detect} ? "detecting" : "cropping") . ".\n" unless $opt{silent};
    print "Using color " . ($opt{color} ? uc("'$opt{color}'") : "from top left corner.") . ($opt{fuzz} ? " Fuzz: $opt{fuzz}." : "") . ($opt{border} ? " Border: $opt{border}." : "") . "\n" unless $opt{silent};
    
    my $img = Imager->new();
    $img->read(file => $opt{in}) or return $img->errstr;
    my %runtime = ();
    $runtime{detect} = \%detect if $opt{detect};
    foreach (qw<color fuzz border>) {
        $runtime{$_} = $opt{$_} if $opt{$_};
    }
    $img->filter(type => 'autocrop', %runtime) or return $img->errstr;
    if ($opt{detect}) {
        print join(", ", map { "$_: " . $detect{$_}||'unknown' } qw<top left bottom right>), "\n";
    } else {
        %runtime = ();
        foreach (qw<jpegquality>) {
            $runtime{$_} = $opt{$_} if $opt{$_};
        }
        $img->write(file => $opt{out}, %runtime) or return $img->errstr;
    }
    return;
}

sub usage_and_exit {
    local $/;
    print <DATA>;
    exit(1);
}

__END__

 ==============================
 Imager::Filter::Autocrop v1.23
 ==============================

 in <file>                        - File to be processed.
 out <file>                       - Name for the resulting file, if running without --detect parameter.
 detect                           - Detection-only mode (no actual cropping takes place).
 color <#XXYYZZ|#XYZ>             - Color to be treated as the background color. Optional, color of the top left pixel will be used if not given.
 fuzz <amount>                    - Color deviation to define range that will be treated as matching the background (0-255). Optional.
 border <pixels>                  - Pixels to be left around the detected area. Optional.
 jpegquality <amount>             - Quality of jpeg output (0 - 100, by default 75). Optional.
 silent                           - Suppress non-error messages.
 help                             - This screen.

