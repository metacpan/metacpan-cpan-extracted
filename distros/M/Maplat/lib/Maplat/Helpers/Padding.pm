# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::Padding;
use strict;
use warnings;

use 5.008000;

use base qw(Exporter);
our @EXPORT_OK = qw(doFPad doSpacePad trim);

our $VERSION = 0.995;

sub doFPad {
    my ($val, $len) = @_;
    while(length($val) < $len) {
        $val = "0$val";
    }
    return $val;
}

sub doSpacePad {
    my ($val, $len) = @_;
    while(length($val) < $len) {
        $val = "$val ";
    }
    return $val;    
}

sub trim
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

1;
__END__

=head1 NAME

Maplat::Helpers::Padding - string padding/trimming helpers

=head1 SYNOPSIS

  use Maplat::Helpers::Padding qw(doFPad doSpacePad trim);
  
  # front pad string with zeroes
  my $padded = doFPad("100", 10);

  # pad string with spaces
  my $padded = doSpacePad("Hello World", 20);

  # trim start and end whitespace
  my $trimmed = trim(" Hello, world!     ");

=head1 DESCRIPTION

This module provides a few string padding and trimming helpers, used
throughout the MAPLAT framework.

=head2 doFPad

Takes two arguments, $text and $length and returns the padded string.

$text is the string to be padded to the desired $length with zeroes in front.

  my $padded = doFPad("100", 5); # returns "00100"

=head2 doSpacePad

Takes two arguments, $text and $length and returns the padded string.

$text is the string to be padded to the desired $length with spaces at the end.

  my $padded = doSpacePad("100", 5); # returns "100  "

=head2 trim

Takes one argument, the string to be trimmed. Returns the string with whitespace remoned from
start and end of that string.

  my $trimmed = trim("  test  "); # returns "test"

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
