package Goo::Thing::pm::MethodMatcher;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::pm::MethodMatcher.pm
# Description:  Match a method in a string
#
# Date          Change
# -----------------------------------------------------------------------------
# 17/08/2005    Auto generated file
# 17/08/2005    Started to do this in multiple places
# 26/10/2005    Added method: getScope
#
###############################################################################

use strict;

use Goo::TextUtilities;

# return the method position plus 5
# sp we target the middle of the method
my $offset = 5;


###############################################################################
#
# get_line_number - return the line of the file that matches the method
#
###############################################################################

sub get_line_number {

    my ($method_name, $string) = @_;

    my $pattern;

    # need to jump to the method of this Thing
    if ($method_name eq "main") {
        $pattern = qr/^use\s+strict/;
    } else {
        $pattern = qr/^sub\s+$method_name/;
    }

    # textutilities - to match the pattern, then find the line, then jump
    my $matching_line_number = Goo::TextUtilities::get_matching_line_number($pattern, $string);

    return $matching_line_number + $offset;

}

1;


__END__

=head1 NAME

Goo::Thing::pm::MethodMatcher - Match a method in a string

=head1 SYNOPSIS

use Goo::Thing::pm::MethodMatcher;

=head1 DESCRIPTION



=head1 METHODS

=over

=item get_line_number

return the line of the file that matches the method


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

