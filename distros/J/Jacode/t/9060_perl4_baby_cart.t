######################################################################
#
# t/9060_perl4_baby_cart.t - guard perl 4.036 compatibility of jacode.pl
#
# jacode.pl is the runtime engine and must parse on perl 4.036 through
# current perl 5 (it is the replacement for the original jcode.pl). The
# "baby cart" construct @{[ ... ]} depends on references and is perl 5
# only, so it cannot appear in the compiled (pre-__END__) part of the
# file or the file would fail to compile on perl 4.
#
# This is a static guard: it scans the source text, not the running
# behaviour, so it works even on a modern perl where the file loads fine.
# POD (after __END__) is not scanned because it is not compiled.
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }
use warnings;
use FindBin;

my $path = "$FindBin::Bin/../lib/jacode.pl";

# Read only the compiled part of the file (everything before __END__).
# That is the region perl 4.036 must be able to parse.
my @code = ();
{
    local *FH;
    open(FH, $path) or die "Cannot open $path: $!";
    while (<FH>) {
        last if /^__END__\b/;
        push @code, $_;
    }
    close(FH);
}

# Locate every line that contains the baby-cart @{[ ... ]} idiom.
my @baby_cart = ();
my $lineno = 0;
for my $line (@code) {
    $lineno++;
    push @baby_cart, $lineno if $line =~ /\@\{\[/;
}

my $tno = 0;
sub ok {
    my ($pass, $name) = @_;
    $tno++;
    print $pass ? "ok $tno" : "not ok $tno";
    print " - $name" if defined $name;
    print "\n";
}

my @tests = (

    # The compiled part of jacode.pl must contain no @{[ ... ]} baby cart,
    # which is a perl 5 only (reference-dependent) construct.
    sub {
        ok(
            scalar(@baby_cart) == 0,
            (@baby_cart == 0)
                ? "no perl 5 only baby-cart \@{[ ]} in compiled part of jacode.pl"
                : "baby-cart \@{[ ]} found at line(s): " . join(', ', @baby_cart)
        );
    },

    # Sanity: we actually read some code (guards against an empty/missing
    # file silently passing the check above).
    sub {
        ok(
            scalar(@code) > 100,
            "read the compiled part of jacode.pl (" . scalar(@code) . " lines)"
        );
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

__END__
