#!/usr/bin/env perl
# Last modified: Tue Sep 02 2025 01:16:34 PM -04:00 [EDT]
# First created: Wed Aug 06 2025 01:25:55 PM -04:00 [EDT]

package Env::Scalars::scalars2yaml;
use strict;
use v5.18;
use utf8;
use warnings;
our $VERSION = '0.35';
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(s2yaml);

=head1 SYNOPSIS

=cut

    sub s2yaml {
        my @accepted =
        grep {
                 not $_ eq "PERL5LIB"     and
                 not $_ eq "_"            and
                 not $_ eq "!::"          and
                 not $_ eq "PWD"          and
                 not /^XDG_[A-Z]+_DIRS$/  and
                 not /[_A-Z0-9]*PATH$/
        } sort keys %ENV;

        my @items =  map { sprintf( '%s: %s' , $_ , $ENV{$_} ) }
                        @accepted;
        return \@items;
    }

1;
__END__

# vim: ft=perl et sw=4 ts=4 :
