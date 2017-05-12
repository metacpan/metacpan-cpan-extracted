package Goo::TrailManager;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::TrailManager.pm
# Description:  Manage a Trail of Goo Actions - memex style.
#
# Date          Change
# -----------------------------------------------------------------------------
# 19/08/2005    Auto generated file
# 19/08/2005    Needed a way of talking to the GooTrail database.
# 20/08/2005    Added method: createDatabase
# 21/08/2005    Added method: getMostRecent
# 21/08/2005    Added method: getPreviousAction
# 24/08/2005    Added method: getLatestActions
#
###############################################################################

use strict;

use Goo::Action;
use Goo::Loader;
use Goo::Prompter;
use Goo::Environment;
use Goo::LiteDatabase;


# 7 - keep the buffer small (thanks to miller's rule - 7 plus or minus 2)
my $BUFFER_SIZE_LIMIT = 6;


###############################################################################
#
# reset_last_action - set the last_actionid in the trail.goo back to 0
#
###############################################################################

sub reset_last_action {

    # the user is no longer delving into the trail
    Goo::ConfigFile::write_to_file("trail.goo", "last_actionid", 0);

}


###############################################################################
#
# find_context - find the most recent goo context for the current thing
#
###############################################################################

sub find_context {

    my ($thing) = @_;

    # look up the goo trail for this Thing
    my $user     = Goo::Environment::get_user();
    my $filename = $thing->get_filename();

    my $query = Goo::LiteDatabase::execute_sql(<<EOSQL);

	select 		max(stepid) as 'maxstepid'
	from 		gootrail
	where 		thing = "$filename"
	order by 	stepid desc

EOSQL

    my $row = Goo::LiteDatabase::get_result_hash($query);

    # grab the step id
    #
    # if thing->is_pain() - show after the pain start
    #
    my $starting_stepid = $row->{maxstepid} - 3;
    my $ending_stepid   = $row->{maxstepid} + 3;


}


###############################################################################
#
# get_context - display the most recent goo context for the current thing
#
###############################################################################

sub get_context {

    my ($starting_actionid, $ending_actionid) = @_;

    my $query = Goo::LiteDatabase::execute_sql(<<EOSQL);

	select		actionid,
				action,
				thing,
				who,
				strftime("%d/%m/%Y %H:%M:%S",actiontime) as 'actiontime'
	from 		gootrail
	where 		actionid between $starting_actionid and $ending_actionid
	and			thing != "tail.trail"
	and			action not like ('Z%')
	order by 	actionid desc

EOSQL

    my @context;
    my $seen_thing;

    my $buffer_max_size = 6;
    my $buffer_counter  = 0;

    # return the context back
    while (my $row = Goo::LiteDatabase::get_result_hash($query)) {

        next if $seen_thing->{ $row->{thing} };

        $buffer_counter++;

        last if $buffer_counter > $buffer_max_size;

        #print "adding a new goo action - $row->{actionid} $row->{action} \n";
        unshift(@context, Goo::Action->new($row));

        $seen_thing->{ $row->{thing} } = 1;
    }

    return @context;

}


###############################################################################
#
# create_database - save the commands for creating the database
#
###############################################################################

sub create_database {

    # each user must have their own goo trail
    #GooLiteDatabase::do_sql("drop table gootrail");
    #GooLiteDatabase::do_sql("drop index gootrail_idx2");

    # the integer primary key will automatically increment under SQLite
    Goo::LiteDatabase::do_sql(<<EOSQL);

	create table backlinks ( 	linked_to_thing 	char(50) not null,
				 				linked_from_thing 	char(50) not null)

EOSQL

    Goo::LiteDatabase::do_sql(<<EOSQL);

        create table gootrail  (  actionid        integer primary key,
                                  actiontime      date not null,
                                  action          char(50) not null,
                                  thing           char(50) not null,
                                  who             char(20))

EOSQL

    # setting the DATETIME('NOW')
    Goo::LiteDatabase::do_sql("create index gootrail_idx2 on gootrail(thing, actiontime)");

}


###############################################################################
#
# go_back_one - return the previous action from the gootrail
#
###############################################################################

sub go_back_one {

    my $config = Goo::ConfigFile->new("trail.goo");

    my $actionid;

    if ($config->{last_actionid} > 0) {

        # decrement the last trailid
        $actionid = $config->{last_actionid} - 1;
    } else {
        $actionid = get_max_actionid() - 1;
    }

    # save the details to the config file
    Goo::ConfigFile::write_to_file("trail.goo", "last_actionid", $actionid);

    return Goo::Loader::load(get_thing($actionid));

}

###############################################################################
#
# go_forward_one - go to the next action in the goo trail
#
###############################################################################

sub go_forward_one {

    my $config = Goo::ConfigFile->new("trail.goo");

    my $actionid;

    if ($config->{last_actionid} > 0) {

        # decrement the last trailid
        $actionid = $config->{last_actionid} + 1;
    }

    if ($actionid > get_max_actionid()) {
        $actionid = get_max_actionid();
    }

    # save the details to the config file
    Goo::ConfigFile::write_to_file("trail.goo", "last_actionid", $actionid);

    return Goo::Loader::load(get_thing($actionid));

}


###############################################################################
#
# get_previous_thing - return the previous action from the gootrail
#
###############################################################################

sub get_previous_thing {

    my ($thing) = @_;

    my $query = Goo::LiteDatabase::execute_sql(<<EOSQL);

	select 	max(actionid) as 'actionid'
	from 	gootrail
	where 	thing = "$thing->{filename}"

EOSQL

    my $row = Goo::LiteDatabase::get_result_hash($query);

    # we need to deduct 2 because the act of pressing back causes an action
    # to be added to the trail log
    my $previous_position = $row->{actionid} - 2;

    my @context = get_context($previous_position, $previous_position);

    my $previous_action = shift(@context);

    # Goo::Prompter::notify($previous->to_string());
    return Goo::Loader::load($previous_action->get_thing());

}


###############################################################################
#
# get_latest_actions - return the most recent actions that have happened
#
###############################################################################

sub get_latest_actions {

    my $query = Goo::LiteDatabase::execute_sql(<<EOSQL);

	select 	max(actionid) as 'maxactionid'
	from 	gootrail

EOSQL

    my $row = Goo::LiteDatabase::get_result_hash($query);

    my $starting_position = $row->{maxactionid} - 100;

    if ($starting_position < 1) { $starting_position = 1; }

    my $ending_position = $row->{maxactionid};

    # print "starting position = $starting_position - $ending_position\n";
    return get_context($starting_position, $ending_position);

}


###############################################################################
#
# get_max_actionid - return the last actionid
#
###############################################################################

sub get_max_actionid {

    my $query = Goo::LiteDatabase::execute_sql(<<EOSQL);

	select 	max(actionid) as 'maxactionid'
	from 	gootrail

EOSQL

    my $row = Goo::LiteDatabase::get_result_hash($query);

    return $row->{maxactionid};

}


###############################################################################
#
# get_thing - return the thing for a position in the trail
#
###############################################################################

sub get_thing {

    my ($actionid) = @_;

    # connect to the local SQLite DB
    my $query = Goo::LiteDatabase::execute_sql(<<EOSQL);

	select 	thing
	from	gootrail
	where	actionid = $actionid

EOSQL

    my $row = Goo::LiteDatabase::get_result_hash($query);
    return $row->{thing};

}


###############################################################################
#
# save_goo_action - save a step in the goo_trail
#
###############################################################################

sub save_goo_action {

    my ($thing, $action) = @_;

    my $user = Goo::Environment::get_user();

    # grab the filename
    my $filename =
          $thing->isa("Goo::FileThing")
        ? $thing->get_full_path()
        : $thing->get_filename();

    # connect to the local SQLite DB
    Goo::LiteDatabase::execute_sql(<<EOSQL);

	insert into gootrail(action, thing, who, actiontime)
	values ("$action", "$filename", "$user", datetime('now'))

EOSQL

}

1;


__END__

=head1 NAME

Goo::TrailManager - Manage a Trail of Goo Actions - Memex style.

=head1 SYNOPSIS

use Goo::TrailManager;

=head1 DESCRIPTION



=head1 METHODS

=over

=item 7

keep the buffer small (thanks to Miller's rule - 7 plus or minus 2)

=item get_max_actionid

return the id of the last action in the goo_trail

=item get_thing

return the Thing that was the target of actionid

=item go_back_one

return the Thing that was the target of the previous action

=item go_forward_one

return the Thing that was the target of the next action

=item reset_last_action

set the actionid of the last action to max_actionid

=item find_context

find the most recent goo context for the current thing

=item get_context

display the most recent goo context for the current thing

=item create_database

save the commands for creating the database

=item get_previous_thing

return the previous action from the goo_trail

=item get_latest_actions

return the most recent actions that have happened

=item save_goo_action

save a step in the goo_trail


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

