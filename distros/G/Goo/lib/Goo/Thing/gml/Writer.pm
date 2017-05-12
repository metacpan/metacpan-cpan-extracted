#!/usr/bin/perl

package Goo::Thing::gml::Writer;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::gml::Writer.pm
# Description:  Goo Markup Language
#
# Date          Change
# -----------------------------------------------------------------------------
# 27/06/2005    Auto generated file
# 27/06/2005    Not quite XML - need to read and write Goo XML
#
###############################################################################

use strict;

use Goo::FileUtilities;
use Goo::CompressWhitespace;


###############################################################################
#
# write - write a hash to disk
#
###############################################################################

sub write {

    my ($thing, $filename) = @_;

    Goo::FileUtilities::write_file($filename, stringify_hash($thing));

}


###############################################################################
#
# stringify_hash - turn a hash into a string
#
###############################################################################

sub stringify_hash {

    my ($hash) = @_;

    my $string;

    foreach my $field (keys %$hash) {

        my $value = $hash->{$field};

        if (ref($value) eq "ARRAY") {
            $value = join("||", @{ $hash->{$field} });
            $value =~ s/\s+$//g;
            $value =~ s/^\s+//g;
        }

        next unless ($field && $value);

        # watch out for embedded hashes
        next if ($value =~ /^HASH/);


        $string .= "<$field>$value</$field>\n";

    }

    return $string;

}

1;



__END__

=head1 NAME

Goo::Thing::gml::Writer - Write a Goo Markup Language (GML) Thing

=head1 SYNOPSIS

use Goo::Thing::gml::Writer;

=head1 DESCRIPTION



=head1 METHODS

=over

=item write

write a hash to disk

=item stringify_hash

turn a hash into a string


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

