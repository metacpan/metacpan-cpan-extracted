package Goo::TrailProfiler;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2004
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     GooTrailProfiler.pm
# Description:  Show a Trail of Things the programmer has been working on
#
# Date          Change
# -----------------------------------------------------------------------------
# 12/08/2005    Added method: testingNow
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Profile;
use Goo::Prompter;
use Goo::TrailManager;

our @ISA = ("Goo::Object");


###############################################################################
#
# run - show a trail of things
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $profile = Goo::Profile->new($thing);

    while (1) {
        $profile->clear();
		$profile->show_header("The Zone", "The tail of the Trail", "trail.goo");
        $profile->add_rendered_table($this->add_trail_table($profile, $thing));
        $profile->display();
        $profile->get_command();
    }

}


###############################################################################
#
# add_trail_table - return a table of package that this module uses
#
###############################################################################

sub add_trail_table {

    my ($this, $profile, $thing) = @_;

    my @actions;

    if ($thing->get_filename() eq "tail.trail") {
        @actions = Goo::TrailManager::get_latest_actions();
    } else {
        @actions =
            Goo::TrailManager::get_context($thing->{start_position}, $thing->{end_position});
    }

    # return a list of the most recent Things!
    my $table = Text::FormatTable->new('4l 25l 35l 20l');
    $table->head('', 'Things', "Action", "When");
    $table->rule('-');

    foreach my $action (@actions) {

        my $index_key = $profile->get_next_index_key();
        $profile->add_option($index_key, $action->get_thing(), "Goo::ThingProfileOption");

        # show a row in the table
        $table->row("[$index_key]",        $action->get_short_thing(),
                    $action->get_action(), $action->get_when());

    }

    return Goo::Prompter::highlight_options($table->render());

}


1;


__END__

=head1 NAME

Goo::TrailProfiler - Show a Trail of Things the programmer has been working on

=head1 SYNOPSIS

use Goo::TrailProfiler;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

show a Trail of Things

=item add_trail_table

return a list of Trail actions and Things

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

