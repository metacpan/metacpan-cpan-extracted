package lf_out_test;
use strict;
use warnings;
use Test::More;
use base qw(Exporter);

our $Output;
our @EXPORT = qw($Output logtester);

sub logtester {
    my $msg = shift;
    note $msg;
    $Output = $msg;
}
1;
