package Goo::TextTable;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::TextTable.pm
# Description:  Create a simple fixed-width text table
#
# Date          Change
# -----------------------------------------------------------------------------
# 08/11/2005    Created test file: TextTableTest.tpm
#
###############################################################################

use strict;

use Goo::Object;
use Text::FormatTable;

use base qw(Goo::Object);


###############################################################################
#
# add_row - add a row to the table
#
###############################################################################

sub add_row {

    my ($this, @columns) = @_;

    unless ($this->{rows}) {

        # store an array
        $this->{rows} = ();
    }

    # remember the maximum column count
    if (scalar(@columns) > $this->{column_count}) {
        $this->{column_count} = scalar(@columns);
    }

    # for each column remember the maximum width
    foreach my $column (1 .. scalar(@columns)) {

        # work out the width of this column
        my $column_width = length($columns[ $column - 1 ]);

        # unless there is a max column length aleady - record one
        unless (exists $this->{max_width}->{$column}) {
            $this->{max_width}->{$column} = $column_width;
            next;
        }

        # otherwise check if it exceeds the current maximum?
        if ($column_width > $this->{max_width}->{$column}) {

            # remember it
            $this->{max_width}->{$column} = $column_width;
        }

    }

    # push the columns onto the rows
    push(@{ $this->{rows} }, \@columns);

}


###############################################################################
#
# render - return a table
#
###############################################################################

sub render {

    my ($this, $justified) = @_;

    # justified left, right or centered
    $justified = $justified || "l";

    my $format = "";

    # contruct a format for each column
    foreach my $column (1 .. $this->{column_count}) {

        $format .= "$this->{max_width}->{$column}l ";

    }

    my $table = Text::FormatTable->new($format);

    # go through each row in the table
    foreach my $row (@{ $this->{rows} }) {

        # we need to pad out the row if needs be
        $table->row(@$row);
    }

    return $table->render();

}


1;


__END__

=head1 NAME

Goo::TextTable - Create a simple fixed-width text table

=head1 SYNOPSIS

use Goo::TextTable;

=head1 DESCRIPTION


=head1 METHODS

=over

=item add_row

add a row to the table

=item render

return a text table

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

