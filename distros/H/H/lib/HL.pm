package HL;
use strict;
use warnings;

our $VERSION = '0.001';

our $AUTOLOAD;

sub AUTOLOAD {
    my ($in, @args) = @_;
    my $meth = $AUTOLOAD;
    $meth =~ s/^.*:://g;

    my @got = $in->$meth(@args ? @args : ());
    return unless @got;
    return ($meth => $got[-1]);
}

1;
