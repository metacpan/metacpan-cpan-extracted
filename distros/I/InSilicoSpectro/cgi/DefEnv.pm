use strict;
use Carp;
package DefEnv;
require Exporter;

=head1 NAME

DefEnv

=head1 DESCRIPTION

Reads a local file def.env and set the local variables if any are defined

=FUNCTIONS

=head3 read([$file])

Reads the variable in file $file (default value is "env.def") in the format:

VAR1=blabla
VAR2=moreblabla+
PERLLIB=ici:ailleurs

If the name of a variable matches PERL5?LIB, then all the values (separated by :) are pushed into @INC.

If the value ends with + (VAR2 above) then the value is appended (separated) to the current value of the variable; VAR2 would become VAR2:moreblabla.

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

=cut

our (@ISA,@EXPORT,@EXPORT_OK, $VERSION);
@ISA = qw(Exporter);

@EXPORT = qw(&read);
@EXPORT_OK = ();
$VERSION = "0.9";

our %already;

sub read{
  my ($file)=@_;
  $file='env.def' unless $file;
  return unless -e $file;
  return if ($already{$file});
  $already{$file} = 1;
  open (fd, "<$file") or CORE::die "DefEnv::read(): cannot open [$file]: $!";
  while(<fd>){
    chomp;
    next unless $_;
    my ($n, $v)=split /=/, $_, 2;
    $n=~s/\s//g;
    $v=~s/^\s+//g;
    $v=~s/\s+$//g;
    if($n=~s/\+$//){
      if($ENV{$n}){
	$ENV{$n}.=":$v";
      }else{
	$ENV{$n}=$v;
      }
    }else{
      $ENV{$n}=$v;
    }
    if($n =~ /^PERL5?LIB$/){
      foreach (split /:/, $v) {
        push @INC, $_;
      }
    }
  }
}
 
1;
