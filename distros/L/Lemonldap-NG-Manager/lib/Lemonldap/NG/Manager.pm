# Manager main component
#
# This package contains these parts:
#  - Properties and private methods
#  - Initialization method (launched by Lemonldap::NG::Common::PSGI)
#    that declares routes
#  - Upload methods (launched by Lemonldap::NG::Common::PSGI::Router)
#
# It inherits from Conf.pm to responds to display methods and from
# Sessions.pm to manage sessions
package Lemonldap::NG::Manager;

use strict;
use utf8;
use Mouse;
use JSON;
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::PSGI::Constants;

our $VERSION = '2.21.2';

extends qw(
  Lemonldap::NG::Handler::PSGI::Router
  Lemonldap::NG::Common::Conf::AccessLib
);

has csp            => ( is => 'rw' );
has loadedPlugins  => ( is => 'rw', default => sub { [] } );
has hLoadedPlugins => ( is => 'rw', default => sub { {} } );

## @method boolean init($args)
# Launch initialization method
#
# @param $args hashref to merge with object
# @return 0 in case of error, 1 else
sub init {
    my ( $self, $args ) = @_;
    $args ||= {};

    if ( my $localconf = $self->confAcc->getLocalConf(MANAGERSECTION) ) {
        foreach ( keys %$localconf ) {
            $args->{$_} //= $localconf->{$_};
            $self->{$_} = $args->{$_} unless (/^(?:l|userL)ogger$/);
        }
    }

    # Manager needs to keep new Ajax behaviour
    $args->{noAjaxHook} = 0;

    return 0
      unless ( $self->Lemonldap::NG::Handler::PSGI::Router::init($args) );

    # TODO: manage errors
    unless ( -r $self->{templateDir} ) {
        $self->error("Unable to read $self->{templateDir}");
        return 0;
    }

    my $conf = $self->confAcc->getConf;
    $conf->{$_} = $args->{$_} foreach ( keys %$args );

    $self->{enabledModules} ||= "conf, sessions, notifications, 2ndFA, api";
    my @links;
    my @enabledModules =
      map {
        my @res = ( "Lemonldap::NG::Manager::" . ucfirst($_) );
        if ( my $tmp = $self->loadPlugin( @res, $conf ) ) {
            $self->logger->debug("Plugin $_ loaded");
            push @links,                    $_;
            push @{ $self->loadedPlugins }, $tmp;
            $self->hLoadedPlugins->{$_} = $tmp;
        }
        else {
            $self->logger->error("Unable to load $_, skipping");
            @res = ();
        }
        (@res);
      }
      split( /[,\s]+/, $self->{enabledModules} );
    unless (@enabledModules) {
        $self->logger->error('No plugins loaded, aborting');
        return 0;
    }
    unless ($conf) {
        require Lemonldap::NG::Manager::Conf::Zero;
        $conf = Lemonldap::NG::Manager::Conf::Zero::zeroConf();
    }

    # TODO: -> loadPlugin
    #for ( my $i = 0 ; $i < @enabledModules ; $i++ ) {
    #    my $mod = $enabledModules[$i];
    #    no strict 'refs';
    #    if ( &{"${mod}::addRoutes"}( $self, $conf ) ) {
    #        $self->logger->debug("Module $mod enabled");
    #        push @working, $mod;
    #    }
    #    else {
    #        $links[$i] = undef;
    #        $self->logger->error(
    #            "Module $mod can not be enabled: " . $self->error );
    #    }
    #}
    $self->addRoute( links     => 'links',  ['GET'] );
    $self->addRoute( 'psgi.js' => 'sendJs', ['GET'] );

    my $portal = $conf->{portal};
    $portal =~ s#https?://([^/]*).*#$1#;
    $self->csp(
        "default-src 'self' $portal;frame-ancestors 'none';form-action 'self';"
    );

    # Avoid restricted users to access configuration by default route
    my $defaultMod = $self->{defaultModule} =
      $self->{defaultModule} || $enabledModules[0];
    $self->logger->debug("Default module -> $defaultMod");
    my ($index) =
      grep { $enabledModules[$_] eq $defaultMod } ( 0 .. $#enabledModules );
    $index //= 0;
    $self->logger->debug("Default index -> $index");
    $self->defaultRoute( $self->loadedPlugins->[$index]->defaultRoute );

    $self->links( [] );
    for ( my $i = 0 ; $i < @links ; $i++ ) {
        next unless ( defined $links[$i] );
        push @{ $self->links },
          {
            target => $self->loadedPlugins->[$i]->defaultRoute,
            title  => $links[$i],
            icon   => $self->loadedPlugins->[$i]->icon,
          };
    }

    $self->menuLinks( [] );
    if (
        my $portal =
        $conf->{cfgNum}
        ? Lemonldap::NG::Handler::PSGI::Main->tsv->{portal}->()
        : $conf->{portal}
      )
    {
        $portal = $self->customPortalUrl || $portal;
        push @{ $self->menuLinks },
          {
            target => $portal,
            title  => 'backtoportal',
            icon   => 'home'
          },
          {
            target => "$portal?logout=1",
            title  => 'logout',
            icon   => 'log-out'
          };
    }
    1;
}

sub tplParams {
    my ( $self, $req ) = @_;
    my $res = eval {
        $self->hLoadedPlugins->{viewer}->brwRule->( $req, $req->{userData} );
    } || 0;
    return (
        VERSION      => $VERSION,
        ALLOWBROWSER => $res,
        DOC_PREFIX   => ( $self->{docPrefix} || '/doc' ),
    );
}

sub javascript {
    my ( $self, $req ) = @_;
    my $res = eval {
             $self->hLoadedPlugins->{viewer}
          && $self->hLoadedPlugins->{viewer}
          ->diffRule->( $req, $req->{userData} );
    } || 0;
    print STDERR $@ if $@;
    my $impPrefix = $self->{impersonationPrefix} || 'real_';
    my $ttl       = $self->{timeout}             || 72000;

    return
'var formPrefix=staticPrefix+"forms/";var confPrefix=scriptname+"confs/";var viewPrefix=scriptname+"view/";'
      . "var allowDiff=$res;"
      . "var sessionTTL=$ttl;"
      . "var impPrefix='$impPrefix';"
      . ( $self->links ? 'var links=' . to_json( $self->links ) . ';' : '' )
      . (
        $self->menuLinks
        ? 'var menulinks=' . to_json( $self->menuLinks ) . ';'
        : ''
      );
}

sub sendHtml {
    my ( $self, $req, $template, %args ) = @_;
    my $res = $self->SUPER::sendHtml( $req, $template, %args );
    push @{ $res->[1] },
      'Content-Security-Policy' => $self->csp,
      'X-Content-Type-Options'  => 'nosniff',
      'X-Frame-Options'         => 'DENY',
      'X-XSS-Protection'        => '1; mode=block';
    return $res;
}

sub loadPlugin {
    my ( $self, $plugin, $conf ) = @_;
    unless ($plugin) {
        require Carp;
        Carp::confess('Calling loadPugin without arg !');
    }
    my $obj;
    $plugin = "Lemonldap::NG::Manager$plugin" if ( $plugin =~ /^::/ );

    eval "require $plugin";
    if ($@) {
        $self->logger->error("$plugin load error: $@");
        return 0;
    }
    eval {
        $obj = $plugin->new( { p => $self, conf => $conf } );
        $self->logger->debug("Module $plugin loaded");
    };
    if ($@) {
        $self->error("Unable to build $plugin object: $@");
        return 0;
    }
    ( $obj and $obj->init($conf) ) or return 0;
    return $obj;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Manager - Perl extension for managing Lemonldap::NG Web-SSO
system.

=head1 SYNOPSIS

Use any of Plack launcher. Example:

  #!/usr/bin/env plackup
  
  use Lemonldap::NG::Manager;
  
  # This must be the last instruction ! See PSGI for more
  Lemonldap::NG::Manager->run($opts);

=head1 DESCRIPTION

Lemonldap::NG::Manager provides a web interface to manage Lemonldap::NG Web-SSO
system.

The Perl part of Lemonldap::NG::Manager is the REST server. Web interface is
written in Javascript, using AngularJS framework and can be found in `site`
directory. The REST API is described in REST-API.md file provided in source tree.

Lemonldap::NG Manager uses L<Plack> to be CGI, FastCGI and so on compatible.
It inherits of L<Lemonldap::NG::Handler::PSGI::Router>

=head1 ORGANIZATION

Lemonldap::NG Manager contains 6 parts:

=over

=item Configuration management

=item Session explorer

=item Notification explorer

=item Second Factors manager

=item Configuration builder (see L<Lemonldap::NG::Manager::Build>

=item Command line interface (see L<Lemonldap::NG::Manager::Cli>

=back

=head2 Static files generation

`scripts/jsongenerator.pl` file uses Lemonldap::NG::Manager::Build::Attributes,
Lemonldap::NG::Manager::Build::Tree and Lemonldap::NG::Manager::Build::CTrees to generate

=over

=item `site/htdocs/static/struct.json`:

main file containing the tree view;

=item `site/htdocs/static/js/conftree.js`:

generates Virtualhosts, SAML and OpenID-Connect partners sub-trees;

=item `Lemonldap::NG::Common::Conf::ReConstants`:

constants used by all Perl manager components;

=item `Lemonldap::NG::Common::Conf::DefaultValues`:

constants used to read configuration.

=back

=head1 PARAMETERS

You can use a hash ref to override any LemonLDAP::NG parameter. Currently, you
can specify where your lemonldap-ng.ini file is:

  Lemonldap::NG::Manager->run( { confFile => '/path/to/lemonldap-ng.ini' } );

=head2 lemonldap-ng.ini parameters

You can override any configuration parameter in lemonldap-ng.ini, but some are
required and can't be set to global configuration (as any Lemonldap::NG module,
you can also fix them in $opts hash ref passed as argument to run() or new()).

  [manager]
  ;protection:     choose one of none, authenticate, manager as explain in
  ;                Lemonldap::NG::Handler::PSGI::Router doc.
  protection     = manager
  
  ;enabledModules: Modules to display. Default to `conf, sessions, notifications, 2ndFA`
  enabledModules = conf, sessions, notifications, 2ndFA
  
  ;logLevel:       choose one of error, warn, notice, info, debug
  ;                See Lemonldap::NG::Common::PSGI doc for more
  logLevel       = notice
  
  ;staticPrefix:   set here the URI path to static content
  ;                See Lemonldap::NG::Common::PSGI doc for more
  staticPrefix   = static/
  
  ;languages:      Available interface languages
  languages      = en, fr
  
  ;templateDir:    path to the directory containing HTML templates
  ;                See Lemonldap::NG::Common::PSGI doc for more
  templateDir    = /usr/share/lemonldap-ng/manager/

=head1 SEE ALSO

L<http://lemonldap-ng.org/>

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

Note that if you want to post a ticket for a conf upload problem, please
see L<Lemonldap::NG::Manager::Conf::Parser> before.

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

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
