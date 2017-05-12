package Goo::Thing;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing.pm
# Description:  A new generic type of "Thing" in The Goo based on global config
#               files. A Thing is a handle on an underlying Thing.
#
# Date          Change
# -----------------------------------------------------------------------------
# 15/06/2005    Auto generated file
# 15/06/2005    Needed a generic thing
# 01/08/2005    Simplified action handling
# 11/10/2005    Added method: getLocation
# 18/10/2005    Added method: getDatabaseRow
# 19/10/2005    Added method: getColumns
#
###############################################################################

use strict;

use Cwd;
use Goo::Object;
use Data::Dumper;

# use Smart::Comments;
use Goo::TrailManager;

use base qw(Goo::Object);


###############################################################################
#
# new - construct a Thing
#
###############################################################################

sub new {

    my ($class, $filename) = @_;

    my $this = $class->SUPER::new();

    unless ($filename) {
        die("Can't find Thing. No filename found at: " . caller());
    }

    # extract the prefix and suffix
    if ($filename =~ /(.*)\.(.*)$/) {
        $this->{prefix} = $1;
        $this->{suffix} = $2;
    } else {

        # it may be all suffix, example: goo -m goo
        $this->{suffix} = $filename;
    }

    # remember the filename
    $this->{filename} = $filename;

    # load the config_file
    my $config_file = Goo::ConfigFile->new($this->{suffix} . ".goo");

    ### The config file should contain the actions
    ### $config_file->to_string()
    unless ($config_file) {
        die("Can't create Thing. No config file found for $this->{suffix}.");
    }

    # merge all the config fields with this object
    %$this = (%$this, %$config_file);

    return $this;

}


###############################################################################
#
# get_filename - all Things must have a "filename" - even database Things!
#
###############################################################################

sub get_filename {

    my ($this) = @_;

    # this is the ID of the handle on the Thing!
    return $this->{filename};

}


###############################################################################
#
# get_suffix - return the Thing suffix
#
###############################################################################

sub get_suffix {

    my ($this) = @_;

    return $this->{suffix};

}


###############################################################################
#
# get_prefix - get the full contents of the file
#
###############################################################################

sub get_prefix {

    my ($this) = @_;

    return $this->{prefix};

}


###############################################################################
#
# can_do_action - can this thing do the action?
#
###############################################################################

sub can_do_action {

    my ($this, $action) = @_;

    return exists $this->{actions}->{$action};

}


###############################################################################
#
# get_commands - return a list of commands
#
###############################################################################

sub get_commands {

    my ($this) = @_;

    my @commands;

    foreach my $letter (sort { $a cmp $b } keys %{ $this->{actions} }) {

        push(@commands, $this->{actions}->{$letter}->{command});

    }

    return @commands;

}


###############################################################################
#
# do_action - execute action
#
###############################################################################

sub do_action {

    my ($this, $action_letter, @parameters) = @_;

    unless ($this->isa("Goo::Thing")) {
        print("Invalid Thing.");
        print Dumper($this);
    }


    #unless ($action_letter eq "B") {

    # this is a new step in the trail - record it
    Goo::TrailManager::save_goo_action($this, $this->{actions}->{$action_letter}->{command});

    # reset the trail position
    #Goo::TrailManager::reset_last_action();

    my $module = $this->{actions}->{$action_letter}->{action};

    # strip action handler of .pm suffix
    $module =~ s/\.pm$//;

    # Goo::Prompter::trace("about to require this $module");

    ### $this->{actions}->{E}->{action} = "ProgramEditor";
    eval "require $module;";

    if ($@) {
        die("Evaled failed $@");
    }

    ### $this->{actions}->{E}->{action} = "ProgramEditor";
    my $actor = $module->new();

    $actor->run($this, @parameters);

}

1;


__END__

=head1 NAME

Goo::Thing - A "Thing" in your working environment that you can do actions to

=head1 SYNOPSIS

use Goo::Thing;

=head1 DESCRIPTION

A "Thing" is something you perform actions on in your working environment. It could be a file, a database entity or
configuration file. 

Everytime you perform an action on a Thing it is recorded in the Goo Trail. 

The Goo Trail records all your temporal associations between Things in your environment.

=head1 METHODS

=over

=item new

construct a Thing

=item get_filename

all Things must have a "filename" or "handle" - even database Things!

=item get_suffix

return the Thing suffix

=item get_prefix

get the full contents of the file

=item can_do_action

can this Thing do the action?

=item get_commands

return a list of commands

=item do_action

execute the action

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

Tour    http://thegoo.org/goo-tour.pdf (big)

Web     http://thegoo.org

Blog    http://blog.thegoo.org

