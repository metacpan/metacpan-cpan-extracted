#!/usr/bin/perl

package Goo::Object;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2002
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Object.pm
# Description:  Super object that holds convenience methods.
#               All objects that inherit from this are hash-based.
#
# Date          Change
# ----------------------------------------------------------------------------
# 27/05/02      Version 1 - used for debugging
#               Added Clone method - needed for mod_perl persistent environment
# 24/07/04      DataDumper was hanging around - removed in case of RAM consumption!
#
##############################################################################

use strict;

##############################################################################
#
# new - instantiate an object
#
##############################################################################

sub new {

    my ($class) = @_;

    my $this = {};

    bless( $this, $class );

}

##############################################################################
#
# add_fields - add fields to this object
#
##############################################################################

sub add_fields {

    my ( $this, $fields ) = @_;

    if ( ref($fields) eq "HASH" ) {
        %$this = ( %$this, %$fields );
    }

}

##############################################################################
#
# has - return whether or not an attribute is defined for this object?
#
##############################################################################

sub has {

    my ( $this, $attribute ) = @_;

    return exists( $this->{$attribute} );

}

##############################################################################
#
# get_type - return the type of this object
#
##############################################################################

sub get_type {

    my ($this) = @_;

    return ref($this);

}

##############################################################################
#
# to_string - return a string representation of this class
#
##############################################################################

sub to_string {

    my ($this) = @_;

    my $string = "[" . ref($this) . "]";

    foreach my $key ( keys %$this ) {
        $string .= " $key = $this->{$key} |";

    }

    return $string . "\n\n";

}

##############################################################################
#
# to_htmlstring - return a html representation of this class
#
##############################################################################

sub to_htmlstring {

    my ($this) = @_;

    my $string =
        "<p><table width='95%' border ='1'><tr><td colspan = '2'>"
      . ref($this)
      . "</td><td></td></tr>";

    foreach my $key ( keys %$this ) {

        $this->{$key} =~ s/\</&lt;/g;
        $this->{$key} =~ s/\>/&gt;/g;
        $string .= "<tr><td>$key</td><td>$this->{$key}</td></tr>";

    }

    return $string . "</table>";

}

1;

__END__

=head1 NAME

Goo::Object - Super object that holds convenience methods.

=head1 SYNOPSIS

use Goo::Object;

=head1 DESCRIPTION


=head1 METHODS

=over

=item new

instantiate an object

=item add_fields

add fields to this object

=item has

return whether or not an attribute is defined for this object?

=item get_type

return the type of this object

=item to_string

return a string representation of this object

=item to_htmlstring

return a HTML representation of this object

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

