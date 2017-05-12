#! /usr/local/bin/perl -w
# rainbow.pl - example script for HTML::Rainbow
#
# a simple filter that allows some of the HTML::Rainbow
# parameters to be set. Accepts input on STDIN and writes
# to STDOUT.
#
# Copyright (C) David Landgren 2005 

use strict;
use HTML::Rainbow;
use Getopt::Simple;

use vars '$VERSION';
$VERSION = '0.1';

getopt('rgbxn', \my %opt);

my %param;
$param{min}   = $opt{n} if $opt{n};
$param{max}   = $opt{x} if $opt{x};
$param{red}   = $opt{r} if $opt{r};
$param{green} = $opt{g} if $opt{g};
$param{blue}  = $opt{b} if $opt{b};

print HTML::Rainbow->new(%param)->rainbow( <STDIN> ), "\n";

=head1 NAME

rainbow - Simple rainbow filter

=head1 SYNOPSIS

B<rainbow> [B<-rgbxn>] E<lt>input

=head1 DESCRIPTION

Filter input through rainbow function.

=head1 OPTIONS

=over 5

=item B<-r>, B<-g>, B<-b>

Set the R, G and/or B components to a fixed value.

=item B<-n>

Set the minimum value for all three components.

=item B<-x>

Set the maximum value for all three components.

=back

=head1 SEE ALSO

L<HTML::Rainbow>

=head1 AUTHOR

David Landgren.

Copyright 2005 David Landgren. All rights reserved.

=head1 LICENSE

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
