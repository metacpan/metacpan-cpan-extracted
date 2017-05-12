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

package Games::Risk::App;
# ABSTRACT: prisk's App::Cmd
$Games::Risk::App::VERSION = '4.000';
use App::Cmd::Setup -app;

sub allow_any_unambiguous_abbrev { 1 }
sub default_args                 { [ 'play' ] }

1;

__END__

=pod

=head1 NAME

Games::Risk::App - prisk's App::Cmd

=head1 VERSION

version 4.000

=head1 DESCRIPTION

This is the main application, based on the excellent L<App::Cmd>.
Nothing much to see here, see the various subcommands available for more
information, or run one of the following:

    prisk commands
    prisk help

Note that each subcommand can be abbreviated as long as the abbreviation
is unambiguous.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
