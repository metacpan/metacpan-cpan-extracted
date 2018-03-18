package HS;
use strict;
use warnings;

our $VERSION = '0.001';

our $AUTOLOAD;

sub AUTOLOAD {
    my ($in, @args) = @_;
    my $meth = $AUTOLOAD;
    $meth =~ s/^.*:://g;

    my $val = $in->$meth(@args ? @args : ());
    return ($meth => $val);
}

1;
