# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::Strings;
use strict;
use warnings;

use 5.008000;

use base qw(Exporter);
use Maplat::Helpers::Padding qw(doSpacePad);
our @EXPORT_OK = qw(tabsToTable normalizeString);

our $VERSION = 0.995;

sub tabsToTable {
    my ($txt, @lengths) = @_;
    
    my @parts = split/\t/, $txt;
    my $newtext = "";
    foreach my $part (@parts) {
        my $len = shift @lengths || 5;
        $newtext .= doSpacePad($part, $len);
    }
    return $newtext;
}

# Removes all unneeded whitespace and non-word characters
sub normalizeString {
    my $val = shift;
    
    $val =~ s/^\s+//o;
    $val =~ s/\s+$//o;
    $val =~ s/\s+/\ /go;
    $val =~ s/[^\w\s]//go;
    
    return $val;
}

1;

=head1 NAME

Maplat::Helpers::Strings - special string handling functions

=head1 SYNOPSIS

  use Maplat::Helpers::Strings qw(tabsToTable normalizeString);
  
  my $tableline = tabsToTable($text, @lengths);
  my $newstring = normalizeString($text);

=head1 DESCRIPTION

This module is home to some specialized functions for modifying strings. Most people wont need this
but i find them rather helpfull in some cases.

=head2 tabsToTable

This function turns a tab delimated text string into a space-padded line suitable for printing ascii-art tables.

Takes two arguments, a $textstring with multiple fields delimated by tabs, and an array with field lengths. The second
argument is an array of desired field lengths.

Example:

  my @length = (5, 8, 7);
  my @spies = ("007\tBond\tJames", "008\tDoe\tJohn");
  ...
  foreach my $spy (@spies) {
    print tabsToTable($spy);
  }

Prints out:

  007  Bond    James
  008  Doe     John

=head2 normalizeString

Removed unneeded whitespaces as well as all other non-word characters from a string.

Takes one argument, a text string and returns a "normalized" version of this string.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;
