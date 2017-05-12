package Goo::Differ;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Differ.pm
# Description:  Take the diff!
#
# Date          Change
# -----------------------------------------------------------------------------
# 09/05/2005    Auto generated file
# 09/05/2005    Need to remember the difference between two files
#
###############################################################################

use strict;

use Goo::Object;
use base qw(Goo::Object);


###############################################################################
#
# diff - return those lines that have changed since list1
#
###############################################################################

sub diff {

    my ($this, $list1, $list2) = @_;

    my %list1_member = map { $_ => 1; } @$list1;

    my $linecount = 0;

    foreach my $line (@$list2) {

        $linecount++;

        if (not exists $list1_member{$line}) {
            $this->{lines}->{$linecount} = $line;
        }

    }

}


###############################################################################
#
# get_line_numbers - return the line numbers that are new or different
#
###############################################################################

sub get_line_numbers {

    my ($this) = @_;

    return keys %{ $this->{lines} };

}


###############################################################################
#
# get_line - return the line found at
#
###############################################################################

sub get_line {

    my ($this, $line_number) = @_;

    return $this->{lines}->{$line_number};

}


1;


__END__

=head1 NAME

Goo::Differ - Take the diff!

=head1 SYNOPSIS

use Goo::Differ;

=head1 DESCRIPTION


=head1 METHODS

=over

=item diff

return those lines that have changed

=item get_line_numbers

return the line numbers that are new or different

=item get_line

return the line found at a given line number

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

