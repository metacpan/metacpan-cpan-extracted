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

package Games::Risk::Utils;
# ABSTRACT: various utilities for prisk
$Games::Risk::Utils::VERSION = '4.000';
use Exporter::Lite;
use File::ShareDir::PathClass;
use Path::Class;
 
our @EXPORT_OK = qw{ $SHAREDIR debug };

our $SHAREDIR = -e file("dist.ini") && file("dist.ini")->slurp !~ /Maps/
    ? dir ("share")
    : File::ShareDir::PathClass->dist_dir("Games-Risk");

1;

__END__

=pod

=head1 NAME

Games::Risk::Utils - various utilities for prisk

=head1 VERSION

version 4.000

=head1 DESCRIPTION

This module provides some helper variables and subs, to be used on
various occasions throughout the code.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
