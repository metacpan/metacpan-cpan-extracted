#!/usr/bin/perl

package Goo::Thing::gml::Reader;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:   	Nigel Hamilton
# Filename: 	Goo::Thing::gml::Reader.pm
# Description:  Read a Goo Markup page
#
# Date      	Change
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
# read - slurp in a file and parse it
#
###############################################################################

sub read {

    my ($filename) = @_;

    #	print "$filename \n";

    # slurp mode
    my $data;

    # a hash of stuff
    my $thing = {};

    eval { $data = Goo::FileUtilities::get_file_as_string($filename); };

    # nothing found! bailout now
    if ($@) { return $thing; }

    # parse here!
    while ($data =~ m|<([^>]*)>(.*?)</\1>|gs) {

        my $field = $1;
        my $value = $2;

        # compress all objects except for emailtemplates
        #if (($value =~ /<[^>]*>/) && ($type ne "emailtemplate")) {
        #        # compress the object, save RAM and gain speed - strip leading whitespace
        #        CompressWhitespace::compress_html(\$value);
        #
        #}

        # print "$value";
        # a hash of a hash of a hash - wow
        if ($value =~ /\|\|/) {
            my @values = split(/\|\|/, $value);

            # this is an array of stuff
            $thing->{$field} = \@values;
        } else {
            $thing->{$field} = $value;
        }

    }

    return $thing;

}


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

Goo::Thing::gml::Reader - Read a Goo Markup Language (GML) Thing

=head1 SYNOPSIS

use Goo::Thing::gml::Reader;

=head1 DESCRIPTION



=head1 METHODS

=over

=item read

slurp in a file and parse it

=item write

write a hash to disk

=item stringify_hash

turn a hash into a string


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

