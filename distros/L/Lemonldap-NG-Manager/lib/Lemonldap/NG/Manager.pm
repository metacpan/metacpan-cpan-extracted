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

use 5.10.0;
use utf8;
use Mouse;
our $VERSION = '1.9.13';
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::PSGI::Constants;

extends 'Lemonldap::NG::Manager::Lib', 'Lemonldap::NG::Handler::PSGI::Router';

has csp => ( is => 'rw' );

## @method boolean init($args)
# Launch initialization method
#
# @param $args hashref to merge with object
# @return 0 in case of error, 1 else
sub init {
    my ( $self, $args ) = @_;
    $args ||= {};

    my $conf = $self->confAcc;

    if ( my $localconf = $conf->getLocalConf(MANAGERSECTION) ) {
        $self->{$_} = $args->{$_} // $localconf->{$_}
          foreach ( keys %$localconf );
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

    $self->{enabledModules} ||= "conf, sessions, notifications";
    my @links;
    my @enabledModules =
      map { push @links, $_; "Lemonldap::NG::Manager::" . ucfirst($_) }
      split( /[,\s]+/, $self->{enabledModules} );
    extends 'Lemonldap::NG::Handler::PSGI::Router', @enabledModules;
    my @working;
    for ( my $i = 0 ; $i < @enabledModules ; $i++ ) {
        my $mod = $enabledModules[$i];
        no strict 'refs';
        if ( &{"${mod}::addRoutes"}($self) ) {
            $self->lmLog( "Module $mod enabled", 'debug' );
            push @working, $mod;
        }
        else {
            $links[$i] = undef;
            $self->lmLog( "Module $mod can not be enabled: " . $self->error,
                'error' );
        }
    }
    return 0 unless (@working);
    $self->addRoute( links => 'links', ['GET'] );

    my $portal = $Lemonldap::NG::Handler::Main::tsv->{portal}->();
    $portal =~ s#https?://([^/]*).*#$1#;
    $self->csp(
"default-src 'self';frame-ancestors 'none';form-action 'self';img-src 'self' $portal;style-src 'self' $portal;"
    );

    $self->defaultRoute( $working[0]->defaultRoute );

    my $linksIcons =
      { 'conf' => 'cog', 'sessions' => 'duplicate', 'notifications' => 'bell' };

    $self->links( [] );
    for ( my $i = 0 ; $i < @links ; $i++ ) {
        next unless ( defined $links[$i] );
        push @{ $self->links },
          {
            target => $enabledModules[$i]->defaultRoute,
            title  => $links[$i],
            icon   => $linksIcons->{ $links[$i] }
          };
    }

    $self->menuLinks( [] );
    push @{ $self->menuLinks },
      {
        target => &{ $Lemonldap::NG::Handler::SharedConf::tsv->{portal} },
        title  => 'backtoportal',
        icon   => 'home'
      }
      if ( defined $Lemonldap::NG::Handler::SharedConf::tsv->{portal} );
    push @{ $self->menuLinks },
      {
        target => &{ $Lemonldap::NG::Handler::SharedConf::tsv->{portal} }
          . '?logout=1',
        title => 'logout',
        icon  => 'log-out'
      }
      if ( defined $Lemonldap::NG::Handler::SharedConf::tsv->{portal} );
    1;
}

sub tplParams {
    return ( VERSION => $VERSION, );
}

sub javascript {
    my ($self) = @_;
    return
      'var formPrefix=staticPrefix+"forms/";var confPrefix=scriptname+"confs/";'
      . (
        $self->links ? 'var links=' . JSON::to_json( $self->links ) . ';' : '' )
      . (
        $self->menuLinks
        ? 'var menulinks=' . JSON::to_json( $self->menuLinks ) . ';'
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

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Manager - Perl extension for managing Lemonldap::NG Web-SSO
system.

=head1 SYNOPSIS

  #!/usr/bin/env plackup -I pl/lib
  
  use Lemonldap::NG::Manager;
  
  # This must be the last instruction ! See PSGI for more
  Lemonldap::NG::Manager->run($opts);

=head1 DESCRIPTION

Lemonldap::NG::Manager provides a web interface to manage Lemonldap::NG Web-SSO
system.

The Perl part of Lemonldap::NG::Manager is the REST server. Web interface is
written in Javascript, using AngularJS framework and can be found in `site`
directory. The REST API is described in REST-API.md file given in source tree.

Lemonldap::NG Manager uses L<Plack> to be compatible with CGI, FastCGI,... It
inherits of L<Lemonldap::NG::Handler::PSGI::Router>

=head1 ORGANIZATION

Lemonldap::NG Manager contains 4 parts:

=over

=item Configuration management:

see L<Lemonldap::NG::Manager::Conf>;

=item Session explorer:

see L<Lemonldap::NG::Manager::Sessions>;

=item Notification explorer:

see L<Lemonldap::NG::Manager::Notifications>;

=item Some files uses to generate static files:

see below.

=back

=head2 Generation of static files

The `scripts/jsongenerator.pl` file uses Lemonldap::NG::Manager::Build::Attributes,
Lemonldap::NG::Manager::Build::Tree and Lemonldap::NG::Manager::Build::CTrees to generate

=over

=item `site/static/struct.json`:

the main file that contains the tree view;

=item `site/static/js/conftree.js`:

generates sub tree for virtualhosts and SAML and OpenID-Connect partners;

=item `Lemonldap::NG::Manager::Constants`:

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
  
  ;enabledModules: Modules to display. Default to `conf, sessions, notifications`
  enabledModules = conf, sessions, notifications
  
  ;logLevel:       choose one of error, warn, notice, info, debug
  ;                See Lemonldap::NG::Common::PSGI doc for more
  logLevel       = notice
  
  ;staticPrefix:   set here the URI path to static content
  ;                See Lemonldap::NG::Common::PSGI doc for more
  staticPrefix   = static/
  
  ;languages:      Available interface languages
  languages      = en, fr
  
  ;templateDir:    the path to the directory containing HTML templates
  ;                See Lemonldap::NG::Common::PSGI doc for more
  templateDir    = /usr/share/lemonldap-ng/manager/

=head1 SEE ALSO

L<Lemonldap::NG::Handler::Router>, L<Lemonldap::NG::Portal>, L<Plack>, L<PSGI>,
L<Lemonldap::NG::Manager::Conf>, L<Lemonldap::NG::Manager::Sessions>,
L<Lemonldap::NG::Manager::Notifications>
L<http://lemonldap-ng.org/>

=head1 AUTHORS

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2015-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2015-2016 by Clément Oudot, E<lt>clem.oudot@gmail.comE<gt>

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
