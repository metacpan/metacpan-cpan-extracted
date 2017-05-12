#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require MooseX::Iterator }
    or plan skip_all => "MooseX::Iterator not available -- $@";
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

BEGIN { plan tests => 161; }

my $reset_called;
{
  package TestLocate;
  use Moose;

  extends 'MooseX::Iterator::Locate';
  has 'mynewattr' => (is => 'rw', isa => 'Int');

  after 'reset' => sub {
    $reset_called = 1;
  };
}

#-----------------------------------------------------------------------------
# samp.zeros / samp.locatedb

# read $filename and return a list of strings from it
# each strings in $filename is terminated by a NUL \0
# the \0s are not included in the return
sub slurp_zeros {
  my ($filename) = @_;
  open my $fh, '<', $filename or die "Cannot open $filename: $!";
  binmode($fh) or die "Cannot set binary mode";
  local $/ = "\0";
  my @ret = <$fh>;
  close $fh or die "Error reading $filename: $!";
  foreach (@ret) { chomp }
  return @ret;
}

require FindBin;
require File::Spec;
my $samp_zeros    = File::Spec->catfile ($FindBin::Bin, 'samp.zeros');
my $samp_locatedb = File::Spec->catfile ($FindBin::Bin, 'samp.locatedb');

{
  my $it = TestLocate->new (database_file => $samp_locatedb);
  my @want = slurp_zeros ($samp_zeros);
  {
    my @got;
    while ($it->has_next) {
      push @got, $it->next;
    }
    is_deeply (\@got, \@want, 'samp.locatedb');
  }
  $reset_called = 0;
  $it->reset;
  is ($reset_called, 1, "after 'reset' hook");
  {
    my @got;
    while (defined (my $filename = $it->next)) {
      push @got, $filename;
    }
    is_deeply (\@got, \@want, 'samp.locatedb after reset()');
  }
}

{
  my $it = TestLocate->new (database_file => $samp_locatedb);
  my @want = slurp_zeros ($samp_zeros);

  is ($it->peek, $want[0], 'peek');
  is ($it->peek, $want[0]);
  is ($it->next, $want[0]);
  is ($it->peek, $want[1]);
  is ($it->peek, $want[1]);
  is ($it->next, $want[1]);
  $it->reset;
  is ($it->peek, $want[0]);
  is ($it->peek, $want[0]);
  is ($it->next, $want[0]);
  is ($it->peek, $want[1]);
  is ($it->peek, $want[1]);
  is ($it->next, $want[1]);
}

#-----------------------------------------------------------------------------
# inheritance

{
  my $it = TestLocate->new (database_file => $samp_locatedb);
  ok (! $it->does('nosuchrolename'), 'does() not nosuchrolename');
  ok ($it->does('MooseX::Iterator::Role'), 'does() MooseX::Iterator::Role');
}

#-----------------------------------------------------------------------------
# attributes

{
  my $meta = TestLocate->meta;
  my @want_names = (qw(database_file
                       database_fh
                       database_str
                       suffix
                       suffixes
                       glob
                       globs
                       regexp
                       regexps
                       use_mmap
                     ));
  {
    my %want_names = map { $_=>1 } @want_names;
    my %got_names;
    # get_all_attributes per Class::MOP::Class
    for my $attr ($meta->get_all_attributes) {
      $got_names{$attr->name} = 1;
    }
    foreach my $name (keys %got_names) {
      if (! $want_names{$name}) {
        delete $got_names{$name};
      }
    }
    is_deeply (\%got_names, \%want_names);
  }

  foreach my $name (@want_names) {
    my $attr = $meta->find_attribute_by_name($name);
    ok ($attr,   "$name - find_attribute_by_name");
    ok ($attr && $attr->has_documentation,   "$name - has_documentation");
    isnt ($attr && $attr->documentation, '', "$name - documentation");

    is ($attr && $attr->accessor, undef, "$name - accessor");
    ok ($attr && ! $attr->has_accessor,  "$name - has_accessor");

    is ($attr && $attr->reader, undef,          'reader');
    is ($attr && $attr->get_read_method, undef, 'get_read_method');
    ok ($attr && ! $attr->has_read_method,      'has_read_method');

    is ($attr && $attr->writer, undef,           'writer');
    is ($attr && $attr->get_write_method, undef, 'get_write_method');
    ok ($attr && ! $attr->has_write_method,      'has_write_method');

    is ($attr && $attr->clearer, undef, 'clearer');
    ok ($attr && ! $attr->has_clearer,  'has_clearer');
  }
}
{
  my $instance = TestLocate->new (database_file => $samp_locatedb);
  my $meta = $instance->meta;

  my $attr = $meta->find_attribute_by_name('database_file');
  ok ($attr, 'database_file - find_attribute_by_name');
  ok ($attr && $attr->has_default, 'database_file - has_default');

  ok ($attr && $attr->is_default_a_coderef,
      'database_file - is_default_a_coderef');
  is ($attr && $attr->default($instance),
      File::Locate::Iterator->default_database_file,
      'database_file - default per FLI->default_database_file');
}


#-----------------------------------------------------------------------------
# UseMMAP enum

{
  my $meta = TestLocate->meta;
  my $attr = $meta->find_attribute_by_name('use_mmap');
  ok ($attr,   "use_mmap - find_attribute_by_name");
  ok ($attr && $attr->has_type_constraint,
      'use_mmap - has_type_constraint');
}


#-----------------------------------------------------------------------------
# methods

{
  my $meta = TestLocate->meta;
  my @want_names = (qw(next
                       has_next
                       peek
                       reset
                     ));
  foreach my $name (@want_names) {
    my $method = $meta->find_method_by_name($name);
    ok ($method, "$name - find_method_by_name");
  }
  {
    my $name = 'new';
    ok ($meta->find_method_by_name($name), "$name - find_method_by_name");
  }

  my @want = slurp_zeros ($samp_zeros);
  my $new  = $meta->find_method_by_name('new');
  my $next = $meta->find_method_by_name('next');
  my $it = $new && $new->execute ('TestLocate',
                                  database_file => $samp_locatedb);
  isa_ok ($it, 'TestLocate',
          'new() via execute()');
  my $got = $it && $next && $next->execute($it);
  is ($got, $want[0], 'next() via execute()');
}

exit 0;
