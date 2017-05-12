#
# This file is part of Games-Pandemic
#
# This software is Copyright (c) 2009 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#
use 5.010;
use strict;
use warnings;

package Games::Pandemic::Utils;
{
  $Games::Pandemic::Utils::VERSION = '1.120510';
}
# ABSTRACT: various utilities for pandemic

use Devel::CheckOS        qw{ os_is };
use File::HomeDir         qw{ my_data };
use File::ShareDir::PathClass;
use File::Spec::Functions qw{ catdir updir };
use FindBin               qw{ $Bin };
use Moose;
use Readonly;
 
extends 'Exporter';
our @EXPORT = qw{ $CONFIGDIR $SHAREDIR debug };

Readonly our $CONFIGDIR => _find_config_dir();
our $SHAREDIR = File::ShareDir::PathClass->dist_dir("Games-Pandemic");


# -- public subs


my $debug = -d catdir( $Bin, updir(), '.git' );
sub debug {
    return unless $debug;
    warn "@_";
}


# -- private subs

#
# my $path = _find_config_dir();
#
# return the absolute path where local customization will be saved.
#
sub _find_config_dir {
    my $subdir = os_is('MicrosoftWindows' ) ? 'Perl' : '.perl';
    return catdir( my_data(), $subdir, 'Games-Pandemic' );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Utils - various utilities for pandemic

=head1 VERSION

version 1.120510

=head1 DESCRIPTION

This module provides some helper variables and subs, to be used on
various occasions throughout the code.

=head1 METHODS

=head2 debug( @stuff );

Output C<@stuff> on stderr if we're in a local git checkout. Do nothing
in regular builds.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

