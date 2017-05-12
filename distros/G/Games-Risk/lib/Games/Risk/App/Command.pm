#
# This file is part of Games-Risk
#
# This software is Copyright (c) 2008 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::App::Command;
# ABSTRACT: base class for prisk sub-commands
$Games::Risk::App::Command::VERSION = '4.000';
use App::Cmd::Setup -command;


1;

__END__

=pod

=head1 NAME

Games::Risk::App::Command - base class for prisk sub-commands

=head1 VERSION

version 4.000

=head1 DESCRIPTION

This module is the base class for all sub-commands. It doesn't do
anything special currently but trusting methods for pod coverage.

=for Pod::Coverage::TrustPod description
    opt_spec
    execute

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
