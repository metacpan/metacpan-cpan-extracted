package Goo::Thing::pm::ScopeMatcher;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::pm::ScopeMatcher.pm
# Description:  Extract the matching scope out of a program
#
# Date          Change
# -----------------------------------------------------------------------------
# 17/08/2005    Auto generated file
# 17/08/2005    Started to do this in multiple places
# 26/10/2005    Added method: getScope
#
###############################################################################

use strict;

use Goo::FileUtilities;


###############################################################################
#
# get_scope_of_string - return the scope of the string
#
###############################################################################

sub get_scope_of_string {

    my ($string, $code) = @_;

    my $current_scope = "";

    foreach my $line (split(/\n/, $code)) {

        next if ($line =~ /^\#/);

        if ($line =~ /^sub/) {
            # restart the scope
            $current_scope = "";
        }

        $current_scope .= $line . "\n";

        if ($line =~ /$string/) {
            return $current_scope;
        }

    }

    # not found in scope
    return "";

}


###############################################################################
#
# get_scope_of_line - return the scope of a given line number
#
###############################################################################

sub get_scope_of_line {

    my ($line_number, $filename) = @_;

    my $current_scope = "";
	my $line_count    = 0;

    foreach my $line (Goo::FileUtilities::get_file_as_lines($filename)) {

		$line_count++;

		# ignore comments
        next if ($line =~ /^\#/);

        if ($line =~ /^sub/) {
            # restart the scope
            $current_scope = "";
        }

        $current_scope .= $line;

        if ($line_count == $line_number) {
            return $current_scope;
        }

    }

    # not found in scope
    return "";

}

1;


__END__

=head1 NAME

Goo::Thing::pm::ScopeMatcher - Extract the matching scope out of a program

=head1 SYNOPSIS

use Goo::Thing::pm::ScopeMatcher;

=head1 DESCRIPTION

=head1 METHODS

=over

=item get_scope_of_string

return the scope of the current string

=item get_scope_of_line

return the scope of a given line number


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

