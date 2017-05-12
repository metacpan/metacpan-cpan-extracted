package Dist::Zilla::Plugin::Dpkg::PerlbrewStarman;
{
  $Dist::Zilla::Plugin::Dpkg::PerlbrewStarman::VERSION = '0.16';
}
use Moose;

use Moose::Util::TypeConstraints;

extends 'Dist::Zilla::Plugin::Dpkg';

enum 'WebServer', [qw(apache nginx all)];
subtype 'ApacheModule', as 'Str', where { $_ =~ /^[a-z_]+$/ };
subtype 'ApacheModules', as 'ArrayRef[ApacheModule]', message { 'The value provided for apache_modules does not look like a list of whitespace-separated Apache modules' };
coerce 'ApacheModules', from 'Str', via { [ split /\s+/ ] };

#ABSTRACT: Generate dpkg files for your perlbrew-backed, starman-based perl app


has '+conffiles_template_default' => (
    default => '/etc/default/{$package_name}
/etc/init.d/{$package_name}
'
);

has '+control_template_default' => (
    default => 'Source: {$package_name}
Section: {$package_section}
Priority: {$package_priority}
Maintainer: {$author}
Build-Depends: {$package_depends}
Standards-Version: 3.8.4

Package: {$package_name}
Architecture: {$architecture}
Depends: adduser {$package_binary_depends}
Description: {$package_description}
'
);

has '+default_template_default' => (
    default => '# Defaults for {$package_name} initscript
# sourced by /etc/init.d/{$package_name}
# installed at /etc/default/{$package_name} by the maintainer scripts

#
# This is a POSIX shell fragment
#

APP="{$package_name}"
APPDIR="/srv/$APP"
APPLIB="/srv/$APP/lib"
APPUSER={$package_name}

PSGIAPP="{$psgi_script}"
PIDFILE="/var/run/$APP.pid"

PERLBREW_PATH="$APPDIR/perlbrew/bin"

DAEMON_ARGS="-Ilib $PSGIAPP --daemonize --user $APPUSER --preload-app --workers {$starman_workers} --pid $PIDFILE --port {$starman_port} --host 127.0.0.1 --error-log /var/log/$APP/error.log"
'
);

has '+init_template_default' => (
    default => '#!/bin/sh
### BEGIN INIT INFO
# Provides:          {$package_name}
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: {$name}
# Description:       {$name}
#                    <...>
#                    <...>
### END INIT INFO

# Author: {$author}

DESC={$package_name}
NAME={$package_name}
SCRIPTNAME=/etc/init.d/$NAME

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

PATH=$PERLBREW_PATH:$PATH
DAEMON=`which starman`

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

check_running() \{
    [ -s $PIDFILE ] && kill -0 $(cat $PIDFILE) >/dev/null 2>&1
\}

check_compile() \{
  if ( cd $APPLIB ; find -type f -name \'*.pm\' | xargs perl -c ) ; then
    return 1
  else
    return 0
  fi
\}

_start() \{

  export {$package_shell_name}_HOME=$APPDIR
  /sbin/start-stop-daemon --start --pidfile $PIDFILE --chdir $APPDIR --exec $DAEMON -- \
    $DAEMON_ARGS \
    || return 2

  echo ""
  echo "Waiting for $APP to start..."

  for i in `seq {$startup_time}` ; do
    sleep 1
    if check_running ; then
      echo "$APP is now starting up"
      return 0
    fi
  done

  return 1
\}

start() \{
    log_daemon_msg "Starting $APP"
    echo ""

    if check_running; then
        log_progress_msg "already running"
        log_end_msg 0
        exit 0
    fi

    rm -f $PIDFILE 2>/dev/null

    _start
    log_end_msg $?
    return $?
\}

stop() \{
    log_daemon_msg "Stopping $APP"
    echo ""

    /sbin/start-stop-daemon --stop --oknodo --pidfile $PIDFILE
    sleep 3
    log_end_msg $?
    return $?
\}

restart() \{
    log_daemon_msg "Restarting $APP"
    echo ""

    if check_compile ; then
        log_failure_msg "Error detected; not restarting."
        log_end_msg 1
        exit 1
    fi

    /sbin/start-stop-daemon --stop --oknodo --pidfile $PIDFILE
    _start
    log_end_msg $?
    return $?
\}


# See how we were called.
case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart|force-reload)
        restart
    ;;
    *)
        echo $"Usage: $0 \{start|stop|restart\}"
        exit 1
esac
exit $?
'
);

has '+install_template_default' => (
    default => 'config/* srv/{$package_name}/config
lib/* srv/{$package_name}/lib
root/* srv/{$package_name}/root
script/* srv/{$package_name}/script
perlbrew/* srv/{$package_name}/perlbrew
'
);

has '+postinst_template_default' => (
    default => '#!/bin/sh
# postinst script for {$package_name}
#
# see: dh_installdeb(1)

set -e

# summary of how this script can be called:
#        * <postinst> `configure` <most-recently-configured-version>
#        * <old-postinst> `abort-upgrade` <new version>
#        * <conflictor`s-postinst> `abort-remove` `in-favour` <package>
#          <new-version>
#        * <postinst> `abort-remove`
#        * <deconfigured`s-postinst> `abort-deconfigure` `in-favour`
#          <failed-install-package> <version> `removing`
#          <conflicting-package> <version>
# for details, see http://www.debian.org/doc/debian-policy/ or
# the debian-policy package

PACKAGE={$package_name}

case "$1" in
    configure)

        # Symlink /etc/$PACKAGE to our package`s config directory
        if [ ! -e /etc/$PACKAGE ]; then
            ln -s /srv/$PACKAGE/config /etc/$PACKAGE
        fi

        {$webserver_config_link}

        # Create user if it doesn`t exist.
        if ! id $PACKAGE > /dev/null 2>&1 ; then
            adduser --system {$uid} --home /srv/$PACKAGE --no-create-home \
                --ingroup nogroup --disabled-password --shell /bin/bash \
                $PACKAGE
        fi

        # Setup the perlbrew
        echo "export PATH=~/perlbrew/bin:$PATH" > /srv/$PACKAGE/.profile

        # Make sure this user owns the directory
        chown -R $PACKAGE:adm /srv/$PACKAGE

        # Make the log directory
        if [ ! -e /var/log/$PACKAGE ]; then
            mkdir /var/log/$PACKAGE
            chown -R $PACKAGE:adm /var/log/$PACKAGE
        fi

        {$webserver_restart}
    ;;

    abort-upgrade|abort-remove|abort-deconfigure)
    ;;

    *)
        echo "postinst called with unknown argument: $1" >&2
        exit 1
    ;;
esac

# dh_installdeb will replace this with shell code automatically
# generated by other debhelper scripts.

#DEBHELPER#

exit 0
'
);

has '+postrm_template_default' => (
    default => '#!/bin/sh

set -e

PACKAGE={$package_name}

case "$1" in
    purge)
        # Remove the config symlink
        rm -f /etc/$PACKAGE

        # Remove the nginx config
        if [ -h /etc/nginx/sites-available/$PACKAGE ]; then
            rm -f /etc/nginx/sites-available/$PACKAGE
        fi

        # Remove the apache config
        if [ -e /etc/apache2/sites-available/$PACKAGE ]; then
            rm -f /etc/apache2/sites-enabled/$PACKAGE
            rm -f /etc/apache2/sites-available/$PACKAGE
        fi

        # Remove the user
        userdel $PACKAGE || true

        # Remove logs
        rm -rf /var/log/$PACKAGE
        rm -rf /var/log/apache2/$PACKAGE

        # Remove the home directory
        rm -rf /srv/$PACKAGE
    ;;

    remove|upgrade|failed-upgrade|abort-install|abort-upgrade|disappear)
    ;;

    *)
        echo "postrm called with unknown argument: $1" >&2
        exit 1
    ;;
esac

#DEBHELPER#

exit 0
'
);

has '+rules_template_default' => (
    default => '#!/usr/bin/make -f
# -*- makefile -*-
# Sample debian/rules that uses debhelper.
# This file was originally written by Joey Hess and Craig Small.
# As a special exception, when this file is copied by dh-make into a
# dh-make output file, you may use that output file without restriction.
# This special exception was added by Craig Small in version 0.37 of dh-make.

# Uncomment this to turn on verbose mode.
export DH_VERBOSE=1

build:
	dh_testdir
	dh_auto_build

%:
	dh $@ --without perl --without auto_configure
'
);


has 'starman_port' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);


has 'starman_workers' => (
    is => 'ro',
    isa => 'Str',
    default => 5
);


has 'psgi_script' => (
    is => 'ro',
    isa => 'Str',
    default => sub {
        'script/'.$_[0]->package_name.'.psgi';
    }
);


has 'startup_time' => (
    is => 'ro',
    isa => 'Str',
    default => 30
);


has 'uid' => (
  is => 'ro',
  isa => 'Int',
  predicate => 'has_uid'
);


has 'web_server' => (
    is => 'ro',
    isa => 'WebServer',
    required => 1
);


has 'apache_modules' => (
    is => 'ro',
    isa => 'ApacheModules',
    required => 0,
    coerce => 1
);

around '_generate_file' => sub {
    my $orig = shift;
    my $self = shift;
	my $file = shift;
	my $required = shift;
	my $vars = shift;

    if($self->has_uid) {
      $vars->{uid} = '--uid '.$self->uid;
    }

    $vars->{starman_port} = $self->starman_port;
    $vars->{starman_workers} = $self->starman_workers;
    $vars->{startup_time} = $self->startup_time;

    if(($self->web_server eq 'apache') || ($self->web_server eq 'all')) {
        $vars->{package_binary_depends} .= ', apache2';
        $vars->{webserver_config_link} .= '# Symlink to the apache config for this environment
        rm -f /etc/apache2/sites-available/$PACKAGE
        ln -s /srv/$PACKAGE/config/apache/$PACKAGE.conf /etc/apache2/sites-available/$PACKAGE
';
        $vars->{webserver_restart} .= 'a2enmod proxy proxy_http rewrite ';
		$vars->{webserver_restart} .= join ' ', @{ $self->apache_modules || [] };
        $vars->{webserver_restart} .= '
        a2ensite $PACKAGE
        mkdir -p /var/log/apache2/$PACKAGE
        if which invoke-rc.d >/dev/null 2>&1; then
            invoke-rc.d apache2 restart
        else
            /etc/init.d/apache2 restart
        fi
';
    }
    if(($self->web_server eq 'nginx') || ($self->web_server eq 'all')) {
        $vars->{package_binary_depends} .= ', nginx';
        $vars->{webserver_config_link} .= '# Symlink to the nginx config for this environment
        rm -f /etc/nginx/sites-available/$PACKAGE
        ln -s /srv/$PACKAGE/config/nginx/$PACKAGE.conf /etc/nginx/sites-available/$PACKAGE
';
        $vars->{webserver_restart} .= 'if which invoke-rc.d >/dev/null 2>&1; then
            invoke-rc.d nginx restart
        else
            /etc/init.d/nginx restart
        fi
';
    }
    $self->$orig($file, $required, $vars);
};


1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::Dpkg::PerlbrewStarman - Generate dpkg files for your perlbrew-backed, starman-based perl app

=head1 VERSION

version 0.16

=head1 SYNOPSIS

A minimal directory structure for application foo:

    lib/
    root/
    script/foo.psgi
    config/nginx/foo.conf
    perlbrew/bin/starman

A minimal configuration:

    [Dpkg::PerlbrewStarman]
    web_server      = nginx
    starman_port    = 6000

A configuration showing optional attributes and their defaults:

    [Dpkg::PerlbrewStarman]
    web_server      = nginx
    starman_port    = 6000
    psgi_script     = script/foo.psgi
    starman_workers = 5
    startup_time    = 30

A configuration showing optional attributes that have no defaults:

    [Dpkg::PerlbrewStarman]
    web_server      = apache
    starman_port    = 6000
    apache_modules  = ldap ssl
    uid             = 782

=head1 DESCRIPTION

This L<Dist::Zilla> plugin generates Debian control files that are
suitable for packaging a self-contained Plack application utilizing the
Starman preforking PSGI HTTP server.  Key features include supporting an
independent perl environment and the generation and installation of init
scripts to manage the service.

Dist::Zilla::Plugin::Dpkg::PerlbrewStarman is an implementation of
L<Dist::Zilla::Plugin::Dpkg>, which itself is an abstract base class
more than anything.  It provides the basic framework by which this
Dist::Zilla plugin builds the Debian control files.  If the desired
functionality cannot be achieved by PerlbrewStarman, check there for
other control templates that may be overridden.

Dist::Zilla::Plugin::Dpkg::PerlbrewStarman provides defaults for the
following L<Dist::Zilla::Plugin::Dpkg> stubs:

=over 4

=item * conffiles_template_default

=item * control_template_default

=item * default_template_default

=item * init_template_default

=item * install_template_default

=item * postinst_template_default

=item * postrm_template_default

=back

PerlbrewStarman is intended to be used to deploy applications that meet
the following requirements:

=over 4

=item * L<perlbrew> -- others have reported using PerlbrewStarman under other systems (e.g., L<Carton>)

=item * Plack/PSGI using the L<Starman> preforking HTTP server listening on localhost

=item * Apache and/or nginx are utilized as front-end HTTP proxies

=item * Application may be preloaded (using Starman's --preload-app)

=item * Application does not require root privileges

=back

=head2 Directory structure

The package is installed under C</srv/$PACKAGE>.  Though Debian policy
generally forbids packages from installing into /srv, PerlbrewStarman
was written for third-party distribution, not for inclusion into Debian.
This may change.

By default, your application must conform to the following directory
structure:

=over 4

=item * perl environment in C<perlbrew>

=item * application configuration in C<config>

=item * Apache and/or nginx configuration in C<config/apache/$PACKAGE.conf> and/or C<config/nginx/$PACKAGE.conf>

=item * PSGI and other application scripts in C<script>

=item * application libraries in C<lib>

=item * application templates in C<root>

=back

Only files located in these directories will be installed.  Additional
files may be added to the is list by specifying a path to an alternative
install control file using C<install_template>.  The default install
template looks like this:

    config/* srv/{$package_name}/config
    lib/* srv/{$package_name}/lib
    root/* srv/{$package_name}/root
    script/* srv/{$package_name}/script
    perlbrew/* srv/{$package_name}/perlbrew

The package name is substituted for {$package_name} by Text::Template
via L<Dist::Zilla::Plugin::Dpkg>.

Paths may also be removed, but note that the only path in the default
directory structure that is not utilized elsewhere by PerlbrewStarman
is C<root/*>.

=head2 Other paths

PerlbrewStarman creates a number of files under C</etc> in order to
integrate with init as well as the front-end HTTP proxy.  The directory
C</var/log/$PACKAGE> and the link C</etc/$PACKAGE> are created as
normalized locations for log files and app configuration, respectively.
These paths should be intuitively familiar for most UNIX administrators.

Following is a complete list of files and symlinks created:

=over 4

=item * /etc/init.d/$PACKAGE

=item * /etc/default/$PACKAGE

=item * /var/log/$PACKAGE

=item * /etc/apache2/sites-available/$PACKAGE => /srv/$PACKAGE/config/apache/$PACKAGE.conf

=item * /etc/nginx/sites-available/$PACKAGE => /srv/$PACKAGE/config/nginx/$PACKAGE.conf

=item * /etc/$PACKAGE => /srv/$PACKAGE/config

=back

=head2 Environment

By default, C</srv/$PACKAGE/perlbrew/bin> is prepended to the C<PATH> by
way of the C<PERLBREW_PATH> variable in C</etc/default/$PACKAGE>.  The
C<starman> binary must be present in the path, else the service will
fail to start.

The application runs as user $PACKAGE by way of the --user argument to
L<Starman>.  Starman flags are specified by the C<DAEMON_ARGS> variable
in C</etc/default/$PACKAGE>.

=head1 SEE ALSO

* L<Dist::Zilla::Plugin::ChangelogFromGit::Debian>
* L<Dist::Zilla::Deb>

=head1 ATTRIBUTES

=head2 starman_port

The port to use for starman (required).

=head2 starman_workers

The number of starman workers (5 by default).

=head2 psgi_script

Location of the psgi script started by starman. By default this is
C<script/$PACKAGE.psgi>.

=head2 startup_time

The amount of time (in seconds) that the init script will wait on startup. Some
applications may require more than the default amount of time (30 seconds).

=head2 uid

The UID of the user we're adding for the package. This is helpful for syncing
UIDs across multiple installations

=head2 web_server

Set the web server we'll be working with for this package (required).
Supported values are C<apache>, C<nginx>, and C<all> for both..

=head2 apache_modules

Set any additional Apache modules that will need to be enabled.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

