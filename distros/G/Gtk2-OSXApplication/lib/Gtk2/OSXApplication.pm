package Gtk2::OSXApplication;

use 5.012003;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Gtk2::OSXApplication ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	CRITICAL_REQUEST
	GTK_TYPE_OSX_APPLICATION
	GTK_TYPE_OSX_APPLICATION_ATTENTION_TYPE
	INFO_REQUEST
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	CRITICAL_REQUEST
	GTK_TYPE_OSX_APPLICATION
	GTK_TYPE_OSX_APPLICATION_ATTENTION_TYPE
	INFO_REQUEST
);

our $VERSION = '0.06';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Gtk2::OSXApplication::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Gtk2::OSXApplication', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub new {
  my $class=shift;
  my $obj={};
  bless $obj,$class;
  $obj->{osxapp}=osxapplication_new();
  return $obj;
}

sub ready {
  my $self=shift;
  osxapplication_ready($self->{osxapp});
}

sub cleanup {
  my $self=shift;
  osxapplication_cleanup($self->{osxapp});
}

sub set_menu_bar {
  my $self=shift;
  my $menu_shell=shift;
  osxapplication_set_menu_bar($self->{osxapp},$menu_shell);
}

sub sync_menubar {
  my $self=shift;
  osxapplication_sync_menubar($self->{osxapp});
}

sub insert_app_menu_item {  
  my $self=shift;
  my $item=shift;
  my $index=shift;
  osxapplication_insert_app_menu_item($self->{osxapp},$item,$index);
}

sub set_window_menu {
  my $self=shift;
  my $item=shift;
  osxapplication_set_window_menu($self->{osxapp},$item);
}

sub set_help_menu {
  my $self=shift;
  my $item=shift;
  osxapplication_set_help_menu($self->{osxapp},$item);
}

sub set_dock_menu {
  my $self=shift;
  my $shell=shift;
  osxapplication_set_dock_menu($self->{osxapp},$shell);
}

sub set_dock_icon_pixbuf {  
  my $self=shift;
  my $pixbuf=shift;
  osxapplication_set_dock_icon_pixbuf($self->{osxapp},$pixbuf);
}

sub set_dock_icon_resource {  
  my $self=shift;
  my $name=shift;  
  my $type=shift;
  my $subdir=shift;
  osxapplication_set_dock_icon_resource($self->{osxapp},$name,$type,$subdir);
}

sub activate {
  my $self=shift;
  osxapplication_activate_app($self->{osxapp});
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Gtk2::OSXApplication - Perl extension for mac integration code GtkOSXApplication

=head1 SYNOPSIS

  use Gtk2 '-init';
  use Gtk2::OSXApplication;
  my $osxapp=new Gtk2::OSXApplication(); 
  ...
  $osxapp->set_menu_bar($bar);
  $osxapp->ready();

A sample from my CuePlay application:

  if ($os eq "darwin") {
    require Gtk2::OSXApplication;
    my $app=new Gtk2::OSXApplication();
    my $menubar=Gtk2::MenuBar->new();
    my $menu=Gtk2::Menu->new();
    my $item=Gtk2::MenuItem->new_with_label("Info");
    $item->set_submenu($menu);
    my $about=Gtk2::MenuItem->new_with_label("About");
    $menu->append($about);
    $menubar->append($item);
    $about->show();
    $item->show();
    $menu->show();
    $menubar->show();
    $app->set_menu_bar($menubar);
    $app->ready();
  }

=head1 DESCRIPTION

Creates an OSXApplication object. Do this asap after use Gtk2 '-init'.
Exports the following functions of GtkOSXApplication:

 $self->set_menu_bar($menu_shell)
 $self->sync_menubar()
 $self->insert_app_menu_item($menu_item,$index)
 $self->set_window_menu($menu_item)
 $self->set_help_menu($menu_item)
 $self->set_dock_menu($menu_shell)
 $self->set_dock_icon_pixbuf($pixbuf)
 $self->set_dock_icon_resource($name,$type,$subdir)


 $self->activate()

 Activates this application. Use this before using Gtk::Window->present();

=head1 AUTHOR

Hans Oesterholt, E<lt>oesterhol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by fam. Oesterholt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
