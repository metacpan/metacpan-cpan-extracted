#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2014 Kevin Ryde

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

# uncomment this to run the ### lines
#use Devel::Comments;

plan tests => 209;
require MooseX::Iterator::Locate;


#-----------------------------------------------------------------------------
# VERSION

my $want_version = 23;
is ($MooseX::Iterator::Locate::VERSION, $want_version, 'VERSION variable');
is (MooseX::Iterator::Locate->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { MooseX::Iterator::Locate->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { MooseX::Iterator::Locate->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}
# MooseX::Iterator::Locate->new object isn't an actual subclass, just a
# flavour of Iterator::Simple, so no object version number test


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
  my $it = MooseX::Iterator::Locate->new (database_file => $samp_locatedb);
  my @want = slurp_zeros ($samp_zeros);
  {
    my @got;
    while ($it->has_next) {
      push @got, $it->next;
    }
    is_deeply (\@got, \@want, 'samp.locatedb');
  }
  $it->reset;
  {
    my @got;
    while (defined (my $filename = $it->next)) {
      push @got, $filename;
    }
    is_deeply (\@got, \@want, 'samp.locatedb after reset()');
  }
}

{
  my $it = MooseX::Iterator::Locate->new (database_file => $samp_locatedb);
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

{
  my $str = "\0LOCATE02\0\0/hello\0\006/world\0";
  my $it = MooseX::Iterator::Locate->new (database_str => $str);
  ok ($it->has_next);
  is ($it->peek, '/hello');
  is ($it->next, '/hello');
  ok ($it->has_next);
  is ($it->peek, '/hello/world');
  is ($it->next, '/hello/world');
  ok (! $it->has_next);
  $it->reset;
  ok ($it->has_next);
  is ($it->peek, '/hello');
}

{
  my $str = "\0LOCATE02\0\0/hello\0\006/world\0";
  my $str_ref = \$str;
  my $it = MooseX::Iterator::Locate->new (database_str_ref => $str_ref);
  substr($str,-2,1) = 'X';
  is ($it->next, '/hello');
  is ($it->next, '/hello/worlX');
  ok (! $it->has_next);
}

#-----------------------------------------------------------------------------
# inheritance

{
  my $it = MooseX::Iterator::Locate->new (database_file => $samp_locatedb);
  ok (! $it->does('nosuchrolename'), 'does() not nosuchrolename');
  ok ($it->does('MooseX::Iterator::Role'), 'does() MooseX::Iterator::Role');
}

#-----------------------------------------------------------------------------
# attributes

{
  my $meta = MooseX::Iterator::Locate->meta;
  my @want_names = (qw(database_file
                       database_fh
                       database_str
                       database_str_ref
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
    ok ($meta->has_attribute($name), "$name - has_attribute");
    my $attr = $meta->get_attribute($name);
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
  my $instance = MooseX::Iterator::Locate->new
    (database_file => $samp_locatedb);
  my $meta = $instance->meta;

  my $attr = $meta->get_attribute('database_file');
  ok ($attr, 'database_file attribute exists');
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
  my $meta = MooseX::Iterator::Locate->meta;
  my $attr = $meta->get_attribute('use_mmap');
  ok ($attr && $attr->has_type_constraint,
      'use_mmap - has_type_constraint');

  ok ($attr && $attr->verify_against_type_constraint('if_possible'),
      'use_mmap - verify_against_type_constraint(if_possible) pass');
  {
    my $pass = 0;
    eval {
      $attr->verify_against_type_constraint('no_such_choice');
      $pass = 1;
    };
    my $err = $@;
    ok (! $pass,
        'use_mmap - verify_against_type_constraint(no_such_choice) no pass');
    isnt ($err, undef,
          'use_mmap - verify_against_type_constraint(no_such_choice) error');
  }

  my $tcon = $attr && $attr->type_constraint;
  # "Parameterized" not "Enum" because it's a Maybe[], or some such
  # isa_ok ($tcon, 'Moose::Meta::TypeConstraint::Enum');

  ok ($tcon && $tcon->check('if_possible'),
      'use_mmap - tcon if_possible');
  ok ($tcon && ! $tcon->check('no_such_choice'),
      'use_mmap - tcon no_such_choice');
}


#-----------------------------------------------------------------------------
# methods

{
  my $meta = MooseX::Iterator::Locate->meta;
  my @want_names = (qw(next
                       has_next
                       peek
                       reset
                     ));
  foreach my $name (@want_names) {
    ok ($meta->has_method($name), "$name - has_method");
    my $method = $meta->get_method($name);
    ok ($method, "$name - get_method");
  }
  {
    my $name = 'new';
    ok ($meta->find_method_by_name($name), "$name - find_method_by_name");
  }

  my @want = slurp_zeros ($samp_zeros);
  my $new  = $meta->find_method_by_name('new');
  my $next = $meta->find_method_by_name('next');
  my $it = $new && $new->execute ('MooseX::Iterator::Locate',
                                  database_file => $samp_locatedb);
  isa_ok ($it, 'MooseX::Iterator::Locate',
          'new() via execute()');
  my $got = $it && $next && $next->execute($it);
  is ($got, $want[0], 'next() via execute()');
}

#------------------------------------------------------------------------------
# glob

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = MooseX::Iterator::Locate->new (database_str => $str,
                                          glob => '*.pl');
  ### $it
  is ($it->next, '/hello/world.pl');
  ok (! $it->has_next);
}

#------------------------------------------------------------------------------
# globs

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = MooseX::Iterator::Locate->new (database_str => $str,
                                          globs => ['*.pl']);
  is ($it->next, '/hello/world.pl');
  ok (! $it->has_next);
}

#------------------------------------------------------------------------------
# suffix

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = MooseX::Iterator::Locate->new (database_str => $str,
                                          suffix => '.pl');
  is ($it->next, '/hello/world.pl');
  ok (! $it->has_next);
}

#------------------------------------------------------------------------------
# suffixes

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = MooseX::Iterator::Locate->new (database_str => $str,
                                          suffixes => ['.pm','.pl']);
  is ($it->next, '/hello/world.pl');
  ok (! $it->has_next);
}

#------------------------------------------------------------------------------
# regexp

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = MooseX::Iterator::Locate->new (database_str => $str,
                                          regexp => qr/\.pl/);
  ### $it
  is ($it->next, '/hello/world.pl');
  ok (! $it->has_next);
}

#------------------------------------------------------------------------------
# regexps

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = MooseX::Iterator::Locate->new (database_str => $str,
                                          regexps => [ qr/\.pm/, qr/\.pl/ ]);
  ### $it
  is ($it->next, '/hello/world.pl');
  ok (! $it->has_next);
}

exit 0;
