#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#

package AI::Util;

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

    # set the version for version checking
    $VERSION = 0.01;

    @ISA = qw(Exporter);

    # functions
    @EXPORT = qw(
        &say
        &connect_to
        &only_have_ability
        &be_service
        &kill_all_subprocesses
        &kill_process_from
        &client_setup
        &LANGUAGE
    );
    %EXPORT_TAGS = ();    # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK = qw();
}
our @EXPORT_OK;

use Data::Dumper;
use Config::Std;

