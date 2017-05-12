#!/usr/bin/perl

package File::SafeDO;
use strict;
#use diagnostics;

use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.14 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
        DO
	doINCLUDE
);

use Config;

=head1 NAME

File::SafeDO -- safer do file for perl

=head1 SYNOPSIS

  use File::SafeDO qw(
        DO
	doINCLUDE
  );

  $rv = DO($file,[optional no warnings string])

=head1 DESCRIPTION

=over 4

=item * $rv = DO($file,[optional] "no warnings string");

This is a fancy 'do file'. It first checks that the file exists and is
readable, then does a 'do file' to pull the variables and subroutines into
the current name space. The 'do' is executed with full perl warnings so that 
syntax and construct errors are reported to STDERR. A string of B<no
warnings> may optionally be specified as a second argument. This is
equivalent to saying:

  no warnings qw(string of no values);

See: man perllexwarnings for a full listing of warning names.

  input:	file/path/name,
	    [optional] string of "no" warnings
  returns:	last value in file
	    or	undef on error
	    prints warning

  i.e. DO('myfile','once redefine');

This will execute 'myfile' safely and suppress 'once' and 'redefine'
warnings to STDERR.

=cut

sub xDO($;$) {
  my($file,$nowarnings) = @_;
  return undef unless
	$file &&
	-e $file &&
	-f $file &&
	-r $file;
  $_ = $Config{perlpath};		# bring perl into scope
  if ($nowarnings) {
    return undef if eval q|system($_, '-Mwarnings', "-M-warnings qw($nowarnings)", $file)|;
  } else {
    return undef if eval q|system($_, '-w', $file)|;
  }
# poke anonymous subroutine into calling package so vars and subs will import
  my $caller = caller;
# execute 'do $file;' in calling package
   &{eval "package $caller; sub { my \$file = shift; do \$file;};";}($file);
}

sub DO($;$) {
  my($file,$nowarnings) = @_;
  my $caller = caller;
  @_ = ($file,$nowarnings,$caller,0);
  goto &_doFILE;
}

=item * $rv = doINCLUDE($file,[optional] "no warnings string");

The function is similar to B<DO> above with the addition of recursive loads.

Function will recursively load a file which returns a hash pointer with the
a key of the form:
 
	'INCLUDE' => somefile. 

The file which it loads may contain only HASHs or SUBs. The HASH KEYS will
be promoted into the parent hash, augmenting and replacing existing keys
already present. Subroutines are simply imported into the name
space as is the case with a 'do' or 'require'.

=back

=cut

sub doINCLUDE($;$) {
  my($file,$nowarnings) = @_;
  my $caller = caller;
  @_ = ($file,$nowarnings,$caller,1);
  goto &_doFILE;
}

sub _doFILE($$$$) {
  my($file,$nowarnings,$caller,$recurs) = @_;
  return undef unless
	$file &&
	-e $file &&
	-f $file &&
	-r $file;
  $_ = $Config{perlpath};		# bring perl into scope
  if ($nowarnings) {
    return undef if eval q|system($_, '-Mwarnings', "-M-warnings qw($nowarnings)", $file)|;
  } else {
    return undef if eval q|system($_, '-w', $file)|;
  }
# poke anonymous subroutine into calling package so vars and subs will import
# execute 'do $file;' in calling package
  my $rv = &{eval "package $caller; sub { my \$file = shift; do \$file;};";}($file);
  return $rv unless $recurs && 
	UNIVERSAL::isa($rv,'HASH') &&
	exists $rv->{INCLUDE};
  my $rrv = &_doFILE($rv->{INCLUDE},$nowarnings,$caller,1);
  return $rv unless $rrv &&
	UNIVERSAL::isa($rv,'HASH');
  my @keys = keys %{$rrv};
  @{$rv}{@keys} = @{$rrv}{@keys};
  return $rv;
}

=head1 DEPENDENCIES

	none

=head1 EXPORT_OK

	DO
	doINCLUDE

=head1 AUTHOR

Michael Robinton, michael@bizsystems.com

=head1 COPYRIGHT

Copyright 2003 - 2014, Michael Robinton & BizSystems
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1;
