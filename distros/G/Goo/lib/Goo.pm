package Goo;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo.pm
# Description:  Stick Things together with The Goo
#
#               See: http://thegoo.org
#                    http://blog.thegoo.org
#
# Date          Change
# -----------------------------------------------------------------------------
# 27/03/2004    Auto generated file
# 27/03/2004    Reduce work, bugs, documentation, and maintenance
# 29/10/2004    Used filename suffixes to determine what to do - added a lot of
#               the Goo's basic functionality in one go!
# 02/02/2005    Returned to add more functions
# 07/02/2005    Moved dynamic "use" to "require" to stop connecting to the Master
#               DB on startup for faster running
# 10/02/2005    Added a program editor for fast edits and test updates.
#               Added a ProgramCloner and ProgramEditor
# 16/06/2005    Added meta-goo descriptions in /home/search/goo - dramatically
#               simplified the code for this program.
# 01/08/2005    Meta details stored in Config files help to simplify this part
#               of the code even more - this unifies the command-line and [E]dit
#               processing steps.
# 17/10/2005    Added method: loadMaker
# 23/11/2005    Added check_environment() to help with CPAN-friendly install
#
###############################################################################

use strict;

use File::Grep  qw(fdo);
use File::NCopy qw(copy);

use Goo::Object;
use Goo::Loader;
use Goo::Prompter;
use Goo::TrailManager;
use Goo::LiteDatabase;

use base qw(Goo::Object);

our $VERSION = '0.09';


###############################################################################
#
# check_environment - is everything set up OK?
#
###############################################################################

sub check_environment {

    my $db_directory = "$ENV{HOME}/.goo";              # store the DB in ~/.goo
    my $db_file      = "$db_directory/goo-trail.db";   # in the file goo-trail.db

    if (-e $db_file) {                                 # datbase file is present
        Goo::LiteDatabase::get_connection($db_file);   # connect to db 
        return;                                        # and bail out
    }

    # no database yet - let's make one?
    # check if the ~/.goo directory is present?
    if (!-d $db_directory) {    		       # if there is no directory
        if (-e $db_directory) {   	               # but a file with the name .goo
            rename $db_directory, "$db_directory.wtf"; # move it
        }

	print "~/.goo directory was not present, so I will create one now\n";
	print "and populate it with common things. You can customize it later.\n";

        mkdir $db_directory;                 # make the ~/.goo directory
	for(@INC) {                          # lookup all @INC directories
	    if(-e "$_/.gooskel") {           # if we found the goo skeletton dir
		copy(\1, "$_/.gooskel/*", $db_directory);
		last;
	    }
	}
    }

    close DATA if (open DATA, ">>$db_file"); # make the db file ("touch")

    # connect to the database for the first time
    Goo::LiteDatabase::get_connection($db_file);

    # create all the tables
    Goo::TrailManager::create_database();

}


###############################################################################
#
# doAction - edit a template etc
#
###############################################################################

sub do_action {

    my ($this, $action, $filename, @parameters) = @_;

    # special exception for makers - need to remove this later
    if ($action =~ /M/i) {

        $filename = "$ENV{HOME}/.goo/things/goo/$filename";

        if (-e $filename) {
            return
                unless Goo::Prompter::confirm(
                                            "The file $filename already exists. Continue making?",
                                            "N");
        }

        my $maker = Goo::Loader::get_maker($filename);
        $maker->run($filename);

    } else {

        # if the filename exists in the current directory
        my $thing = Goo::Loader::load($filename);

        # can the Thing do the action?
        if ($thing->can_do_action($action)) {

            # print "thing can do $action \n";
            # dynamically call the matching method
            $thing->do_action($action, @parameters);

        } else {

            Goo::Prompter::stop("Goo invalid action $action for this Thing: $filename.");

        }

    }

}


###############################################################################
#
# BEGIN - is everything set up OK?
#
###############################################################################

sub BEGIN {

    # check and set up the environment
    check_environment();

}


1;


__END__

=head1 NAME

Goo - Stick Things together with The Goo

=head1 SYNOPSIS

shell> goo -p Object.pm		# show a [P]rofile of Object.pm

shell> goo -l Object.pm		# show Back [L]inks to Object.pm

shell> goo -r Object.pm		# [R]un Object.pm

shell> goo -i Object.pm		# comp[I]le Object.pm

shell> goo -p access.log		# show a [P]rofile of access.log

shell> goo -c Object.pm		# [C]lone Object.pm into another Thing

shell> goo -o				# the Care[O]Meter shows Things you care about while coding (e.g., tasks, bugs)

shell> goo -z				# show Things in your working [Z]one or mental buffer

=head1 DESCRIPTION

"The Goo" helps you stick "Things" together in your working environment.

Things include Perl modules, Perl scripts, log files, javascripts, configuration files, database tables, templates etc.

The Goo records a "Trail" as you jump quickly from Thing to Thing in a simple, text-based console. It remembers how you 
associate Things in your environment.

Accelerate your work by quickly traversing the Trail of associations between Things. 

=head1 METHODS

=over

=item check_environment

Check and set up the environment.

=item do_action

Take a command line switch (e.g., -p) and map it to an action handler (e.g., [P]rofile) and perform the action on the 
Thing.

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

Tour	http://thegoo.org/goo-tour.pdf (big)

Web 	http://thegoo.org

Blog	http://blog.thegoo.org
