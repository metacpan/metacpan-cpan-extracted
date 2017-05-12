# --8<--8<--8<--8<--
#
# Copyright (C) 2000-2009 Smithsonian Astrophysical Observatory
#
# This file is part of IPC-XPA
#
# IPC-XPA is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More qw( no_plan );

use strict;
use vars qw( $use_PDL $max_tests $test $loaded @res %res $verbose);

BEGIN { use_ok( 'IPC::XPA' );
	$verbose = 0;

	eval 'require PDL; PDL::import();';
	$use_PDL = ! $@;
      }

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Data::Dumper;
use constant XPASERVER => 'ds9';

my $connect;

# check connectivity
my %res = IPC::XPA->Access( XPASERVER, "gs", { max_servers => 1000 } );

# set connect to -1 on failure so all of the remaining tests fail
unless ( keys %res && _chk_message( 0, %res ) )
{
  print "Unable to connect to server `", XPASERVER, "'; most tests will fail.\n";
  $connect = -1;
}
else
{
  $connect = keys %res;
}

ok( $connect > -1, 'Access' );

my %attr = ( max_servers => ($connect > 0 ? $connect : 0 ) );

# try a lookup
@res = IPC::XPA->NSLookup( 'ds9', 'ls' );
ok( @res == $connect, 'NSLookup' );


# create a new XPA handle
my $xpa = IPC::XPA->Open( { verify => 'true' } );
ok( defined $xpa, 'Open' );

# grab ds9 version
%res = $xpa->Get( 'ds9', 'version', \%attr );
ok( _chk_message( $connect, %res ), 'Get version' );

# make sure version(s) of ds9 are current enough.
while( my ( $server, $res ) = each %res )
{
  my $version;
  unless ( ($version) = $res->{buf} =~ /\b([1-9.]+)\b/ )
  {
    warn( "unable to parse version string for server `$server': $res->{buf}\n" );
    next;
  }
  warn( "DS9 version $version has not been tested with this module.\n",
	  "Some of the tests may fail.\n" )
    if $version lt '1.9.4';
}


%res = $xpa->Get( 'ds9', '-help quit', \%attr );
ok( _chk_message( $connect, %res ), 'Get 1');

my %res = $xpa->Get( 'ds9', '-help quit',
		     { mode => { ack => 'true' }, %attr });
ok( _chk_message( $connect, %res ), 'Get 2' );

%res = $xpa->Set( 'ds9', 'mode crosshair', \%attr );
ok( _chk_message( $connect, %res ), 'Set 1' );

%res = $xpa->Set( 'ds9', 'mode crosshair',
		     { mode => { ack => 'true' }, %attr });
ok( _chk_message( $connect, %res ), 'Set 2' );

%res = IPC::XPA->Set( 'ds9', 'mode pointer',
		     { mode => { ack => 'true' }, %attr });
ok( _chk_message( $connect, %res ), 'Set 3' );

if ( $use_PDL )
{
  my $k = zeroes(double(), 100,100)->rvals;
  
  %res = $xpa->Set( 'ds9', 'array [dim=100,bitpix=-64]', 
		    ${$k->get_dataref}, \%attr);

  ok( _chk_message( $connect, %res ), 'array' );

  $k = $k->max - $k;
  %res = $xpa->Set( 'ds9', 'array [dim=100,bitpix=-64]', 
		    $k->get_dataref, \%attr);

  ok( _chk_message( $connect, %res ), 'array scalar ref' );
}

sub _chk_message
{
  my ( $connect, %res ) = @_;
  my $ok = 1;
  if ( $connect != 0 && keys %res != $connect )
  {
    $ok = 0;
  }
  else
  {
    $ok = 0 if grep { defined $_->{message} } values %res;
  }

  print Dumper \%res if $verbose;

  $ok;
}
