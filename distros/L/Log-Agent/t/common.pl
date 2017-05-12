#!perl
###########################################################################
#
#   common.pl
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

sub contains ($$) {
    my ($file, $pattern) = @_;
    $pattern = qr{$pattern};
    local *FILE;
    local $_;
    open(FILE, $file) || die "can't open $file: $!\n";
    my $found = 0;
    my $line = 0;
    while (<FILE>) {
        s/[\n\r]//sg;
        $line++;
        if (/$pattern/) {
            $found = 1;
            last;
        }
    }
    close FILE;
    return $found ? $line : 0;
}

sub perm_ok ($$) {
    #
    # Given a fileame and target permissions, checks if the file
    # was created with the correct permissions.
    #
    my($file, $target) = @_;

    $target &= ~ umask;         # account for user mask
    my $mode = (stat $file)[2]; # find the current mode
    $mode &= 0777;              # we only care about UGO

    return $mode == $target;
}

1;
