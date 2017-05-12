package Exporter::Constants;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.03';

use Exporter;
use parent qw/Exporter/;

sub import {
    my $class = shift;
    my $pkg = caller(0);

    while (@_) {
        my ($array, $stuff) = splice @_, 0, 2;
        _declare_constant($pkg, $array, $stuff);
    }
}

sub _declare_constant {
    my ($pkg, $array, $stuff) = @_;

    no strict 'refs';
    while (my ($k, $v) = each %$stuff) {
        *{"$pkg\::$k"} = sub () { $v };
        unshift @$array, $k;
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Exporter::Constants - Declare constants and export it.

=head1 SYNOPSIS

    package My::Constants;
    # declare constants and push to @EXPORT
    use parent qw/Exporter/;
    our @EXPORT;
    our @EXPORT_OK;

    use Exporter::Constants (
        \@EXPORT => {
            'TYPE_A' => 4649,
            'TYPE_B' => 5963
        },
        \@EXPORT_OK => {
            'TYPE_C' => 1919,
            'TYPE_D' => 0721
        }
    );

    package main;
    use My::Constants;

    # constants are exported.
    print TYPE_A, "\n";

=head1 DESCRIPTION

This module help to declare & export constants.

=head1 MOTIVATION

I want to declare My::Own::Constants package when writing applications.
These class declares constants and export to other application classes.

I can do this task by Exporter.pm and constants.pm. But I want to do it at once.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
