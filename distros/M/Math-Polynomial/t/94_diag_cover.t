# Copyright (c) 2009 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 94_diag_cover.t 36 2009-06-08 11:51:03Z demetri $

# Checking whether all error messages are covered in the DIAGNOSTICS
# pod section.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/94_diag_cover.t'

use 5.006;
use strict;
use warnings;
use Test;
use lib "t/lib";
use Test::MyUtils;
use Math::Polynomial 1.000;

maintainer_only();

my $mp_file = $INC{'Math/Polynomial.pm'};
if (!defined $mp_file) {
    die "could not figure out module location";
}
my $mp_text = Test::MyUtils::slurp_or_bail($mp_file);

plan tests => 5;

print "# parsing file $mp_file\n";

my %in_code = ();       # croak messages as found in code
my @in_pod  = ();       # diagnostics items found in pod
my $msg_count = 0;

while ($mp_text =~ /\bcroak ['"]([^'"]*)['"]/g) {
    ++ $in_code{$1};
    ++ $msg_count;
}
if ($mp_text =~ /^(=head1 DIAGNOSTICS\b.*?)^=head1/ms) {
    my $diag = $1;
    while ($diag =~ /^=item (.*)/mg) {
        my $msg = $1;
        $msg =~ s/E<lt>/</g;
        $msg =~ s/E<gt>/>/g;
        push @in_pod, $msg;
    }
}

print "# found $msg_count croak calls, ", scalar(keys %in_code), " distinct\n";
ok($msg_count);
print "# found ", scalar(@in_pod), " documented message types\n";
ok(scalar @in_pod);

my $prev = '';
my $sorted = 1;
my @patterns = ();
my $WILDCARD = quotemeta quotemeta '%s';
foreach my $msg (@in_pod) {
    $sorted &&= $prev lt $msg;
    $prev = $msg;
    my $pat = quotemeta $msg;
    $pat =~ s/$WILDCARD/'.*'/geo;
    push @patterns, qr/^$pat\z/;
}
ok($sorted);

my $covered_pat = join '|', @patterns;
my $covered = 1;
foreach my $msg (sort keys %in_code) {
    if ($msg !~ /$covered_pat/os) {
        $covered = 0;
        print "# msg not covered: $msg\n";
    }
}
ok($covered);

my $hit = 1;
foreach my $i (0..$#in_pod) {
    my ($msg, $pat) = ($in_pod[$i], $patterns[$i]);
    if (!grep /$pat/, keys %in_code) {
        print "# msg not in code: $msg\n";
        $hit = 0;
    }
}
ok($hit);

__END__
