package Goo::Thing::pm::Perl6Profiler;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Perl6Profiler.pm
# Description:  Create a synopsis of a program / module / script
#
# Date          Change
# -----------------------------------------------------------------------------
# 12/11/2005    Alpha version using simple Regexes - just a proof of concept
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Profile;
use Goo::Prompter;
use Text::FormatTable;

use Goo::Thing::pm::Perl6ModuleInspector;

use base qw(Goo::Object);


###############################################################################
#
# get_signatures_table - return a table of signatures
#
###############################################################################

sub get_signatures_table {

    my ($this, $profile, $inspector, $thing) = @_;

    my $table = Text::FormatTable->new('4l 9l 21l 40l 12l 12l');

    $table->head('', 'Type', 'Name', 'Parameters', 'Returns', 'Traits');

    $table->rule('-');

    foreach my $method ($inspector->get_signatures()) {

        my $index_key = $profile->get_next_index_key();

        $profile->add_option($index_key, $method->{name}, "Goo::Thing::pm::MethodProfileOption");

        # print "addin conter === $counter \n";
        $table->row("[$index_key]",        $method->{type},    $method->{name},
                    $method->{parameters}, $method->{returns}, $method->{traits});

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

        $profile->show_header("Perl6 Profile", $thing->get_filename(), $thing->get_location());

        my $inspector = Goo::Thing::pm::Perl6ModuleInspector->new($thing->get_full_path());

        my @packages = $inspector->get_uses_list();

        # add the module list
        $profile->add_options_table("Uses Packages",
                                    4,
                                    "Goo::Thing::pm::PackageProfileOption",
                                    $inspector->get_uses_list());

        # render a table of method signatures and descriptions
        $profile->add_rendered_table($this->get_signatures_table($profile, $inspector, $thing));

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

Goo::Thing::pm::Perl6Profiler - Create a synopsis of a program / module / script

=head1 SYNOPSIS

use Goo::Thing::pm::Perl6Profiler;

=head1 DESCRIPTION



=head1 METHODS

=over

=item get_signatures_table

return a table of signatures

=item run

generate a profile of a Perl6 program

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

