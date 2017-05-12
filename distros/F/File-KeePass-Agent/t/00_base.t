#!/usr/bin/perl

=head1 NAME

00_base.t - Check basic functionality of File::KeePass::Agent

=cut

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    my @OS = qw(
                linux
                unix
               );

    my $os = lc $^O;
    if (! grep {$_ eq $os} @OS) {
        SKIP: {
            skip("OS $os - not supported at this time",1);
        };
        exit;
    }

    use_ok('File::KeePass::Agent');
}
