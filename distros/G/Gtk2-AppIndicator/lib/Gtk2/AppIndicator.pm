package Gtk2::AppIndicator;

use 5.006;
use strict;
use warnings;
use Carp;
use Gtk2;

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
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.15';

#sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

#    my $constname;
#    our $AUTOLOAD;
#    ($constname = $AUTOLOAD) =~ s/.*:://;
#    croak "&Gtk2::AppIndicator::constant not defined" if $constname eq 'constant';
#    my ($error, $val) = constant($constname);
#    if ($error) { croak $error; }
#    {
#	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
#	    *$AUTOLOAD = sub { $val };
#XXX	}
#    }
#    goto &$AUTOLOAD;
#}

require XSLoader;
XSLoader::load('Gtk2::AppIndicator', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub new {
  my $class=shift;
  my $application_id=shift or die "Gtk2::AppIndicator->new needs an application id";
  my $iconname=shift or die "Gtk2::AppIndicator->new needs an icon name";
  my $type=shift;
  if (not(defined($type))) { $type="application-status"; }
  
  my $tp=-1;
  if ($type eq "application-status") { $tp=1; }
  elsif ($type eq "communications") { $tp=2; }
  elsif ($type eq "system-services") { $tp=3; }
  elsif ($type eq "hardware") { $tp=4; }
  elsif ($type eq "other") { $tp=5; }
  
  if ($tp==-1) { die "Gtk2::AppIndicator->new -> category of indicator must be one of 'application-status','communications','system-services','hardware','other'}"; }
  
  my $obj={};
  bless $obj,$class;
  $obj->{ind}=appindicator_new($application_id,$iconname,$tp);
  return $obj;
}

sub get_category {
	my $self=shift;
	return appindicator_get_category($self->{ind});
}

sub set_icon_theme_path {
	my $self=shift;
	my $path=shift;
	appindicator_set_icon_theme_path($self->{ind},$path);
}

sub get_icon_theme_path {
	my $self=shift;
	return appindicator_get_icon_theme_path($self->{ind});
}

sub set_icon_name_active {
	my $self=shift;
	my $name=shift;
	my $text=shift;
	if (not(defined($text))) { $text="no text"; }
	appindicator_set_icon_name_active($self->{ind},$name,$text);
}

sub get_icon_name_active {
	my $self=shift;
	return appindicator_get_icon($self->{ind});
}

sub get_icon_desc_active {
	my $self=shift;
	return appindicator_get_icon_desc($self->{ind});
}

sub get_id {
	my $self=shift;
	return appindicator_get_id($self->{ind});
}



sub set_icon_name_attention {
	my $self=shift;
	my $name=shift;
	my $text=shift;
	if (not(defined($text))) { $text="no text"; }
	appindicator_set_icon_name_attention($self->{ind},$name,$text);
}

sub get_icon_name_attention {
	my $self=shift;
	return appindicator_get_attention_icon($self->{ind});
}

sub get_icon_desc_attention {
	my $self=shift;
	return appindicator_get_attention_icon_desc($self->{ind});
}


sub set_active {
	my $self=shift;
	appindicator_set_active($self->{ind});
}

sub set_attention {
	my $self=shift;
	appindicator_set_attention($self->{ind});
}

sub set_passive {
	my $self=shift;
	appindicator_set_passive($self->{ind});
}

sub set_status {
	my $self=shift;
	my $status=shift;
	if ($status eq "passive") { $self->set_passive(); }
	elsif ($status eq "active") { $self->set_active(); }
	elsif ($status eq "attention") { $self->set_attention(); }
	else { die "usage: set_status <'passive'|'active'|'attention'>"; }
}

sub get_status {
	my $self=shift;
	return appindicator_get_status($self->{ind});
}


sub set_menu {
	my $self=shift;
	my $menu=shift;
	$self->{menu}=$menu;
	appindicator_set_menu($self->{ind},$menu);
}

sub get_menu {
	my $self=shift;
	return $self->{menu};
}

sub set_secondary_active_target {
	my $self=shift;
	my $widget=shift;
	$self->{secondary}=$widget;
	appindicator_set_secondary_active_target($self->{ind},$widget);
}

sub get_secondary_active_target {
	my $self=shift;
	return $self->{secondary};
}

sub set_title {
	my $self=shift;
	my $title=shift;
	appindicator_set_title($self->{ind},$title);
}

sub get_title {
	my $self=shift;
	return appindicator_get_title($self->{ind});
}

sub set_label {
	my $self=shift;
	my $label=shift or die "usage: set_label(label,guide)";
	my $guide=shift or die "usage: set_label(label,guide)";
	appindicator_set_label($self->{ind},$label,$guide);
}

sub get_label {
	my $self=shift;
	return appindicator_get_label($self->{ind});
}

sub get_guide {
	my $self=shift;
	return appindicator_get_label_guide($self->{ind});
}





1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Gtk2::AppIndicator - Perl extension for libappindicator

=head1 SYNOPSIS

  use Gtk2 '-init';
  use Gtk2::AppIndicator;
  use Cwd;

  # Initialize the status icon. an_icon_name must be present 
  # at the icon theme path location, with an image extension like
  # .jpg, .png or .svg, etc.
  $status_icon=Gtk2::AppIndicator->new("AnAppName","an_icon_name");
 
  # If you want to be in control over your icon location, you 
  # can set it manually. It must be an absolute path, in order
  # to work. 
  my $absolute_current_working_directory=getcwd();
  my $acwd=$absolute_current_working_directory;
  $status_icon->set_icon_theme_path($acwd);

  # Optionally set different icons 
  # $status_icon->set_icon_name_active("an_icon_name");
  # $status_icon->set_icon_name_attention("an_other_icon_name");
  # $status_icon->set_icon_name_passive("an_other_icon_name");
 
  # Add a menu to the indicator
  my $menu=Gtk2::Menu->new();
  my $showcp=Gtk2::CheckMenuItem->new_with_mnemonic("_Show My App");
  $showcp->set_active(1);
  $showcp->signal_connect("toggled",sub { hide_show($window,$showcp); });
  my $quit=Gtk2::MenuItem->new_with_mnemonic("_Quit");
  $quit->signal_connect("activate",sub { Gtk->main_quit(); });
  
  $menu->append($showcp);
  $menu->append(Gtk2::SeparatorMenuItem->new());
  $menu->append($quit);
  $status_icon->set_menu($menu);

  # Show our icon and set the state
  $menu->show_all();
  $status_icon->set_active();


=head1 DESCRIPTION

This module gives an interface to the new ubuntu Unity libappindicator stuff.

=head1 FUNCTIONS

 $ind=Gtk2::AppIndicator->new($application_id,$active_icon_name [,$category])
 
Creates a new application indicator object with given name (id) and icon name for the active icon.
Category must be one of  { 'application-status','communications','system-services','hardware','other' }
if set. if not set, it defaults to 'application-status'.

 $ind->set_icon_theme_path($path)
 
Set the icon theme path to 'path'. This is where icons should be found with names like <active_icon_name>.png.

 $ind->get_icon_theme_path() 
 
Returns the (previously written) icon theme path, or undefined if not set.

 $ind->get_category()
 
Returns the previously set category with the new function.

 $ind->get_id()
 
Returns the application id given to the new function.

 $ind->set_icon_name_active($name)
 
Sets the icon name for the active icon.

 $ind->get_icon_name_active()
 
Returns the name of the icon for active state.

 $ind->set_icon_name_attention($name)
 
Sets the icon name for the attention icon

 $ind->get_icon_name_attention()
 
Returns the name of the icon for attention state.

  $ind->set_active()
  
Makes the application indicator active.

  $ind->set_attention()
  
Makes the application indicator show the attention icon.

  $ind->set_passive()
  
Makes the application indicator enter passive state, not showing any icon

  $ind->set_state($state)
  
Sets application indicator in the given state, one of {'active','passive','attention'}.

  $ind->get_state()
  
Returns the current state of the application indicator.

  $ind->set_menu($menu)
  
Sets the popup menu for the indicator icon.

  $ind->get_menu()
  
Returns the current menu (not from the C code, but as stored in the perl object)

  $ind->set_secondary_activate_target($widget)
  
Sets the secondary active target (under the middle mouse button) to $widget

  $ind->get_secondary_activate_target()
  
Returns the current secondary active target (not from the C code, but as stored in the perl object)

=head1 AUTHOR

Hans Oesterholt, E<lt>oesterhol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Hans Oesterholt <oesterhol@cpan.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License, which comes with Perl.

=cut
