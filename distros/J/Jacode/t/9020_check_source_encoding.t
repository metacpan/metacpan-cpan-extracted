######################################################################
#
# t/9020_check_source_encoding.t - verify source file encodings
#
# jacode.pl must be UTF-8 (verified at its own runtime too).
# All other hand-edited source files must be US-ASCII or UTF-8.
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }
use warnings;
use FindBin;

my $dist_root = "$FindBin::Bin/..";

# Hand-edited files that must be UTF-8 encoded
my @utf8_files = qw(
    lib/jacode.pl
    lib/Jacode.pm
    SECURITY.md
    CONTRIBUTING
    README
    README2ND
    Changes
);

# Hand-edited test files (this file itself and other t/9*.t) must be UTF-8
push @utf8_files, map { "t/$_" } grep { /^9\d\d\d/ } do {
    local *DH;
    opendir(DH, "$dist_root/t") or die "Cannot opendir t/: $!";
    my @f = readdir(DH);
    closedir(DH);
    sort @f;
};

print "1..", scalar(@utf8_files), "\n";
my $tno = 1;

for my $relpath (@utf8_files) {
    my $path = "$dist_root/$relpath";
    unless (-f $path) {
        print "ok $tno - $relpath (skip: not found)\n";
        $tno++;
        next;
    }

    open(FH, $path) or do {
        print "not ok $tno - $relpath (cannot open: $!)\n";
        $tno++;
        next;
    };
    binmode(FH);
    my $content = do { local $/; <FH> };
    close(FH);

    # Validate UTF-8: no invalid byte sequences.
    # A simple heuristic: after stripping valid UTF-8 multibyte sequences
    # and ASCII, no bytes above 0x7f should remain.
    (my $stripped = $content) =~ s/
        [\xc2-\xdf][\x80-\xbf]                             |
        [\xe0-\xe0][\xa0-\xbf][\x80-\xbf]                  |
        [\xe1-\xec][\x80-\xbf][\x80-\xbf]                  |
        [\xed-\xed][\x80-\x9f][\x80-\xbf]                  |
        [\xee-\xef][\x80-\xbf][\x80-\xbf]                  |
        [\xf0-\xf0][\x90-\xbf][\x80-\xbf][\x80-\xbf]       |
        [\xf1-\xf3][\x80-\xbf][\x80-\xbf][\x80-\xbf]       |
        [\xf4-\xf4][\x80-\x8f][\x80-\xbf][\x80-\xbf]       |
        [\x00-\x7f]
    //gx;

    if ($stripped eq '') {
        print "ok $tno - $relpath is valid UTF-8\n";
    } else {
        my $bad = join(' ', map { sprintf('\\x%02x', ord($_)) } split //, substr($stripped, 0, 4));
        print "not ok $tno - $relpath contains invalid UTF-8 bytes: $bad\n";
    }
    $tno++;
}

__END__
