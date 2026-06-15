######################################################################
#
# t/9030_no_apostrophe_warning.t - clean warning behavior at load time
#
# jacode.pl intentionally uses the old "'" package separator so that it
# keeps running on Perl 4.036 / 5.005_03. On Perl 5.38.0 and later that
# separator triggers an "Old package separator" deprecation warning,
# which jacode.pl suppresses internally with a version-gated __WARN__
# filter (installed before, and removed after, the apostrophe code is
# compiled).
#
# This test asserts:
#   1) requiring and initializing jacode.pl emits no OTHER class of
#      warning - a regression guard against an accidental Perl-5-ism
#      (e.g. a new deprecation) slipping into the source, and
#   2) on Perl 5.38.0+ the apostrophe-separator warning does not leak,
#      i.e. the internal filter is doing its job.
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

# Capture every warning emitted while jacode.pl is compiled and
# initialized. jacode.pl's own __WARN__ filter saves this handler on
# entry, drops only the apostrophe-separator message, chains anything
# else back here, and restores this handler before require() returns.
my @warns = ();
{
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    require "$FindBin::Bin/../lib/jacode.pl";
    jacode::init();
}

my @separator = grep {  /Old package separator/ } @warns;
my @other     = grep { !/Old package separator/ } @warns;

my $tno = 0;
sub ok {
    my ($pass, $name) = @_;
    $tno++;
    print $pass ? "ok $tno" : "not ok $tno";
    print " - $name" if defined $name;
    print "\n";
}

sub oneline {
    my $s = shift;
    $s = '' unless defined $s;
    $s =~ s/[\r\n]+/ /g;
    return $s;
}

my @tests = (

    # 1) No warning class other than the apostrophe separator may appear.
    sub {
        ok(
            scalar(@other) == 0,
            (@other == 0)
                ? "no unexpected warning class during require/init"
                : "unexpected warning: " . oneline($other[0])
        );
    },

    # 2) On Perl 5.38.0+ the apostrophe-separator warning must be
    #    suppressed by jacode.pl's internal filter. Older perls never
    #    emit it, so there is nothing to suppress.
    sub {
        if ($] < 5.038000) {
            ok(1, "apostrophe-separator warning not emitted by perl $] (n/a)");
        }
        else {
            ok(
                scalar(@separator) == 0,
                (@separator == 0)
                    ? "apostrophe-separator deprecation suppressed on perl $]"
                    : "apostrophe-separator warning leaked (" . scalar(@separator) . ")"
            );
        }
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

__END__
