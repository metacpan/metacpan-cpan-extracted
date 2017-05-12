package JavascriptProfiler;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2004
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     JavascriptProfiler.pm
# Description:  Create a synopsis of a program / module / script
#
# Date          Change
# -----------------------------------------------------------------------------
# 01/11/2004    Auto generated file
# 01/11/2004    Needed to work with the Goo
# 16/02/2005    Need to find out a range of lines for things
# 12/08/2005    Added method: getOption
# 12/08/2005    Added method: testingNow
# 24/08/2005    Added method: showHeader
#
###############################################################################

use strict;

use List;
use Object;
use Profile;
use Prompter;

use base qw(Object);


###############################################################################
#
# run - return a table of methods
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $profile = Profile->new($thing);

    while (1) {

        $profile->clear();

        $profile->set_location($thing->get_location());
        $profile->set_filename($thing->get_filename());

        my @functions = $thing->get_file() =~ m/^function\s+(\w+)\(/msg;
        my @variables = $thing->get_file() =~ m/var\s+(\w+)/msg;

        #Prompter::notify("found --- " . @functions);
        #Prompter::notify("found --- " . @variables);

        # add the function list
        $profile->add_options_table("Functions", 4, "JSFunctionProfileOption",
                                  List::get_unique(@functions));

        # add the variable list
        $profile->add_options_table("Variables", 4, "JumpProfileOption",
                                  grep { length($_) > 1 } List::get_unique(@variables));

        # add a list of Things found in this Thing
        $profile->add_things_table();

        # show the profile and all the rendered tables
        $profile->display();

        # prompt the user for the next command
        $profile->get_command();

    }

}


1;


__END__

=head1 NAME

JavascriptProfiler - Create a synopsis of a program / module / script

=head1 SYNOPSIS

use JavascriptProfiler;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

return a table of methods


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

