package Bus_mySUBS;
require 5.000; use English; use strict 'vars', 'refs', 'subs';

# Copyright (c) 1999 Dermot Musgrove <dermot.musgrove@virgin.net>
#
# This library is released under the same conditions as Perl, that
# is, either of the following:
#
# a) the GNU General Public License as published by the Free
# Software Foundation; either version 1, or (at your option) any
# later version.
#
# b) the Artistic License.
#
# If you use this library in a commercial enterprise, you are invited,
# but not required, to pay what you feel is a reasonable fee to perl.org
# to ensure that useful software is available now and in the future. 
#
# (visit http://www.perl.org/ or email donors@perlmongers.org for details)

BEGIN {
    use Exporter    qw (  );
    use Glade::PerlRun;
    use vars        qw( @ISA  @EXPORT );
    # Tell interpreter who we are inheriting from
    @ISA = qw( Glade::PerlRun );
    # Tell interpreter what we are exporting
    @EXPORT =       qw( 
                        on_New_activate
                        on_Open_activate
                        on_Print_activate
                        on_BusFrame_delete_event
                        on_BusFrame_destroy_event
                        on_fileselection1_delete_event
                        on_ok_button1_clicked
                    );
}

sub DESTROY {
    # This sub will be called on object destruction
} # End of sub DESTROY

#===============================================================================
#==== Below are all the signal handlers supplied by the programmer          ====
#===============================================================================
sub on_New_activate {
  my ($class, $data, $object, $instance, $event) = @_;
  my $me = __PACKAGE__."->on_New_activate";
    my $title = sprintf(_("New file selection triggered in %s"), $me);
    if ($instance) {
        # We are AUTOLOAD style run
        # Get ref to hash of all widgets on our form
        my $form = $__PACKAGE__::all_forms->{$instance};
        my $filesel = fileselection1->new->TOPLEVEL;
        $filesel->set_title($title);
        $filesel->show;
    } else {
        # We are Libglade style run
        my $filesel = fileselection1->new;
        $filesel->get_widget('fileselection1')->set_title($title);
        $filesel->signal_autoconnect_from_package('fileselection1');
    }
} # End of sub on_New_activate

sub on_Open_activate {
  my ($class, $data, $object, $instance, $event) = @_;
  my $me = __PACKAGE__."->on_Open_activate";
    my $title = sprintf(_("Open file selection triggered in %s"), $me);
    if ($instance) {
        # We are AUTOLOAD style run
        # Get ref to hash of all widgets on our form
        my $form = $__PACKAGE__::all_forms->{$instance};
        my $filesel = fileselection1->new->TOPLEVEL;
        $filesel->set_title($title);
        $filesel->show;
    } else {
        # We are Libglade style run
        my $filesel = fileselection1->new;
        $filesel->get_widget('fileselection1')->set_title($title);
        $filesel->signal_autoconnect_from_package('fileselection1');
    }
} # End of sub on_Open_activate

sub on_Print_activate {
	my ($class, $data) = @_;
    my $me = __PACKAGE__."->on_Print_activate";
    __PACKAGE__->show_skeleton_message($me, \@ARG, __PACKAGE__, 'pixmaps/glade2perl_logo.xpm');
}

sub on_BusFrame_delete_event {shift->destroy;Gtk->main_quit}
sub on_BusFrame_destroy_event {Gtk->main_quit}

sub on_fileselection1_delete_event {shift->destroy}
sub on_ok_button1_clicked {shift->get_toplevel->destroy}

1;

__END__

