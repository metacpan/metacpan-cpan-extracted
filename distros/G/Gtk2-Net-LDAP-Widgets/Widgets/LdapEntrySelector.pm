package Gtk2::Net::LDAP::Widgets::LdapEntrySelector;

#---[ pod head ]---{{{

=head1 NAME

Gtk2::Net::LDAP::Widgets::LdapEntrySelector - LDAP entry selection window

=head1 SYNOPSIS

    use Gtk2::Net::LDAP::Widgets;

    my $entryPopup = Gtk2::Net::LDAP::Widgets::LdapEntrySelector->new ($parent_window,
      $ldap_source,
      'dc=example,dc=com',
      'objectClass=inetorgperson',
      'init_interactive_filter' => 'smith',
      'single_selection' => 1,
      'interactive_filter_type' => 'simple'
    );
    $entryPopup->signal_connect (response => sub {
      my ($popup, $response) = @_;
      if($response =~ 'accept') {
        print "Selected entry DN: ".$entryPopup->get_dn;
      } else {
				print "No existing entry selected.\n";
      }
      $_[0]->destroy;
      });
    $entryPopup->show_all;


=head1 ABSTRACT

Gtk2::Net::LDAP::Widgets::LdapEntrySelector is a child class to L<Gtk2::Dialog> 
and is used to create a Gtk2 dialog which lets the user search for a LDAP entry 
and select it.  

The dialog is equipped with a search/filter box.

=cut

#---}}}
use utf8;
use strict;
use warnings;
use vars qw(@ISA $VERSION);

use Carp qw(cluck);
use Net::LDAP;
use Net::LDAP::Util;
use Gtk2 -init;
use Data::Dumper;
use Gtk2::Net::LDAP::Widgets::LdapEntryView;
use Gtk2::Net::LDAP::Widgets::Util;

@ISA = qw(Gtk2::Dialog);

our $VERSION = "2.0.1";


use overload
q{""} => 'to_string';

# determine the filter (internal utility method)
sub _get_filter {
  my $self  = shift;
  if ($self->{interactive_filter_type} eq 'ldap') {
    return($self->{entryInteractiveFilter}->get_text);
  } elsif ($self->{interactive_filter_type} eq 'none') {
    return('');
  } elsif ($self->{interactive_filter_type} eq 'simple') {
    return('cn=*'.$self->{entryInteractiveFilter}->get_text.'*');
  }
  return('');
}

#---[ sub new ]---{{{

=head1 CONSTRUCTOR

=over 4

=item new ( parent, ldap_source, base_dn, static_filter, named parameters )

Creates a new Gtk2::Net::LDAP::Widgets::LdapEntrySelector object.

C<parent> the L<Gtk2::Window> which will be parent of this L<Gtk2::Dialog>

C<ldap_source> the L<Net::LDAP> object which is an active connection to an LDAP server

C<base_dn> the base DN of LDAP search operations

C<static_filter> the static filter that will be logically AND-ed with all filters executed by this selector

=back

=head2 named parameters

=over 4

=item init_interactive_filter =E<gt> 'some ldap filter'

The string to be initially put in the filter box

=item single_selection =E<gt> 0 | 1

Whether to use single selection mode (otherwise multiple selection is posible)


=item interactive_filter_type =E<gt> 'ldap' | 'simple' | 'none'

The type of filter box: 'ldap' supports full LDAP filter syntax, 'simple' does a substring search against the "cn" attribute, 'none' disables the search/filter box.

=back 

=cut
sub new {
  my $class = shift;
  my $self = $class->SUPER::new('Choose LDAP entry/entries', shift, 'destroy-with-parent',
                              'gtk-ok' => 'accept', 'gtk-cancel' => 'reject');
  $self->set_modal(1);
  $self->{ldap_source} = shift;
  $self->{base_dn} = shift;
  $self->{static_filter} = shift;

  my %named_params = @_;
  $self->{init_interactive_filter} = $named_params{'init_interactive_filter'};
  $self->{single_selection} = $named_params{'single_selection'};
  $self->{interactive_filter_type} = $named_params{'interactive_filter_type'};
  # possible values: 'ldap', 'simple', 'none':
  if (! $self->{interactive_filter_type}) {
    $self->{interactive_filter_type} = 'ldap';
  }


  my $btnFiltruj = Gtk2::Button->new_with_mnemonic ('_Filter');
  if ($self->{interactive_filter_type} ne 'none') {
    # The filter horizontal box:
    my $hboxFilter = Gtk2::HBox->new;
    my $labelFilter = Gtk2::Label->new;
    if ($self->{interactive_filter_type} eq 'ldap') {
      $labelFilter->set_markup("<b>LDAP filter</b>:");
    } elsif ($self->{interactive_filter_type} eq 'simple') {
      $labelFilter->set_markup("Search:");
    } else {
      $labelFilter->set_markup("<b>filter</b>:");
    }
    $hboxFilter->pack_start ($labelFilter, 0, 0, 5);
    my $entryInteractiveFilter = Gtk2::Entry->new;
    $entryInteractiveFilter->set_text($self->{init_interactive_filter});
    $hboxFilter->pack_start ($entryInteractiveFilter, 1, 1, 5);

    $hboxFilter->pack_start ($btnFiltruj, 1, 1, 5);

    $self->{entryInteractiveFilter} = $entryInteractiveFilter;
    $self->vbox->pack_start ($hboxFilter, 0, 0, 5);
  }


  # Results list component:
  bless $self, $class;
  $self->{listEntriesView} = Gtk2::Net::LDAP::Widgets::LdapEntryView->new($self->{ldap_source}, $self->{base_dn}, $self->{static_filter},
          $self->_get_filter, $self->{single_selection});
  my $scrollwin = Gtk2::ScrolledWindow->new;
  $scrollwin->set_policy ('never', 'automatic');
  $scrollwin->set_shadow_type ('in');
  $scrollwin->add($self->{listEntriesView});
  $self->vbox->pack_start ($scrollwin, 1, 1, 5);

  $self->set_default_size(640, 480);

  $btnFiltruj->signal_connect (clicked => sub { 
    $self->refresh_list;
  });

  bless $self, $class;
}
#---}}}

# by OLO
# czw mar 17 17:51:20 CET 2005
# Conversion of self to string:
sub to_string {
  my $self  = shift;
  return $self->{class}.' "'.\$self.'"';
}


#---[ sub refresh_list ]---{{{
=head2 refresh_list

Refresh the entries list - re-execute the search with the filter determined by 
the search/filter box.

=cut
sub refresh_list {
  my $self = shift;
  my $newfilter = $self->_get_filter;
  $self->{listEntriesView}->set_interactive_filter($newfilter);
}
#---}}}

#---[ sub get_dn ]---{{{

=head2 get_dn

Return the list of selected entries' Distinguished Names.

The list has at most one entry if single_selection is set to 1.

=cut
sub get_dn {
  my $self  = shift;
  return $self->{listEntriesView}->get_dn;
}
#---}}}

1;

__END__

#---[ pod end ]---{{{

=head1 SEE ALSO

L<Gtk2::Net::LDAP::Widgets>
L<Gtk2>
L<Net::LDAP>

=head1 AUTHOR

Aleksander Adamowski, E<lt>cpan@olo.org.plE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005,2008 by Aleksander Adamowski

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut

#---}}}
