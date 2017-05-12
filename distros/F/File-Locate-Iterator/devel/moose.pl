#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

# uncomment this to run the ### lines
use Smart::Comments;


{
  require MooseX::Iterator::Locate;
  my $meta = MooseX::Iterator::Locate->meta;
  my $attr = $meta->get_attribute('database_file');
  {
    my $default = $attr->default;
    ### $default
  }

  my $it = MooseX::Iterator::Locate->new (glob => '*.c');
  {
    my $default = $attr->default($it);
    ### $default
  }
  exit 0;
}

{
  # peek vs next ...

  require MooseX::Iterator::Array;
  my $iter = MooseX::Iterator::Array->new
    (collection => [ 1, 2 ]);

  my @peek = $iter->peek;
  my @next = $iter->next;
  ### @peek
  ### @next

  @peek = $iter->peek;
  @next = $iter->next;
  ### @peek
  ### @next

  @peek = $iter->peek;
  @next = $iter->next;
  ### @peek
  ### @next

  exit 0;

}

{
  require MooseX::Iterator::Locate;
  # (fli => File::Locate::Iterator->new);
  my $it = MooseX::Iterator::Locate->new (glob => '*.c');
  print $it,"\n";
  print $it->next,"\n";
  print $it->peek,"\n";
  print $it->next,"\n";
  print $it->next,"\n";

  my $meta = MooseX::Iterator::Locate->meta;
  print "attributes\n";
  for my $attr ($meta->get_all_attributes) {
    # ### ref: ref $attr
    print "  ", $attr->name, "\n";
  }

  print "methods\n";
  for my $method ( $meta->get_all_methods ) {
    print "  ", $method->fully_qualified_name, "\n";
    print "    name:         ", $method->name, "\n";
    print "    package_name: ", $method->package_name, "\n";
    print "    body:         ", $method->body, "\n";
    print "    associated_metaclass: ", $method->associated_metaclass, "\n";

  }

  exit 0;
}

{
  require MooseX::Iterator::Hash;
  my $it = MooseX::Iterator::Hash->new (collection => { a => 1, b=>2 });
  ### next: [ $it->next ]
  ### next: [ $it->next ]
  ### next: [ $it->next ]
  exit 0;
}

{
  require MooseX::Iterator::Array;
  # (fli => File::Locate::Iterator->new);
  my $it = MooseX::Iterator::Array->new (collection => [ 1, 2, 3]);
  print $it,"\n";
  print $it->next,"\n";
  ### peek: [ $it->peek ]
  ### next: [ $it->next ]
  ### next: [ $it->next ]
  ### next: [ $it->next ]
  exit 0;
}

