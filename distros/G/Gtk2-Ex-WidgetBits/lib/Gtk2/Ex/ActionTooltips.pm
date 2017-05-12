# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::ActionTooltips;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2 1.160; # for $widget->set_tooltip_text new in Gtk2 1.152

our $VERSION = 48;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(group_tooltips_to_menuitems
                    action_tooltips_to_menuitems_dynamic);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# uncomment this to run the ### lines
#use Smart::Comments;

# Cribs:
#
# $action->get_proxies can't be used within a 'connect-proxy' handler until
# Gtk2-Perl 1.220 (due to floating ref handling problems).  That means not
# using group_tooltips_to_menuitems() within connect-proxy until that
# version, though doing so from there would be pretty unusual anyway.
#
# $action->get_tooltip isn't wrapped (gtk_action_get_tooltip()) as of
# Gtk2-Perl 1.220, hence use of $action->get('tooltip').
# $widget->set_tooltip_text is wrapped in 1.160, and will want at least that
# or newer for bug fixes, so may as well use that method instead of the
# 'tooltip-text' property.
#

my $connect_hook_id;
sub _ensure_connect_hook {
  $connect_hook_id ||= Gtk2::ActionGroup->signal_add_emission_hook
    (connect_proxy => \&_do_connect_proxy);
}

sub group_tooltips_to_menuitems {
  Gtk2::Widget->can('set_tooltip_text') || return; # only in Gtk 2.12 up

  foreach my $actiongroup (@_) {
    $actiongroup->{(__PACKAGE__)} = undef;
    _ensure_connect_hook ();

    foreach my $action ($actiongroup->list_actions) {
      _do_action_tooltip ($action);
    }
  }
}

sub action_tooltips_to_menuitems_dynamic {
  Gtk2::Widget->can('set_tooltip_text') || return; # only in Gtk 2.12 up

  foreach my $action (@_) {
    $action->{(__PACKAGE__)} = undef;
    _ensure_connect_hook ();

    $action->signal_connect ('notify::tooltip' => \&_do_action_tooltip);
    _do_action_tooltip ($action);
  }
}

# Gtk2::ActionGroup 'connect-proxy' emission hook handler
sub _do_connect_proxy {
  my ($invocation_hint, $parameters) = @_;
  my ($actiongroup, $action, $widget) = @$parameters;
  ### dynamic connect: ("@{[$action->get_name]} $action onto $widget")

  if ((exists $actiongroup->{(__PACKAGE__)}
       || exists $action->{(__PACKAGE__)})
      && $widget->isa('Gtk2::MenuItem')) {
    $widget->set_tooltip_text ($action->get('tooltip'));
  }
  return 1; # stay connected
}

# Gtk2::Action 'notify::tooltip' signal handler, and called directly
sub _do_action_tooltip {
  my ($action) = @_;
  my $tip = $action->get('tooltip');
  ### tooltip: ["@{[$action->get_name]} $action, tip ", $tip]

  foreach my $widget ($action->get_proxies) {
    ### proxy: $widget
    if ($widget->isa('Gtk2::MenuItem')) {
      $widget->set_tooltip_text ($tip);
    }
  }
}

1;
__END__

=for stopwords tooltips MenuItems Gtk MenuItem tooltip unintrusive GtkActionGroup statusbar ActionGroup Ryde Gtk2-Ex-WidgetBits

=head1 NAME

Gtk2::Ex::ActionTooltips -- propagate Action tooltips to MenuItems

=for test_synopsis my ($actiongroup, $action1, $action2, $action3)

=head1 SYNOPSIS

 use Gtk2::Ex::ActionTooltips;
 Gtk2::Ex::ActionTooltips::group_tooltips_to_menuitems
     ($actiongroup);
 Gtk2::Ex::ActionTooltips::action_tooltips_to_menuitems_dynamic
     ($action1, $action2, $action2);

=head1 DESCRIPTION

This spot of code sets tooltips from L<C<Gtk2::Action>|Gtk2::Action>s onto
L<C<Gtk2::MenuItem>|Gtk2::MenuItem>s connected to those actions.  Normally
the action connection sets tooltips onto
L<C<Gtk2::ToolItem>|Gtk2::ToolItem>s, but not MenuItems.

The widget C<tooltip-text> mechanism is used, which is new in Gtk 2.12 and
up.  For earlier Gtk the functions here do nothing.

Whether you want tooltips on MenuItems depends on personal preference or how
much explanation the actions need.  A MenuItem tooltip is fairly unintrusive
though, and pops up only after the usual delay.

See F<examples/action-tooltips.pl> in the Gtk2-Ex-WidgetBits sources for a
sample program setting tooltips on menu items.

There's other ways to show what a menu item might do of course.  For
instance the Gtk manual under the GtkActionGroup connect-proxy signal
describes showing action tooltips in a statusbar.

=head1 EXPORTS

Nothing is exported by default and the functions can be called with a fully
qualified name as shown.  Or they can be imported in usual
L<Exporter|Exporter> style, including tag C<:all> for all functions.

    use Gtk2::Ex::ActionTooltips 'group_tooltips_to_menuitems';
    group_tooltips_to_menuitems ($actiongroup);

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::ActionTooltips::group_tooltips_to_menuitems ($actiongroup) >>

Setup C<$actiongroup> (a L<C<Gtk2::ActionGroup>|Gtk2::ActionGroup>) so
tooltips in its actions are installed on any connected C<Gtk2::MenuItem>s.

    my $actiongroup = Gtk2::ActionGroup->new ("main");
    Gtk2::Ex::ActionTooltips::group_tooltips_to_menuitems
        ($actiongroup);

The tooltips are applied to current and future connected MenuItems, for all
current and future actions in the group.  But the tooltips in the actions
are assumed to be unchanging.  If you change a tooltip then the change is
not propagated to already-connected menu items.

=item C<< Gtk2::Ex::ActionTooltips::action_tooltips_to_menuitems_dynamic ($action1, $action2, ...) >>

Setup each given C<$action> (C<Gtk2::Action> object) so its tooltip property
is installed on any connected C<Gtk2::MenuItms>s dynamically.

    Gtk2::Ex::ActionTooltips::action_tooltips_to_menuitems_dynamic
      ($my_help_action,
       $my_frobnicate_action);

The tooltips are applied to currently connected MenuItems, and any future
connected MenuItems, and the setup is "dynamic" in that if you change the
action tooltip then the change is propagated to connected MenuItems.

    $my_help_action->set (tooltip => 'New text');

C<action_tooltips_to_menuitems_dynamic> makes a signal connection on each
Action.  To keep down overheads you probably only want it on actions which
might change their tooltips.  If you want dynamic propagation for all
Actions in an ActionGroup you could use

    Gtk2::Ex::ActionTooltips::action_tooltips_to_menuitems_dynamic
      ($actiongroup->list_actions);

Of course this is only actions currently in the ActionGroup, not future
added ones.  As of Gtk 2.16 there's no callback from an ActionGroup when an
action is added to it, so there's no easy way to cover future added actions
too.

=back

=head1 SEE ALSO

L<Gtk2::Action>, L<Gtk2::ActionGroup>, L<Gtk2::MenuItem>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-WidgetBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
