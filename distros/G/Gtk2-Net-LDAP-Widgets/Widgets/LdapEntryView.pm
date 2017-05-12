package Gtk2::Net::LDAP::Widgets::LdapEntryView;
#---[ pod head ]---{{{

=head1 NAME

Gtk2::Net::LDAP::Widgets::LdapEntryView - LDAP entry viewport

=head1 SYNOPSIS

    This component is mostly used by other components and isn't meant to be 
used directly. Read the source in case of any needs to do that.

=cut

#---}}}
use utf8;
use strict;
use vars qw(@ISA $VERSION);

use Carp qw(cluck);
use Net::LDAP;
use Net::LDAP::Util;
use Gtk2 -init;
use Data::Dumper;
use Gtk2::Net::LDAP::Widgets::Util;

@ISA = qw(Gtk2::TreeView);

our $VERSION = "2.0.1";
our $dn_column = 0;
our $bool_column = 1;


use overload
q{""} => 'to_string';

# by OLO
# czw mar 17 17:51:34 CET 2005
# Constructor:
sub new {
  my $class = shift;
  my $self = $class->SUPER::new;
  $self->{ldap_source} = shift;
  $self->{base_dn} = shift;
  $self->{static_filter} = shift;
  $self->{interactive_filter} = shift;
  $self->{single_selection} = shift;

  $self->{selectedDN} = undef;

  ###
  # 1st column
  my $renderer = Gtk2::CellRendererText->new;
  my $col_offset = $self->insert_column_with_attributes
    (-1, "DN", $renderer,
     text => 0);
  my $column = $self->get_column ($col_offset - 1);
  $column->set_clickable (1);

  ###
  # 2nd column
  $renderer = Gtk2::CellRendererToggle->new;
  $renderer->set (xalign => 0.0);
  $renderer->set_data (column => 1);
  if ($self->{single_selection}) {
    $renderer->set_radio (1);
  }
  $renderer->signal_connect (toggled => \&LdapEntryView_item_toggled, $self);
  $col_offset = $self->insert_column_with_attributes
    (-1, "Y/N", $renderer,
     active => 1
    );
  $column = $self->get_column ($col_offset - 1);
  $column->set_clickable (1);

  bless $self, $class;
  $self->refresh_model;

  bless $self, $class;
}

# by OLO
# czw mar 17 17:51:20 CET 2005
# Conversion of self to string:
sub to_string {
  my $self  = shift;
  return $self->{class}.' "'.\$self.'"';
}

# by OLO
# wto kwi 19 12:15:31 CEST 2005
# Returns the list of selected entries' Distinguished Names.
sub get_dn {
  my $self  = shift;
  my @dn_list;
  if ($self->{single_selection}) {
    push @dn_list, $self->{selectedDN};
  } else {
    #TODO: multiple
    my $model = $self->get_model;
    $model->foreach( sub {
      my $model = shift;
      my $path = shift;
      my $iter = shift;
      if ($model->get ($iter, $bool_column) > 0) {
        # Wpis jest zaznaczony:
        push(@dn_list, $model->get ($iter, $dn_column));
      }
      return 0;
    });
  }
  
  #print "Selected:\n";
  #print Dumper(\@dn_list);
  #print "\n";
  return @dn_list;
}

sub LdapEntryView_item_toggled {
  my ($cell, $path_str, $self) = @_;
  my $model = $self->get_model;
  my $path = Gtk2::TreePath->new_from_string ($path_str);
  my $column = $cell->get_data ("column");
  # get toggled iter
  my $iter = $model->get_iter ($path);
  #print Dumper($iter);
  my ($toggle_item) = $model->get ($iter, $column);

  # do something with the value
  my $selectedDN = $model->get($iter, $dn_column);
  #print "val: ".$model->get($iter, $column)."\n";
  #print "toggle_item before: $toggle_item\n";
  #$toggle_item ^= 1;
  #print "toggle_item after: $toggle_item\n";
  #$model->set ($iter, $column, $toggle_item);

  # set new value
  if ($self->{single_selection}) {
    $model->foreach( sub { my $model = shift; my $path = shift; my $iter = shift; $model->set ($iter, $column, 0); return 0; } );
    $model->set ($iter, $column, 1);
    $self->{selectedDN} = $selectedDN;
  } else {
    $toggle_item ^= 1;
    $model->set ($iter, $column, $toggle_item);
  }

}

# by OLO
# wto kwi 19 13:19:38 CEST 2005
# Changes the interactive filter and refreshes data model
sub set_interactive_filter($) {
  my $self  = shift;
  $self->{interactive_filter} = shift;
  $self->refresh_model;
}

sub refresh_model {
  my $self  = shift;
  my $static_filter = $self->{static_filter};
  my $interactive_filter = $self->{interactive_filter};
  # Remove superfluous pairs of parentheses:
  $interactive_filter = filter_trim_outer_parens($interactive_filter);
  $static_filter = filter_trim_outer_parens($static_filter);

  my $compositeFilter;
  if (length($interactive_filter) > 3) {
    $compositeFilter = '(&('.$static_filter.')('.$interactive_filter.'))';
  } else {
    $compositeFilter = '('.$static_filter.')';
  }
  #print "LdapTreeView composite filter: $compositeFilter\n";

  my $result = $self->{ldap_source}->search(filter => $compositeFilter, base => $self->{base_dn}, attrs => ['dn']);
  my @entries = $result->sorted;
  my $newModel = Gtk2::ListStore->new (qw/Glib::String Glib::Boolean/);

  foreach my $entry (@entries) {
    #print "Entry: ".$entry->dn."\n";
    my $value = $newModel->set ($newModel->append, $dn_column => $entry->dn, $bool_column => 0);
  }
  $self->set_model($newModel);
}

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
