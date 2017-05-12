package Gtk2::Ex::TreeMaker::FlatInterface;

our $VERSION = '0.10';

use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

B<Gtk2::Ex::TreeMaker::FlatInterface> - This module is not to be used directly. It is called from Gtk2::Ex::TreeMaker as a utility module.

=head1 DESCRIPTION

This module contains a utility method C<sub flat_to_tree>. This utility method will accept an array of arrays (a set of relational records) as its input and then return a treelike data structure that is in-turn used by the Gtk2::Ex::TreeMaker to spin the Gtk2::TreeModel.

=head1 METHODS

=head2 Gtk2::Ex::TreeMaker::FlatInterface->new

Accepts no arguments. Just returns a reference to the object

=cut

sub new {
	my ($class) = @_;
	my $self  = {};
	$self->{column_count} = undef;
	$self->{record_count} = 0;
	bless ($self, $class);
	return $self;
}

=head2 Gtk2::Ex::TreeMaker::FlatInterface->flat_to_tree

Accepts an array of arrays (a set of relational records) as its input. Returns a special tree-like data structure that is then used by the Gtk2::Ex::TreeMaker to spin the Gtk2::TreeModel.

Here is a sample input:

	my $recordset = [
		['Texas','Dallas','Fruits','Dec-2003','300',0,1,'red'],
		['Texas','Dallas','Veggies','Jan-2004','120',1,0,'blue'],
		['Texas','Austin','Fruits','Nov-2003','310',1,1,'white'],
	];

Here is the corresponding output:

   my $output = {
          'Node' => [
                      {
                        'Node' => [
                                    {
                                      'Node' => [
                                                  {
                                                    'Node' => [
                                                                {
                                                                  'text' => '310',
                                                                  'editable' => 1,
                                                                  'background' => 'white',
                                                                  'hyperlinked' => 1,
                                                                  'Name' => 'Nov-2003'
                                                                }
                                                              ],
                                                    'Name' => 'Fruits'
                                                  }
                                                ],
                                      'Name' => 'Austin'
                                    },
                                    {
                                      'Node' => [
                                                  {
                                                    'Node' => [
                                                                {
                                                                  'text' => '120',
                                                                  'editable' => 1,
                                                                  'background' => 'blue',
                                                                  'hyperlinked' => 0,
                                                                  'Name' => 'Jan-2004'
                                                                }
                                                              ],
                                                    'Name' => 'Veggies'
                                                  },
                                                  {
                                                    'Node' => [
                                                                {
                                                                  'text' => '300',
                                                                  'editable' => 0,
                                                                  'background' => 'red',
                                                                  'hyperlinked' => 1,
                                                                  'Name' => 'Dec-2003'
                                                                }
                                                              ],
                                                    'Name' => 'Fruits'
                                                  }
                                                ],
                                      'Name' => 'Dallas'
                                    }
                                  ],
                        'Name' => 'Texas'
                      }
                    ],
          'Name' => 'ROOT'
        };

This data structure is really the key input into the Gtk2::Ex::TreeMaker module. If you can provide this data structure through external means, then we can build Gtk2::Ex::TreeMaker using that. More on this later...

=cut

sub flat_to_tree {
	my ($self, $data_attributes, $flat) = @_;
	my @attributes;
	foreach my $attr (@$data_attributes) {
		foreach my $key (keys %$attr) {
			push @attributes, $key;
		}
	}   
	my $intermediate = $self->_flat_to_intermediate(\@attributes, $flat);
	my $withroot = {};
	$withroot->{'ROOT'} = $intermediate;
	my $tree = _intermediate_to_tree($withroot);
	return $tree;
}

# This is a private method
sub _flat_to_intermediate {
	my ($self, $attributes, $flat) = @_;
	my $intermediate = {};  
	foreach my $record (@$flat) {
		my $sub_intermediate = $intermediate;
		$self->{record_count}++;
		if ($self->{column_count}) {
			if ($self->{column_count} != $#{@$record}) {
				carp "Warning ! Input record expected ".($self->{column_count}+1)." columns; got ".($#{@$record}+1).
					" at record number ".$self->{record_count};
			}
		} else {
			$self->{column_count} = $#{@$record};
		}
		foreach (my $i=0; $i<$#{@$record}-$#{@$attributes}; $i++){
			my $column = $record->[$i];
			next unless $column;
			if (!exists $sub_intermediate->{$column}) {
				$sub_intermediate->{$column} = {};
			}
			$sub_intermediate = $sub_intermediate->{$column};        
		}
		foreach (my $i=$#{@$record}-$#{@$attributes}; $i<=$#{@$record}; $i++){
			$sub_intermediate->{$attributes->[$i-$#{@$record}+$#{@$attributes}]} = $record->[$i]; 
		}
	}
	return $intermediate;
}

# This is a private method
sub _intermediate_to_tree {
	my ($intermediate) = shift;
	foreach my $singlekey ( sort keys %$intermediate) {
		my $node = {};
		$node->{'Name'} = $singlekey;
		foreach my $key (sort keys %{$intermediate->{$singlekey}}) {
			if (ref ($intermediate->{$singlekey}->{$key}) eq 'HASH') {
				$node->{'Node'} = [] unless ($node->{'Node'});
				my $newtree = {};
				$newtree->{$key} = $intermediate->{$singlekey}->{$key};
				push @{$node->{'Node'}}, _intermediate_to_tree($newtree);
			} else {
				$node->{$key} = $intermediate->{$singlekey}->{$key};
			}
		}
		return $node;
	}
}

1;

__END__

=head1 AUTHOR

Ofey Aikon, C<< <ofey.aikon at gmail dot com> >>

=head1 BUGS

You tell me. Send me an email !

=head1 ACKNOWLEDGEMENTS

To the wonderful gtk-perl-list

=head1 COPYRIGHT & LICENSE

Copyright 2004 Ofey Aikon, All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 59
Temple Place - Suite 330, Boston, MA  02111-1307  USA.

=cut
