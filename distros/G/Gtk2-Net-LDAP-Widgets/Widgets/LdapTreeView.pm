package Gtk2::Net::LDAP::Widgets::LdapTreeView;
#---[ pod head ]---{{{

=head1 NAME

Gtk2::Net::LDAP::Widgets::LdapEntryView - LDAP entry viewport

=head1 SYNOPSIS

    use Gtk2::Net::LDAP::Widgets;

  $treeView = Gtk2::Net::LDAP::Widgets::LdapTreeView->new($ldap_source, 'ou=OrgStructure,dc=example,dc=com', 'objectClass=top');
	# expand entries two tree levels below:
  $treeView->expand_row(Gtk2::TreePath->new_from_string('0'), 0);
  $treeView->expand_row(Gtk2::TreePath->new_from_string('0:0'), 0);
	# ... later ...
	print join(", ", $treeView->get_dn);
=head1 ABSTRACT

Gtk2::Net::LDAP::Widgets::LdapEntryView is a child class to L<Gtk2::TreeView> 
and is used to create a Gtk2 component which lets the user select LDAP entry/entries
displayed in a tree-like structure.

Note: there might be problems with displaying the tree when an interactive 
filter is set since there may be problems building the tree if all ancestors 
for an entry aren't included in the search result.

So it's advised to carefully control the filters that are fed to this component.

=cut

#---}}}
use utf8;
use strict;
use vars qw(@ISA $VERSION);

use Net::LDAP;
use Net::LDAP::Util;
use Gtk2 -init;
use Data::Dumper;
use Gtk2::Net::LDAP::Widgets::DistinguishedName;
use Gtk2::Net::LDAP::Widgets::Util;

@ISA = qw(Gtk2::TreeView);

our $VERSION = "2.0.1";

our $rdn_column = 0;
our $bool_column = 1;
our $dn_column = 2;


use overload
q{""} => 'to_string';

#---[ sub new ]---{{{

=head1 CONSTRUCTOR

=over 4

=item new ( ldap_source, base_dn, static_filter, interative_filter, single_selection)

Creates a new Gtk2::Net::LDAP::Widgets::LdapTreeView object.

C<ldap_source> the L<Net::LDAP> object which is an active connection to an LDAP server

C<base_dn> the base DN of LDAP search operations

C<static_filter> the static filter that will be logically AND-ed with all filters executed by this selector

C<interactive_filter> the additional filter that usually comes from filter box components

C<single_selection> whether to use single selection mode (otherwise multiple selection is posible)

=back

=cut
sub new {
  my $class = shift;
  my $self = $class->SUPER::new;
  $self->{ldap_source} = shift;
  $self->{base_dn} = shift;
  $self->{static_filter} = shift;
  defined($self->{static_filter}) or $self->{static_filter} = '';
  $self->{interactive_filter} = shift;
  defined($self->{interactive_filter}) or $self->{interactive_filter} = '';
  $self->{single_selection} = shift;

  $self->{selectedDN} = undef;



  bless $self, $class;
  $self->set_rules_hint (1);
  $self->get_selection->set_mode ('multiple');
  ###
  # 1st column
  my $renderer = Gtk2::CellRendererText->new;
  my $col_offset = $self->insert_column_with_attributes
    (-1, "Entry", $renderer,
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
  $renderer->signal_connect (toggled => \&LdapTreeView_item_toggled, $self);
  $col_offset = $self->insert_column_with_attributes
    (-1, "Y/N", $renderer,
     active => 1
    );
  $column = $self->get_column ($col_offset - 1);
  $column->set_clickable (1);
  #$column->set_sizing ('fixed');
  #$column->set_fixed_width (50);

  $self->refresh_model;
  bless $self, $class;
}
#---}}}

#---[ sub refresh_model ]---{{{
=head2 refresh_model

Refresh the data model - re-execute the search with the current filters

=cut
sub refresh_model {
  my $self = shift;
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
  my $tree_model = Gtk2::TreeStore->new(qw/Glib::String Glib::Boolean Glib::String/);
  my $prev_dn = undef;
  my $child; 
  my $entry;
  my @ancestors_stack = ();
  my %dn_iters;
  #push @parents, $toplevel;
  foreach $entry (@entries) {
    my $dn = Gtk2::Net::LDAP::Widgets::DistinguishedName->new($entry->dn);
    my $rdn;
    my $parent = $ancestors_stack[$#ancestors_stack];
    if (defined($prev_dn) && $dn->isDescendant($prev_dn)) {
      # it's a child of the previous dn
      # print "$dn is a child of $prev_dn\n";
      # TODO: assert length($entry->dn) =okolo (rindex($entry->dn, $prev_dn) + length($prev_dn))
      # TODO: push the previous DN onto a stack

      # Push the parent to stack:
      push(@ancestors_stack, $prev_dn);
      $parent = $ancestors_stack[$#ancestors_stack];
      
    } else {
      # it might not be a descendant of the parent anymore. Search for the youngest ancestor:
      while(scalar(@ancestors_stack)) {
        $parent = pop(@ancestors_stack);
        if ($dn->isDescendant($parent)) {
          push(@ancestors_stack, $parent);
          last;
        }
      }
      #$rdn = $dn->getRdn($parent);
    }
    # determine the RDN:
    $rdn = $dn->getRdn($parent);
    #print " ...so its RDN is $rdn\n";
    #print "number of components:".$dn->getLength."\n";

    # Determine the Iter-a of the super element in the tree model (if there's 
		# no parent, then iter is undefined and tree's top level is created):
    my $iter = undef;
    if (defined($parent)) {
      $iter = $dn_iters{$parent->{dn}};
    }

    $child = $tree_model->append($iter);

    $tree_model->set($child,
        0 => $rdn,
        1 => 0,
        2 => ($dn->{dntext})
        );
    $dn_iters{$dn->{dn}} = $child;
    $prev_dn = $dn;
  }

  $self->set_model($tree_model);

}
#---}}}

# by OLO
# czw mar 17 17:51:20 CET 2005
# Conversion of self to string:
sub to_string {
  my $self  = shift;
  return $self->{class}.' "'.\$self.'"';
}

#---[ sub get_dn ]---{{{

=head2 get_dn

Return the list of selected entries' Distinguished Names.

The list has at most one entry if single_selection is set to 1.

=cut
sub get_dn {
  my $self  = shift;
  my @dn_list;
  
  if ($self->{single_selection}) {
    push @dn_list, $self->{selectedDN};
  } else {
    my $model = $self->get_model;
    $model->foreach( sub {
      my $model = shift;
      my $path = shift;
      my $iter = shift;
      if ($model->get ($iter, $bool_column) > 0) {
        # The entry is selected:
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
#---}}}

#---[ sub set_dn ]---{{{

=head2 set_dn

=over 4

=item set_dn( dn_list )

Sets the state of entries specified by DNs in dn_list to "selected" and unselects all other entries.

C<dn_list> list of Distinguished Names of entries to select

=back

=cut
sub set_dn(@) {
  my $self  = shift;
  my @dn_list = @_;

  # Build a hash map to speed up lookups:
  my %dn_hash = map { my $DN = new Gtk2::Net::LDAP::Widgets::DistinguishedName($_); ($DN->{dn}) => 1; } @dn_list;

  my $model = $self->get_model;
  $model->foreach( sub {
    my $model = shift;
    my $path = shift;
    my $iter = shift;
    my $row_dn = $model->get ($iter, $dn_column);
    my $row_DistinguishedName = new Gtk2::Net::LDAP::Widgets::DistinguishedName($row_dn);
    if ($dn_hash{$row_DistinguishedName->{dn}}) {
      # DN is on the supplied list, select the row:
      $model->set ($iter, $bool_column, 1);
    } else {
      # DN is not on the supplied list, deselect the row:
      $model->set ($iter, $bool_column, 0);
    }
    return 0;
  });
}
#---}}}

sub LdapTreeView_item_toggled {
  #my $self  = shift;
  my ($cell, $path_str, $self) = @_;
  my $model = $self->get_model;
  my $path = Gtk2::TreePath->new_from_string ($path_str);
  #print "$path_str\n$path\n";
  my $column = $cell->get_data ("column");
  # get toggled iter
  my $iter = $model->get_iter ($path);
  #print Dumper($iter);
  my ($toggle_item) = $model->get ($iter, $column);

  # do something with the value
  my $selectedDN = $model->get($iter, $dn_column);
  #print "Row: ".$model->get($iter, 0)."\n";
  #print "DN: ".$model->get($iter, 2)."\n";
  #print "toggle_item before: $toggle_item\n";

  if ($self->{single_selection}) {
    $model->foreach( sub { my $model = shift; my $path = shift; my $iter = shift; $model->set ($iter, $column, 0); return 0; } );
    $model->set ($iter, $column, 1);
    $self->{selectedDN} = $selectedDN;
  } else {
    $toggle_item ^= 1;
    $model->set ($iter, $column, $toggle_item);
  }

}

#---[ sub set_interactive_filter ]---{{{

=head2 set_interactive_filter

=over 4

=item set_interactive_filter ( interactive_filter )

Sets the interactive filter which is an additional filter applied to LDAP 
searches, usually provided by interactive components like a search/filter box 
and refreshes the data model, re-executing LDAP search and building a new data 
tree. 

C<interactive_filter> a string representation of an LDAP filter

=back

=cut
sub set_interactive_filter($) {
  my $self  = shift;
  $self->{interactive_filter} = shift;
  $self->refresh_model;
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

