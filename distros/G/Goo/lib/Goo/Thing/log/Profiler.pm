package Goo::Thing::log::Profiler;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:    	Profiler.pm
# Description:  Show a profile of the log
#
# Date          Change
# -----------------------------------------------------------------------------
# 15/10/2005    Version 1
# 02/12/2005    Removed backticks in run (/usr/bin/tail)
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Profile;
use Goo::Prompter;

use base qw(Goo::Object);


###############################################################################
#
# run - return a table of methods
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $profile = Goo::Profile->new($thing);

    while (1) {

        $profile->clear();

        $profile->show_header("Log Viewer", $thing->get_filename(), $thing->get_location());

        my $log_file_location = $thing->get_full_path();

        $profile->set_description("Tail of $log_file_location");

        # grab the tail of the log
        my @log_tail = Goo::FileUtilities::get_last_lines($log_file_location, 6);

        $profile->add_rendered_table(join("\n", $log_tail));

        # add a list of Things found in this Thing
        $profile->add_things_table($log_tail);

        $profile->display();

        # prompt the user for the next command
        $profile->get_command();

    }

}


1;


__END__

=head1 NAME

Goo::Thing::log::Profiler - Show a profile of the log

=head1 SYNOPSIS

use Goo::Thing::log::Profiler;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

return a table of methods


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

