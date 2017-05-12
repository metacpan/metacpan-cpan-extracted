# Copyright 2008, 2009, 2010, 2011, 2012, 2014 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

package Glib::Ex::SourceIds;
use 5.008;
use strict;
use warnings;
use Glib;

our $VERSION = 16;

sub new {
  my ($class, @ids) = @_;
  my $self = bless [], $class;
  $self->add (@ids);
  return $self;
}
sub add {
  my ($self, @ids) = @_;
  push @$self, @ids;
}

sub DESTROY {
  my ($self) = @_;
  $self->remove;
}

# g_source_remove() returns false if it didn't find the ID, so no need to
# check whether it's already removed (for instance by a false return from
# the handler function).
#
# Recent Glib has made incompatible changes to this so that
# g_source_remove() emits a g_log() error message on attempting to remove a
# non-existent ID.
#
sub remove {
  my ($self) = @_;
  while (my $id = pop @$self) {
    Glib::Source->remove ($id);
  }
}

1;
__END__

=for stopwords Glib-Ex-ObjectBits Ryde Eg SourceIds

=head1 NAME

Glib::Ex::SourceIds -- hold Glib main loop source IDs

=head1 SYNOPSIS

 use Glib::Ex::SourceIds;
 my $sourceids = Glib::Ex::SourceIds->new
                    (Glib::Timeout->add (1000, \&do_timer),
                     Glib::Idle->add (\&do_idle));

 # removed when ids object destroyed
 $sourceids = undef;

=head1 DESCRIPTION

C<Glib::Ex::SourceIds> holds a set of Glib main loop source IDs.  When the
SourceIds object is destroyed it removes those IDs.

This is designed as a reliable way to keep sources installed for a limited
period, such as an IO watch while communicating on a socket, or a timeout on
an action.  Often such things will be associated with a C<Glib::Object> (or
just a Perl object), though they don't have to be.

=head2 Callback Removal

Callback handler code which wants to remove itself as a source should
destroy any SourceIds object holding that source.  This will have the effect
of removing the handler.  It can return false (C<Glib::SOURCE_REMOVE()>) to
remove itself too if desired.

Recent Glib made incompatible changes to C<g_source_remove()> so that it
emits a C<g_log()> error message on attempting to remove an already-removed
source.  This will happen if a handler removes itself and then later a
SourceIds is destroyed and so removes again.

=head1 FUNCTIONS

=over 4

=item C<< $sourceids = Glib::Ex::SourceIds->new ($id,$id,...) >>

Create and return a SourceIds object holding the given C<$id> main loop
source IDs (integers).

SourceIds doesn't install sources.  You do that with
C<< Glib::Timeout->add() >>, C<< Glib::IO->add_watch() >> and
C<< Glib::Idle->add() >> in the usual ways and all the various options, then
pass the resulting ID to SourceIds to look after.  Eg.

    my $sourceids = Glib::Ex::SourceIds->new
                      (Glib::Timeout->add (1000, \&do_timer));

You can hold any number of IDs in a SourceIds object.  If you want things
installed and removed at different points in the program then use separate
SourceIds objects for each (or each group).

=item C<< $sourceids->add ($id,$id,...) >>

Add the given C<$id> main loop source IDs (integers) to SourceIds object
C<$sourceids>.  This can be used for IDs created separately from a C<new()>
call.

    $sourceids->add (Glib::Timeout->add (1000, \&do_timer));

Adding IDs one by one is good if the code might error out.  IDs previously
connected are safely tucked away in the SourceIds and will be disconnect as
the error unwinds.  An error in a simple connection is unlikely, but if for
instance the "condition" flags for an C<add_watch()> came from some external
code then they could be invalid.

=item C<< $sourceids->remove() >>

Remove the source IDs held in C<$sourceids> from the main loop, using
C<< Glib::Source->remove() >>.  This remove is done when
C<$sourceids> is garbage collected, but you can do it explicitly sooner if
desired.

=back

=head1 SEE ALSO

L<Glib::MainLoop>, L<Glib::Ex::SignalIds>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-objectbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012, 2014 Kevin Ryde

Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ObjectBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
