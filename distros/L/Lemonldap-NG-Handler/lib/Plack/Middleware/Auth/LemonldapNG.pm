package Plack::Middleware::Auth::LemonldapNG;

our $AUTHORITY = 'cpan:GUIMARD';
our $VERSION   = '2.0';
our $llclass   = 'Lemonldap::NG::Handler::Server';

use strict;
use base qw(Plack::Middleware);
use Plack::Util;
use Plack::Util::Accessor qw(
  llhandler
  llparams
  on_reject
);

sub prepare_app {
    my ($self) = @_;
    Plack::Util::load_class($llclass);
    $self->llhandler( $llclass->run( $self->llparams ) );
}

sub call {
    my ( $self, $env ) = @_;
    my $res    = $self->llhandler->($env);
    my $rejApp = $self->on_reject;
    unless ( $res->[0] == 200 ) {
        if ($rejApp) {
            return $self->$rejApp( $env, $res );
        }
        else {
            return $res;
        }
    }
    my $app  = $self->app;
    my %hdrs = @{ $res->[1] };
    foreach ( keys %hdrs ) {
        $env->{$_} = 'HTTP_' . uc( $hdrs{$_} ) foreach ( keys %hdrs );
    }
    @_ = $env;
    goto $app;
}

__PACKAGE__;
__END__

=pod

=encoding utf8

=head1 NAME

Plack::Middleware::Auth::LemonldapNG - authentication middleware for Lemonldap-NG

=head1 SYNOPSIS

  use Plack::Builder;
  
  my $app   = sub { ... };

  # Optionally ($proposedResponse is the PSGI response of Lemonldap::NG handler)
  #sub on_reject {
  #    my($self,$env,$proposedResponse) = @_;
  #    ...
  #}
  
  builder
  {
    enable "Auth::LemonldapNG";
    # Or with some LLNG args or a reject sub
    #enable "Auth::LemonldapNG",
    #  llparams => {
    #    configStorage => ...
    #  },
    #  on_reject => \&on_reject;
    $app;
  };

=head1 DESCRIPTION

Lemonldap::NG is a modular Web-SSO based on Apache::Session modules. It
simplifies the build of a protected area with a few changes in the application.

It manages both authentication and authorization and provides headers for
accounting. So you can have a full AAA protection for your web space as
described below.

Plack::Middleware::Auth::LemonldapNG provides the module to protect a L<Plack>
family server.

=head1 SEE ALSO

L<http://lemonldap-ng.org>, L<Plack>, L<Plack::Middleware>

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

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
