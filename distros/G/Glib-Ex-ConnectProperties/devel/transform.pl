#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;

{
  # only for existence of the other end of the mapping, not for values as such
  require Tie::Hash::TwoWay;
  tie (my %h, 'Tie::Hash::TwoWay');
  $h{'k'} = ['a','b'];
  print "keys ", keys %h, "\n";
  print $h{'a'}->{'k'},"\n";
  print $h{'b'},"\n";
  print $h{'k'},"\n";
}

# Is an array transform any good?  Most things are string enums or bools
# rather than numbers as such.
#
#     if (my $aref = delete $elem->{'array_in'}) {
#       ### array_in func: "@{[keys %$aref]}"
#       $elem->{'func_in'} = _make_array_func ($aref);
#     }
#     if (my $aref = delete $elem->{'array_out'}) {
#       ### array_out func: "@{[keys %$aref]}"
#       $elem->{'func_out'} = _make_array_func ($aref);
#     }
# sub _make_array_func {
#   my ($aref) = @_;
#   return sub {
#     (exists $aref->{$_[0]} ? $aref->{$_[0]} : $_[0]);
#   };
# }


__END__
use Glib;
my $pspec;
#my $flags = $option{'flags'};
my $flags = ['readable'];
$flags = (defined $flags ? Glib::ParamFlags->new($flags) : $pspec->get_flags);





    if (my $h = delete $elem->{'hash_inout'}) {
      ### hash_inout: "@{[keys %$h]}"
      $elem->{'hash_in'} = $h;
      $elem->{'hash_out'} = { reverse %$h };
    }
# =item C<< hash_inout => $hashref >>
# 
# A convenient combination of C<hash_in> and C<hash_out>.  C<$hashref> is used
# for values going in, and a reverse lookup is performed for values coming
# out, as if C<hash_out> was C<< { reverse %$hashref } >>.


if (my $h = delete $options->{'hash_out'}) {
  $options->{'func_out'} = sub {
    return (exists $h->{$_[0]} ? $h->{$_[0]} : $_[0])
  }

if (my $h = $from_options->{'hash_out'}) {
  if (exists $h->{$from_val}) {
    $from_val = $h->{$from_val};
  }
} elsif (my $f = $from_options->{'func_out'}) {
  $from_val = $f->($from_val);
} elsif (my $f = $from_options->{'func_out'}) {

  if (my $h = $to_options->{'hash_in'}) {
    if (exists $h->{$to_val}) {
      $to_val = $h->{$to_val};
    }
  } elsif (my $f = $to_options->{'func_in'}) {
    $to_val = $f->($to_val);
  }



  __END__

    flags => ['readable']

      negate => 1
        hash_inout => { 1 => 2,
                        2 => 3 }
          reverse for out, when required
            Tie::RefHash

                hash_in => { 1 => 2,
                             2 => 3 }
                  hash_out => { 2 => 1,
                                3 => 2 }
                    array_inout => { 2 => 1,
                                     3 => 2 }

                      subr_in =>    &$subr ($value)
                        subr_out =>   &$subr ($value)
