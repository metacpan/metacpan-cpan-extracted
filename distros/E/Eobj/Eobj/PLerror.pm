#
# This file is part of the Eobj project.
#
# Copyright (C) 2003, Eli Billauer
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# A copy of the license can be found in a file named "licence.txt", at the
# root directory of this project.
#

package Eobj::PLerror;
use strict 'vars';
require Exporter;

@Eobj::PLerror::ISA = ('Exporter');
@Eobj::PLerror::EXPORT = qw(blow puke wiz wizreport fishy wrong say hint wink);
%Eobj::PLerror::evalhash = ();
%Eobj::PLerror::packhash = ();

sub blow {
  { local $@; require Eobj::PLerrsys; }  # XXX fix require to not clear $@?
  my $err = &Eobj::linebreak("@_");
  die $err if $err =~ /\n$/; 
  chomp $err;
  die "$err ".oneplace()."\n";
}

sub puke {
  { local $@; require Eobj::PLerrsys; }  # XXX fix require to not clear $@?
  my ($chain, $err)=&stackdump(@_);
  die(&Eobj::linebreak($chain."\nError: $err")."\n");
}

sub wiz {
  print &Eobj::linebreak("@_");
}

sub wizreport {
  { local $@; require Eobj::PLerrsys; }  # XXX fix require to not clear $@?
  my ($chain, $err)=&stackdump(@_);
  die(&Eobj::linebreak($chain."\nWiz report: $err")."\n");
}

sub fishy {
  my $warn = &Eobj::linebreak("@_");
  chomp $warn;
  warn "$warn\n";
}

sub wrong { 
  die(&Eobj::linebreak("@_")."\n");
  $Eobj::wrongflag=1;
}

sub say {
  print "@_";
}

sub hint {
#  print "@_";
}

sub wink {
  print "@_";
}

sub register {
  my $fname = shift;
  my ($pack,$file,$line) = caller;
  $Eobj::PLerror::evalhash{$file}=[$pack,$fname,$line];
  $Eobj::PLerror::packhash{$pack}=$fname;
}

1;
