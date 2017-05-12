#!/usr/bin/perl

package Goo::TabConverter;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::TabConverter.pm
# Description:  Convert tab characters to four spaces
#
# Date          Change
# -----------------------------------------------------------------------------
# 27/09/2005    Version 1
# 15/10/2005    Created test file: TabConverterTest.tpm
#
###############################################################################

use strict;

#use Smart::Comments;
my $default_tab_size = 4;

###############################################################################
#
# tabs_to_spaces - turn any tabs into the right number of characters
#
###############################################################################

sub tabs_to_spaces {

    my ($line, $tab_size) = @_;

    $tab_size = $tab_size || $default_tab_size;

    my $tab_count = 0;

    my $new_line;

    foreach my $character (split(//, $line)) {

        ### is this a tab char
        if ($character =~ /\t/) {

            ### replace the tab with the number of space up to the next tab stop
            $character = ' ' x ($tab_size - $tab_count);

            ### we've now filled up a complete tab stop
            $tab_count = $tab_size;

        }

        ### increment the tab_count
        $tab_count++;

        if ($tab_count >= $tab_size) {
            $tab_count = 0;
        }

        ### append the character to the line
        $new_line .= $character;

    }

    return $new_line;

}

1;


__END__

=head1 NAME

Goo::TabConverter - Convert tab characters to four spaces

=head1 SYNOPSIS

use Goo::TabConverter;

=head1 DESCRIPTION

=head1 METHODS

=over

=item tabs_to_spaces

turn any tabs into n characters

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

