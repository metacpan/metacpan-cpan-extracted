## @file
# Main handler.

## @class
# Main handler.
# All methods in handler are class methods: in ModPerl environment, handlers
# are always launched without object created.
#
# The main method is run() who is called by Apache for each requests (using
# handler() wrapper).
#
# The initialization process is splitted in two parts :
# - init() is launched as Apache startup
# - globalInit() is launched at each first request received by an Apache child
# and each time a new configuration is detected
package Lemonldap::NG::Handler::SharedConf;

#use strict;

use Lemonldap::NG::Handler::Main qw(:all);
use Lemonldap::NG::Handler::Main::Logger;
use Lemonldap::NG::Handler::API qw(:httpCodes);
use Lemonldap::NG::Handler::Reload;
use Lemonldap::NG::Common::Conf;               #link protected lmConf
use Lemonldap::NG::Common::Conf::Constants;    #inherits

use base qw(Lemonldap::NG::Handler::Main);

our $VERSION = '1.9.1';
our $lmConf;         # Lemonldap::NG::Common::Conf object to get config
our $localConfig;    # Local configuration parameters, i.e. defined
                     # in lemonldap-ng.ini or in startup parameters
our $cfgNum    = 0;      # Number of the loaded remote configuration
our $lastCheck = 0;      # Date of last configuration check (unix time)
our $checkTime = 600;    # Time between 2 configuration check (in seconds);
                         # default value is 600, can be reset in local config

BEGIN {
    Lemonldap::NG::Handler::API->thread_share($cfgNum);
    Lemonldap::NG::Handler::API->thread_share($lastCheck);
    Lemonldap::NG::Handler::API->thread_share($checkTime);
    Lemonldap::NG::Handler::API->thread_share($lmConf);
    Lemonldap::NG::Handler::API->thread_share($localConfig);
    *EXPORT_TAGS = *Lemonldap::NG::Handler::Main::EXPORT_TAGS;
    *EXPORT_OK   = *Lemonldap::NG::Handler::Main::EXPORT_OK;
    push(
        @{ $EXPORT_TAGS{$_} },
        qw($cfgNum $lastCheck $checkTime $lmConf $localConfig)
    ) foreach (qw(variables localStorage));
    push @EXPORT_OK, qw($cfgNum $lastCheck $checkTime $lmConf $localConfig);
}

# INIT PROCESS

## @imethod void init(hashRef args)
# Read parameters and build the Lemonldap::NG::Common::Conf object.
# @param $args hash containing parameters
sub init($$) {
    my ( $class, $args ) = @_;

    # According to doc, localStorage can be declared in $args root,
    # but it must be in $args->{configStorage}
    foreach (qw(localStorage localStorageOptions)) {
        $args->{configStorage}->{$_} ||= $args->{$_};
    }

    $lmConf = Lemonldap::NG::Common::Conf->new( $args->{configStorage} );
    die(    "$class : unable to build configuration: "
          . "$Lemonldap::NG::Common::Conf::msg" )
      unless ($lmConf);

    # Merge local configuration parameters so that params defined in
    # startup parameters have precedence over lemonldap-ng.ini params
    $localConfig = { %{ $lmConf->getLocalConf(HANDLERSECTION) }, %{$args} };

    $checkTime = $localConfig->{checkTime} || $checkTime;

    # Few actions that must be done at server startup:
    # * set log level for Lemonldap::NG logs
    Lemonldap::NG::Handler::Main::Logger->logLevelInit(
        $localConfig->{logLevel} );

    # * set server signature
    $class->serverSignatureInit unless ( $localConfig->{hideSignature} );

    # * launch status process
    $class->statusInit($tsv) if ( $localConfig->{status} );
    1;
}

# @method void serverSignatureInit
# adapt server signature
sub serverSignatureInit {
    my $class = shift;
    Lemonldap::NG::Handler::API->setServerSignature(
        "Lemonldap::NG/" . $Lemonldap::NG::Handler::VERSION )
      if ($Lemonldap::NG::Handler::VERSION);
}

## @ifn protected void statusInit()
# Launch the status process
sub statusInit {
    my ( $class, $tsv ) = @_;
    return if ( $tsv->{statusPipe} and $tsv->{statusOut} );
    require IO::Pipe;
    $statusPipe = IO::Pipe->new;
    $statusOut  = IO::Pipe->new;
    if ( my $pid = fork() ) {

        # TODO: log new process pid
        $statusPipe->writer();
        $statusOut->reader();
        $statusPipe->autoflush(1);
        ( $tsv->{statusPipe}, $tsv->{statusOut} ) = ( $statusPipe, $statusOut );
    }
    else {
        $statusPipe->reader();
        $statusOut->writer();
        my $fdin  = $statusPipe->fileno;
        my $fdout = $statusOut->fileno;
        open STDIN,  "<&$fdin";
        open STDOUT, ">&$fdout";
        my $perl_exec = ( $^X =~ /perl/ ) ? $^X : 'perl';
        exec $perl_exec, '-MLemonldap::NG::Handler::Status',
          map( {"-I$_"} @INC ),
          '-e &Lemonldap::NG::Handler::Status::run()';
    }
}

# MAIN

## @rmethod int run
# Check configuration and launch Lemonldap::NG::Handler::Main::run().
# Each $checkTime, the Apache child verify if its configuration is the same
# as the configuration stored in the local storage.
# @param $rule optional Perl expression to grant access
# @return Apache constant
sub run {
    my $class = shift;
    if ( time() - $lastCheck > $checkTime ) {
        die("$class: No configuration found")
          unless ( $class->checkConf );
    }
    if ( my $rule = shift ) {
        my ( $cond, $prot ) =
          Lemonldap::NG::Handler::Reload->conditionSub( $rule, $tsv );
        return $class->SUPER::run( $cond, $prot );
    }
    return $class->SUPER::run();
}

# CONFIGURATION UPDATE

## @rmethod protected int checkConf(boolean force)
# Check if configuration is up to date, and reload it if needed.
# If the optional boolean $force is set to true,
# * cached configuration is ignored
# * and checkConf returns false if it fails to load remote config
# @param $force boolean
# @return true if config is up to date or if reload config succeeded
sub checkConf {
    my ( $class, $force ) = @_;
    my $conf = $lmConf->getConf( { local => !$force } );

    unless ( ref($conf) ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
"$class: Unable to load configuration: $Lemonldap::NG::Common::Conf::msg",
            'error'
        );
        return $force ? 0 : $cfgNum ? 1 : 0;
    }

    if ( !$cfgNum or $cfgNum != $conf->{cfgNum} ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
"Get configuration $conf->{cfgNum} ($Lemonldap::NG::Common::Conf::msg)",
            'debug'
        );
        $lastCheck = time();
        unless ( $cfgNum = $conf->{cfgNum} ) {
            Lemonldap::NG::Handler::Main::Logger->lmLog(
                'No configuration available', 'error' );
            return 0;
        }
        $conf->{$_} = $localConfig->{$_} foreach ( keys %$localConfig );
        Lemonldap::NG::Handler::Reload->configReload( $conf, $tsv );
    }
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "$class: configuration is up to date", 'debug' );
    return $conf;
}

# RELOAD SYSTEM

*refresh = *reload;

## @rmethod int reload
# Launch checkConf() with $local=0, so remote configuration is tested.
# Then build a simple HTTP response that just returns "200 OK" or
# "500 Server Error".
# @return Apache constant (OK or SERVER_ERROR)
sub reload {
    my $class = shift;
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "Request for configuration reload", 'notice' );
    return $class->checkConf(1) ? DONE : SERVER_ERROR;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Handler::SharedConf - Perl extension to use dynamic
configuration provide by Lemonldap::NG::Manager.

=head1 SYNOPSIS

  package My::Package;
  use Lemonldap::NG::Handler::SharedConf;
  @ISA = qw(Lemonldap::NG::Handler::SharedConf);
  __PACKAGE__->init ( {
    localStorage        => "Cache::FileCache",
    localStorageOptions => {
        'namespace' => 'lemonldap-ng',
        'default_expires_in' => 600,
      },
    configStorage       => {
       type                => "DBI"
       dbiChain            => "DBI:mysql:database=$database;host=$hostname;port=$port",
       dbiUser             => "lemonldap",
       dbiPassword         => "password",
      },
  } );

Call your package in /apache-dir/conf/httpd.conf :

  PerlRequire MyFile
  # TOTAL PROTECTION
  PerlHeaderParserHandler My::Package
  # OR SELECTED AREA
  <Location /protected-area>
    PerlHeaderParserHandler My::Package
  </Location>

The configuration is loaded only at Apache start. Create an URI to force
configuration reload, so you don't need to restart Apache at each change :

  # /apache-dir/conf/httpd.conf
  <Location /location/that/I/ve/choosed>
    Order deny,allow
    Deny from all
    Allow from my.manager.com
    PerlHeaderParserHandler My::Package->refresh
  </Location>

=head1 DESCRIPTION

This library inherit from L<Lemonldap::NG::Handler::Main> to build a
complete SSO Handler System: a central database contains the policy of your
domain. People that want to access to a protected applications are redirected
to the portal that run L<Lemonldap::NG::Portal::SharedConf>. After reading
configuration from the database and authenticating the user, it stores a key
word for each application the user is granted to access to.
Then the user is redirected to the application he wanted to access and the
Apache handler build with L<Lemonldap::NG::Handler::SharedConf::DBI> has just
to verify that the keyword corresponding to the protected area is stored in
the database.

=head2 OVERLOADED SUBROUTINES

=head3 init

Like L<Lemonldap::NG::Handler::Main>::init() but read only localStorage
related options. You may change default time between two configuration checks
with the C<checkTime> parameter (default 600s).

=head1 OPERATION

Each new Apache child checks if there's a configuration stored in the local
store. If not, it calls getConf to get one and store it in the local store by
calling setconf.

Every 600 seconds, each Apache child checks if the local stored configuration
has changed and reload it if it has.

When refresh subroutine is called (by http for example: see synopsis), getConf
is called to get the new configuration and setconf is called to store it in the
local store.

=head1 SEE ALSO

L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Manager>, L<Lemonldap::NG::Portal>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2005-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Copyright (C) 2006-2016 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
