package Goo::Thing::bug::Maker;

###############################################################################
# Turbo10.com
#
# Copyright Turbo10.com 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::bug::Maker.pm
# Description:  What?? something that *makes* bugs!!
#               Bugs are a software artefact too.
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
# run - make a bug_maker
#
###############################################################################

sub run {

    my ($this, $filename) = @_;

	$filename = $filename || "bug";

    Goo::Prompter::clear();

    Goo::Header::show("Bug Maker", $filename, "database");

    Goo::Prompter::say();

    my $query = Goo::Database::prepare_sql(<<EOSQL);

	insert 	into bug (	title,
						description,
						foundby,
						importance,
						status,
						foundon)
	values			  (?, ?, ?, ?, 'alive', now())

EOSQL

    Goo::Database::bind_param($query, 1, Goo::Prompter::insist("Enter a new bug?"));
    Goo::Database::bind_param($query, 2,
                              Goo::Prompter::ask("Bug description (how/when/where/why)?"));

    my $found_by = Goo::Prompter::pick_one("Found by?", Goo::TeamManager::get_all_nick_names());

    Goo::Database::bind_param($query, 3, $found_by);
    Goo::Database::bind_param($query, 4, Goo::Prompter::ask("How important is this (1-10)?", 3));

    #my $company = Goo::Prompter::pick_one("which company?", qw(turbo trexy));
    #Goo::Database::bind_param($query, 5, "");

    # what is the pain associated with this task???
    Goo::Database::execute($query);

    Goo::Prompter::say("Bug recorded.");

    if (Goo::Prompter::confirm("Enter another bug?")) {
        $this->run($filename);
    }

}


1;


__END__

=head1 NAME

Goo::Thing::bug::Maker - What?? something that *makes* bugs!!

=head1 SYNOPSIS

use Goo::Thing::bug::Maker;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

make a bug_maker


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

