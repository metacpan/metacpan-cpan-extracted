package Kolab::LDAP::Backend::dirservd;

##
##  Copyright (c) 2003  Code Fusion cc
##
##    Writen by Stuart Bingë  <s.binge@codefusion.co.za>
##
##  This  program is free  software; you can redistribute  it and/or
##  modify it  under the terms of the GNU  General Public License as
##  published by the  Free Software Foundation; either version 2, or
##  (at your option) any later version.
##
##  This program is  distributed in the hope that it will be useful,
##  but WITHOUT  ANY WARRANTY; without even the  implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
##  General Public License for more details.
##
##  You can view the  GNU General Public License, online, at the GNU
##  Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.
##

use 5.008;
use strict;
use warnings;
use Kolab;
use Kolab::Util;
use Kolab::LDAP;
use Net::LDAP;
use Net::LDAP::Control;
use vars qw($ldap $cyrus);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [ qw(
    &startup
    &run
    ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = sprintf('%d.%02d', q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);

sub startup { 1; }

sub shutdown
{
    Kolab::log('DSd', 'Shutting down');
    exit(0);
}

sub abort
{
    Kolab::log('DSd', 'Aborting');
    exit(1);
}

sub run
{
    # This should be called from a separate thread, as we set our
    # own interrupt handlers here

    $SIG{'INT'} = \&shutdown;
    $SIG{'TERM'} = \&shutdown;

    END {
    alarm 0;
    }

    my $mesg;

    Kolab::log('DSd', 'Listener starting up, refresh is: '.$Kolab::config{'dirserv_poll_period'}." seconds");

    #while ($Kolab::config{'dirserv_mailbox_server'} ne '') {
    while (1) {

      if ($Kolab::config{'dirserv_mailbox_user'} ne "") {
	Kolab::log('DSd', 'Polling for DirServ updates', KOLAB_DEBUG);
	Kolab::DirServ::handleNotifications(
        	$Kolab::config{'dirserv_mailbox_server'},
		$Kolab::config{'dirserv_mailbox_user'},
		$Kolab::config{'dirserv_mailbox_password'},
      	);
      }

      sleep($Kolab::config{'dirserv_poll_period'});


    };



    1;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Kolab::LDAP::Backend::dirservd - Perl extension for the Directory
Services updater.

=head1 ABSTRACT

  Kolab::LDAP::Backend::dirservd handles an DirServ updater
  backend to the kolab daemon.

=head1 AUTHOR

Stuart Bingë, E<lt>s.buys@codefusion.co.zaE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003  Code Fusion cc

This  program is free  software; you can redistribute  it and/or
modify it  under the terms of the GNU  General Public License as
published by the  Free Software Foundation; either version 2, or
(at your option) any later version.

This program is  distributed in the hope that it will be useful,
but WITHOUT  ANY WARRANTY; without even the  implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You can view the  GNU General Public License, online, at the GNU
Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.

=cut
