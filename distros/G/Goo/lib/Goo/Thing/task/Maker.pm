# -*- Mode: cperl; mode: folding; -*-

package Goo::Thing::task::Maker;

###############################################################################
# Turbo10.com
#
# Copyright Turbo10.com 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Maker.pm
# Description:  Make a task module
#
# Date          Change
# -----------------------------------------------------------------------------
# 16/10/2005    Auto generated file
# 16/10/2005    Need to create a task object
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Header;
use Goo::Prompter;
use Goo::Database;
use Goo::Prompter;
use Goo::TeamManager;

use base qw(Goo::Object);


###############################################################################
#
# run - make a task_maker
#
###############################################################################

sub run {

    my ($this, $filename) = @_;

    Goo::Header::show($filename, "database");

    my $query = Goo::Database::prepare_sql(<<EOSQL);

	insert 	into task (	title,
						description,
						requestedby,
						importance,
						status,
						requestedon)
	values			  (?, ?, ?, ?, "pending", now())

EOSQL

    Goo::Database::bind_param($query, 1, Goo::Prompter::ask("Enter a new task?"));
    Goo::Database::bind_param($query, 2,
                              Goo::Prompter::ask("Enter a description (how/when/where/why)?"));

    my $requested_by =
        Goo::Prompter::pick_one("Requested by?", Goo::TeamManager::get_all_nick_names());

    Goo::Database::bind_param($query, 3, $requested_by);
    Goo::Database::bind_param($query, 4, Goo::Prompter::ask("How important is this (1-10)?", 3));

    #my $company = Goo::Prompter::pick_one("for which company?", qw(turbo10 trexy));
    # Goo::Database::bind_param($query, 5, "");

    # what is the pain associated with this task???
    Goo::Database::execute($query);

    Goo::Prompter::say("New task created.");

    if (Goo::Prompter::confirm("Create another task?")) {
        $this->run($filename);
    }

}


1;


__END__

=head1 NAME

Goo::Thing::task::Maker - Make a task module

=head1 SYNOPSIS

use Goo::Thing::task::Maker;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

make a task_maker


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

