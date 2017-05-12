## @file
# Main portal for Lemonldap::NG portal

## @class
# Main portal for Lemonldap::NG portal
package Lemonldap::NG::Portal::SharedConf;

use strict;
use Lemonldap::NG::Portal::Simple qw(:all);
use Lemonldap::NG::Common::Conf;            #link protected lmConf Configuration
use Lemonldap::NG::Common::Conf::Constants; #inherits
use Regexp::Assemble;
use URI::Split qw(uri_split);

*EXPORT_OK   = *Lemonldap::NG::Portal::Simple::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::Simple::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::Simple::EXPORT;

our $VERSION = '1.4.2';
use base qw(Lemonldap::NG::Portal::Simple);
our $confCached;

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($confCached);
    };
}

##################
# OVERLOADED SUB #
##################

## @method protected boolean getConf(hashRef args)
# Copy all parameters returned by the Lemonldap::NG::Common::Conf object in $self.
# @param args hash
# @return True
sub getConf {
    my $self = shift;
    my %args;
    if ( ref( $_[0] ) ) {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }

    if ( defined( $args{configStorage} ) ) {
        $self->{configStorage} = $args{configStorage};
    }

    my $num;
    my $lConf;

    # If useLocalConf is set, just verify that current conf has the same number
    # than local cache one
    if ( $confCached and $confCached->{useLocalConf} ) {
        $lConf = $self->__lmConf->getLocalConf(PORTALSECTION);
        eval { $num = $lConf->{cfgNum} };
    }
    else {
        $num = $self->__lmConf->lastCfg();
    }

    # Reload configuration
    unless ( $confCached and $confCached->{cfgNum} == $num ) {
        $lConf ||= $self->__lmConf->getLocalConf(PORTALSECTION);
        my $prm = { cfgNum => $num };
        if ( $args{useLocalConf} or $lConf->{useLocalConf} ) {
            $prm->{local} = 1;
            $self->lmLog( 'useLocalConf set to true', 'debug' );
        }
        my $gConf = $self->__lmConf->getConf($prm);
        unless ( ref($gConf) and ref($lConf) ) {
            $self->abort( "Cannot get configuration",
                $Lemonldap::NG::Common::Conf::msg );
        }
        $self->lmLog(
            "Cached configuration too old, get configuration $num "
              . "($Lemonldap::NG::Common::Conf::msg)",
            'debug'
        );
        %$confCached = ( %$gConf, %$lConf );

        my $re = Regexp::Assemble->new();
        foreach my $vhost ( keys %{ $confCached->{locationRules} } ) {
            my $quotedVhost = quotemeta($vhost);
            $self->lmLog( "Vhost $vhost added in reVHosts", 'debug' );
            $re->add($quotedVhost);

            # Add aliases
            if ( $confCached->{vhostOptions}->{$vhost}->{vhostAliases} ) {
                foreach my $alias ( split /\s+/,
                    $confCached->{vhostOptions}->{$vhost}->{vhostAliases} )
                {
                    $self->lmLog( "Alias $alias added in reVHosts", 'debug' );
                    $re->add( quotemeta($alias) );
                }
            }
        }

        # Add portal vhost
        my ( $portal_scheme, $portal_auth ) =
          uri_split( $confCached->{portal} );
        $re->add($portal_auth);
        $self->lmLog( "Portal vhost $portal_auth added in reVHosts", 'debug' );

        $confCached->{reVHosts} = $re->as_string;
    }

    %$self = ( %$self, %$confCached, %args, );

    $self->lmLog( "Now using configuration: " . $confCached->{cfgNum},
        'debug' );

    1;
}

sub __lmConf {
    my $self = shift;
    return $self->{lmConf} if ( $self->{lmConf} );
    my $r = Lemonldap::NG::Common::Conf->new( $self->{configStorage} );
    $self->abort(
        "Cannot create configuration object",
        $Lemonldap::NG::Common::Conf::msg
    ) unless ( ref($r) );
    $self->{lmConf} = $r;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::SharedConf - Module for building Lemonldap::NG
compatible portals using a central configuration database.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::SharedConf( {
         configStorage => {
             type        => 'DBI',
             dbiChain    => "dbi:mysql:...",
             dbiUser     => "lemonldap",
             dbiPassword => "password",
             dbiTable    => "lmConfig",
         },
         # Activate SOAP service
         Soap           => 1
    } );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see L<CGI(3)>)
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    # Write here the html form used to authenticate with CGI methods.
    # $portal->error returns the error message if athentification failed
    # Warning: by defaut, input names are "user" and "password"
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see L<CGI(3)>)
    print "...";
    print '<form method="POST">';
    # In your form, the following value is required for redirection
    print '<input type="hidden" name="url" value="'.$portal->param('url').'">';
    # Next, login and password
    print 'Login : <input name="user"><br>';
    print 'Password : <input name="password" type="password" autocomplete="off">';
    print '<input type="submit" value="go" />';
    print '</form>';
  }

SOAP mode authentication (client) :

  #!/usr/bin/perl -l
  
  use SOAP::Lite;
  use Data::Dumper;
  
  my $soap =
    SOAP::Lite->proxy('http://auth.example.com/')
    ->uri('urn:/Lemonldap::NG::Common::::CGI::SOAPService');
  my $r = $soap->getCookies( 'user', 'password' );
  
  # Catch SOAP errors
  if ( $r->fault ) {
      print STDERR "SOAP Error: " . $r->fault->{faultstring};
  }
  else {
      my $res = $r->result();
  
      # If authentication failed, display error
      if ( $res->{error} ) {
          print STDERR "Error: " . $soap->error( $res->{error} )->result();
      }
  
      # print session-ID
      else {
          print "Cookie: lemonldap=" . $res->{cookies}->{lemonldap};
      }
  }

=head1 DESCRIPTION

Lemonldap::NG::Portal::SharedConf is the base module for building Lemonldap::NG
compatible portals using a central database configuration. You have to use by
inheritance.

See L<Lemonldap::NG::Portal::SharedConf> for a complete example.

=head1 METHODS

Same as L<Lemonldap::NG::Portal::Simple>, but Lemonldap::NG::Portal::SharedConf
adds a new sub:

=over

=item * scanexpr: used by setGroups to read combined LDAP and Perl expressions.
See L<Lemonldap::NG::Portal> for more.

=back

=head3 Args

Lemonldap::NG::Portal::SharedConf use the same arguments than
L<Lemonldap::NG::Portal::Simple>, but you can set them either using local
variables passed to C<new()> or using variables issued from the database.

=head2 EXPORT

=head3 Constants

Same as L<Lemonldap::NG::Portal::Simple>.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::SharedConf>,
L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Manager>,
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

=item Copyright (C) 2006, 2007, 2008, 2009, 2010 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Copyright (C) 2006, 2009, 2010, 2011, 2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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
