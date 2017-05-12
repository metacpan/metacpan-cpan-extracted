package Goo::Header;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Header.pm
# Description:  Show a consistent style of text header for the GOO
#
# Date          Change
# -----------------------------------------------------------------------------
# 10/10/2005    Added method: showDetailedHeader
#
###############################################################################

use strict;
use Goo::Prompter;


###############################################################################
#
# show - show a  the header in detail
#
###############################################################################

sub show {

    my ($action, $filename, $location) = @_;

    Goo::Prompter::clear();
    Goo::Prompter::say("");
    Goo::Prompter::yell("The Goo - $action - $filename [$location]");

}

1;


__END__

=head1 NAME

Goo::Header - Show a consistent style of text header for The Goo

=head1 SYNOPSIS

use Goo::Header;

=head1 DESCRIPTION



=head1 METHODS

=over

=item show

show a consistent header at the top of the screen

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

