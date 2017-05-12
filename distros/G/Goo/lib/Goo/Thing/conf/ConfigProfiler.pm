package Goo::Thing::conf::ConfigProfiler;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::conf::ConfigProfiler.pm
# Description:  Profile a config file
#
# Date          Change
# -----------------------------------------------------------------------------
# 17/09/2005    Version 1
# 17/09/2005    Added method: showProfile
# 16/10/2005    Added method: getFields
#
###############################################################################

use strict;

use Goo::List;
use Goo::Object;
use Goo::Profile;
use base qw (Goo::Object);


###############################################################################
#
# run - display a profile of an xml thing
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $profile = Goo::Profile->new($thing);

    while (1) {

        $profile->clear();

		$profile->show_header("Config Profile", 
							  $thing->get_filename(), 
							  $thing->get_location());
	
        # add the variable list
        $profile->add_options_table("Fields", 4, "Goo::JumpProfileOption",
                                    $this->get_fields($thing->get_file()));

        # add a list of Things found in this Thing
        $profile->add_things_table();

        # show the profile and all the rendered tables
        $profile->display();

        # prompt the user for the next command
        $profile->get_command();

    }

}


###############################################################################
#
# get_fields - get all the fields in the config file
#
###############################################################################

sub get_fields {

    my ($this, $config_string) = @_;

    my @fields;

    foreach my $line (split(/\n/, $config_string)) {

        next if $line =~ /^\#/;

        # strip any trailing comment
        $line =~ s/\#.*//;

        # strip trailing space
        $line =~ s/\s+$//;

        # strip leading space
        $line =~ s/^\s+//;

        # match a field
        if ($line =~ /^(.*?)\=/) {
			
			my $field = $1;
			$field =~ s/\s+$//;	
			$field =~ s/^\s+//;	
        	push(@fields, $field);

		}

    }

    return Goo::List::get_unique(@fields);

}

1;


__END__

=head1 NAME

Goo::Thing::conf::ConfigProfiler - Profile a config file

=head1 SYNOPSIS

use Goo::Thing::conf::ConfigProfiler;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

display a profile of an xml thing

=item get_fields

get all the fields in the config file


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

