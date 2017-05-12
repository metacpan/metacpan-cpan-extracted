package Goo::Thing::gml::Profiler;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::gml::Profiler.pm
# Description:  Create a synopsis of a gml Thing
#
# Date          Change
# -----------------------------------------------------------------------------
# 02/07/2005    Version 1 - starting to get momementum in The Goo
# 01/08/2005    Broke out ThingFinder into separate module
# 06/10/2005    removed chain of inheritance
# 06/10/2005    Added method: new
#
###############################################################################

use strict;
use Goo::Object;
use Goo::Profile;
use base qw(Goo::Object);


###############################################################################
#
# run - return a table of tokens that this template uses
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $profile = Goo::Profile->new($thing);

    while (1) {

        $profile->clear();

		$profile->show_header("Profile", $thing->get_filename(), $thing->get_location());

        # capture the inside of all tokens in the template
        my @tokens = $thing->get_file() =~ m/\{\{(.*?)\}\}/msg;

        # pick out the unique ones
        my %unique_tokens = map { $_ => 1; } @tokens;

        $profile->add_options_table("Tokens", 4, "Goo::TemplateProfileOption", keys(%unique_tokens));

        $profile->add_things_table();
        $profile->display();
        $profile->get_command();

    }

}

1;


__END__

=head1 NAME

Goo::Thing::gml::Profiler - Create a synopsis of a Goo Markup Language (GML) Thing

=head1 SYNOPSIS

use Goo::Thing::gml::Profiler;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

return a table of tokens that this template uses

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

