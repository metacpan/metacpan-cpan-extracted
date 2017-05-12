#!/usr/bin/perl
package Mail::SpamCannibal::LaBreaDaemon;

use strict;
use LaBrea::Tarpit 1.20 qw(daemon);
use vars qw(@ISA @EXPORT $FIFO $VERSION);
require Exporter;

@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.03 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT = qw(daemon);

=head1 NAME

Mail::SpamCannibal::LaBreaDaemon - interface to LaBrea::Tarpit

=head1 SYNOPSIS

  use Mail::SpamCannibal::LaBreaDaemon;

  daemon(&hash | \%hash)

=head1 DESCRIPTION

This module has one function, to interface to the LaBrea::Tarpit::daemon
routine to start and run its data collection daemon.

=over 2

=item * daemon(&hash | \%hash)

 input parameters: from hash or pointer to hash
 {
  'LaBrea'      => '/usr/local/spamcannibal/bin/dbtarpit',
  'd_port'      => 8687,                # REQUIRED
  'd_host'      => 'localhost',         # defaults to ALL interfaces
                                        # NOT recommended
  'allowed'     => 'localhost,remote.com',      # default is ALL
                                        # recommend only 'localhost'
  'pid'         => '/var/run/dbtarpit/sc_lbdaemon.pid',
  'cache'       => '/var/run/dbtarpit/sc_lbdaemon.cache',
  'fifo'        => '/var/run/dbtarpit/dbtplog',
 # 'kids'       => default 5            # kids to deliver net msgs
                                        # why would you need more??
 # 'umask'      => 033,         # default 033, cache_file umask
 # 'cull'       => 600,         # default 600, seconds to keep old threads
  'scanners'    => 100,                 # keep this many dead threads
 # 'port_timer' => 86400,       # default 86400, seconds per collection period
  'port_intvls' => 30,                  # keep #nintvls of port stats
                                        # 0 or missing disables
                                        # this can take lots of memory
 };  

=back

=cut

sub lbd_open {
  my($LaBrea,$DEBUG) = @_;
  local *LABREA;
  $LaBrea =~ /^([^\s]+)/;		# bare path to LaBrea
  qx/$1 -V 2>&1/ =~ /(\d+\.[^\s]+)/;	# get version
  my $version = $1;			# save version
# open LaBrea daemon
  my $kid = open(LABREA,$FIFO);
	die "Can't open $FIFO: $!" unless $kid;
  unless ($DEBUG) {
    open STDERR, '>&STDOUT'		or die "Can't dup stdout: $!";
  }
  $0 =~ /[^\s]+$/;
  $0 = $&;
  return(*LABREA,$version,$kid);
}

sub lbd_close {
  my($LBfh,$kid) = @_;
  close $LBfh;
}

*LaBrea::Tarpit::lbd_open = \&lbd_open;
*LaBrea::Tarpit::lbd_close = \&lbd_close;

sub daemon {
  local $_ = ( ref $_[0] ) ? $_[0] : {@_};
  $FIFO = $_->{fifo} || die 'no fifo found';
  goto &LaBrea::Tarpit::daemon;
}

=head1 DEPENDENCIES

	LaBrea::Tarpit verion 1.17 or better

=head1 COPYRIGHT

Copyright 2003, Michael Robinton <michael@bizsystems.com>

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

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 SEE ALSO

L<LaBrea::Tarpit>, L<LaBrea::Tarpit::Report>

=cut


1;
