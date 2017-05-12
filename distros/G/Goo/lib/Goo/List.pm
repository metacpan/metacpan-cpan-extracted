package Goo::List;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::List.pm
# Description:  Utility functions for handling lists
#
# Date          Change
# -----------------------------------------------------------------------------
# 27/01/2005    Auto generated file
# 27/01/2005    Initially needed a way to split lists
#
###############################################################################

use strict;


###############################################################################
#
# get_unique - return a sorted unique list
#
###############################################################################

sub get_unique {

    my (@list) = @_;

    my $seen;

    foreach my $member (@list) {
        $seen->{$member} = 1;
    }

    return sort { $a cmp $b } keys %$seen;

}


###############################################################################
#
# halve_list - split a list in two
#
###############################################################################

sub halve_list {

    my (@list) = @_;

    my $halfway = scalar(@list)/2;

    my @list1;
    my @list2;

    for (my $i = 0; $i <= $#list; $i++) {

        if ($i >= $halfway) {
            push(@list2, $list[$i]);
        } else {
            push(@list1, $list[$i]);
        }

    }

    return (\@list1, \@list2);
}


###############################################################################
#
# quarter_list - split a list in four!
#
###############################################################################

sub quarter_list {

    my (@list) = @_;

    my ($a, $b) = halve_list(@list);

    my ($list1, $list2) = halve_list(@$a);

    my ($list3, $list4) = halve_list(@$b);

    return ($list1, $list2, $list3, $list4);

}


1;


__END__

=head1 NAME

Goo::List - Utility functions for handling lists

=head1 SYNOPSIS

use Goo::List;

=head1 DESCRIPTION

=head1 METHODS

=over

=item get_unique

return a sorted unique list

=item halve_list

return a list split in two

=item quarter_list

return a list split in four

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

