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

package Games::Risk::Tk::About;
# ABSTRACT: prisk about information
$Games::Risk::Tk::About::VERSION = '4.000';
use Moose;
use Path::Class;

use Games::Risk;
use Games::Risk::I18n  qw{ T };
use Games::Risk::Utils qw{ $SHAREDIR };

with 'Tk::Role::Dialog' => { -version => 1.101480 };


# -- initialization / finalization

sub _build_title     { 'prisk - ' . T('about') }
sub _build_icon      { $SHAREDIR->file('icons', '32', 'about.png') }
sub _build_header    { "prisk $Games::Risk::VERSION" }
sub _build_resizable { 0 }
sub _build_cancel    { T('Close') }

sub _build_text { join "\n",
    T('Created by Jerome Quelin'),
    T('Copyright (c) 2008 Jerome Quelin, all rights reserved'),
    '',
    T('prisk is free software; you can redistribute it and/or modify it under the terms of the GPLv3.'),
    ;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Games::Risk::Tk::About - prisk about information

=head1 VERSION

version 4.000

=head1 DESCRIPTION

C<GR::Tk::About> implements a Tk window used to show the copyright and
licence of the game.

=head1 ATTRIBUTES

=head2 parent

A Tk window that will be the parent of the toplevel window created. This
parameter is mandatory.

=head1 METHODS

=head2 new

    Games::Risk::Tk::About->new( %opts );

Create a window showing some information about the game. See the
attributes for available options.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
