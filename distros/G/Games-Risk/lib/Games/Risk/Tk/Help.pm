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

package Games::Risk::Tk::Help;
# ABSTRACT: prisk manual window
$Games::Risk::Tk::Help::VERSION = '4.000';
use Moose;
use Path::Class;
use Tk::Pod::Text;
use Tk::Sugar;

use Games::Risk::I18n  qw{ T };
use Games::Risk::Utils qw{ $SHAREDIR };

with 'Tk::Role::Dialog' => { -version => 1.101480 };


# -- initialization / finalization

sub _build_title     { 'prisk - ' . T('help') }
sub _build_icon      { $SHAREDIR->file('icons', '32','help.png') }
sub _build_header    { T('How to play?') }
sub _build_resizable { 1 }
sub _build_cancel    { T('Close') }


# -- private subs

#
# $self->_build_gui( $frame );
#
# called by tk::role::dialog to build the inner dialog
#
sub _build_gui {
    my ($self,$f) = @_;

    $f->PodText(
        -file       => $SHAREDIR->file('manual.pod'),
        -scrollbars => 'e',
    )->pack( top, xfill2, pad10 );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Games::Risk::Tk::Help - prisk manual window

=head1 VERSION

version 4.000

=head1 DESCRIPTION

C<GR::Tk::Help> implements a Tk window used to show the manual of the
game. The manual itself is in a pod file in the share directory.

=head1 ATTRIBUTES

=head2 parent

A Tk window that will be the parent of the toplevel window created. This
parameter is mandatory.

=head1 METHODS

=head2 new

    Games::Risk::Tk::Help->new( %opts );

Create a window showing some basic help about the game. See the
attributes for available options.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
