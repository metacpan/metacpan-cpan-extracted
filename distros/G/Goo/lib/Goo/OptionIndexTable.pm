package Goo::OptionIndexTable;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::OptionIndexTable.pm
# Description:  Take a hash of of options and turn into a table of text
#
# Date          Change
# -----------------------------------------------------------------------------
# 05/10/2005    Auto generated file
# 05/10/2005    Need to clean up the interfaces and make it simple
#
###############################################################################

use strict;
use Goo::Prompter;
use Text::FormatTable;


###############################################################################
#
# make - constructor
#
###############################################################################

sub make {

    my ($title, $number_of_columns, $index) = @_;

    my $table;

    if ($number_of_columns == 4) {
        $table = Text::FormatTable->new('4l 20l 4l 20l 4l 20l 4l 20l');
        $table->head('', $title, '', '', '', '', '', '');
        $table->rule('-');
    } else {
        $table = Text::FormatTable->new('4l 100l');
        $table->head('', $title, '', '', '', '', '', '');
        $table->rule('-');
    }

    my @options = sort { $a cmp $b || $a <=> $b } keys %$index;

    # how many rows do we need?
    my $number_of_rows = scalar(@options) / $number_of_columns;

    # is there a remainder? - round it up
    if ($number_of_rows =~ /(\d+)\./) {
        $number_of_rows = $1;
        $number_of_rows++;
    }

    # add a row at a time
    foreach my $row (1 .. $number_of_rows) {

        my @args = ();

        # add to each column
        foreach my $column (1 .. $number_of_columns) {

            my $option = shift(@options);

            if (defined($option)) {
                push(@args, "[$option]");          # add the index
                push(@args, $index->{$option});    # add the text
            } else {

                # blank cells
                push(@args, '');
                push(@args, '');
            }
        }

        $table->row(@args);

    }

    return Goo::Prompter::highlight_options($table->render());

}

1;


__END__

=head1 NAME

Goo::OptionIndexTable - Take a hash of options and turn into a table of text

=head1 SYNOPSIS

use Goo::OptionIndexTable;

=head1 DESCRIPTION



=head1 METHODS

=over

=item make

constructor

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

