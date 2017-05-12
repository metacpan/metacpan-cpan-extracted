package Goo::Thing::pm::Perl5Profiler;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2004
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Perl5Profiler.pm
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

use Goo::Object;
use Goo::Profile;
use Goo::Prompter;
use Text::FormatTable;
use Goo::Thing::pm::Perl5ModuleInspector;

use base qw(Goo::Object);


###############################################################################
#
# get_methods_table - return a table of methods
#
###############################################################################

sub get_methods_table {

    my ($this, $profile, $inspector, $thing) = @_;

    my $table = Text::FormatTable->new('4l 20l 77l');

    $table->head('', 'Methods', 'Description');

    $table->rule('-');

    foreach my $method ($inspector->get_methods()) {

        my $index_key = $profile->get_next_index_key();

        $profile->add_option($index_key, $method, "Goo::Thing::pm::MethodProfileOption");

        # print "addin conter === $counter \n";
        $table->row("[$index_key]", $method, $inspector->get_method_description($method));

    }

    return Goo::Prompter::highlight_options($table->render());

}


###############################################################################
#
# run - generate a profile of a program
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $profile = Goo::Profile->new($thing);

    while (1) {

        $profile->clear();

        $profile->show_header("Perl5 Profile", $thing->get_filename(), $thing->get_location());

        my $inspector = Goo::Thing::pm::Perl5ModuleInspector->new($thing->get_full_path());

        my @packages = $inspector->get_uses_list();

        # add the module list
        $profile->add_options_table("Uses Packages",
                                    4,
                                    "Goo::Thing::pm::PackageProfileOption",
                                    $inspector->get_uses_list());

        # add the methods list
        $profile->add_options_table("Methods", 4,
                                    "Goo::Thing::pm::MethodProfileOption",
                                    $inspector->get_methods());

        # render a table of method signatures and descriptions
        #$profile->add_rendered_table($this->get_methods_table($profile, $inspector, $thing));

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

Goo::Thing::pm::Perl5Profiler - Create a synopsis of a Perl5 program

=head1 SYNOPSIS

use Goo::Thing::pm::Perl5Profiler;

=head1 DESCRIPTION



=head1 METHODS

=over

=item get_methods_table

return a table of methods

=item run

display a profile of a program

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

