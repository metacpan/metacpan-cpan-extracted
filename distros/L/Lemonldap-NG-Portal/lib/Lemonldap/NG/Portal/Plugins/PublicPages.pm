package Lemonldap::NG::Portal::Plugins::PublicPages;

use strict;
use Mouse;

extends 'Lemonldap::NG::Portal::Main::Plugin';

our $VERSION = '2.0.10';

sub init {
    my ($self) = @_;
    $self->addAuthRoute( public => { ':tpl' => 'run' }, ['GET'] )
      ->addUnauthRoute( public => { ':tpl' => 'run' }, ['GET'] );

    return 1;
}

sub run {
    my ( $self, $req ) = @_;
    my $tpl = $req->param('tpl');

    unless ( $tpl =~ /^[\w\.\-]+$/ ) {
        $self->userLogger->error("Bad public path $tpl");
        return $self->p->sendError( $req, 'File not found', 404 );
    }

    $tpl = "public/$tpl";
    my $path =
        $self->conf->{templateDir} . '/'
      . $self->conf->{portalSkin}
      . "/$tpl.tpl";

    unless ( -e $path ) {
        $self->userLogger->warn("File not found: $path");
        return $self->p->sendError( $req, 'File not found', 404 );
    }
    return $self->p->sendHtml( $req, $tpl );
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Lemonldap::NG::Portal::Plugins::PublicPages - LLNG portal plugin that allows
one to publish HTML pages using LLNG framework
system.

=head1 SYNOPSIS

=over

=item Add "C<customPlugins = ::Plugins::PublicPages>" in your lemonldap-ng.ini
file

=item Create a "public" subdir in your template directory

=item Create your .tpl files inside

=item To access them, use "http://auth.your.domain/public/name" where "name" is
the template name

=back

=head1 DESCRIPTION

Lemonldap::NG::Portal::Plugins::PublicPages is a simple LLNG portal plugin that
allows one to publish HTML pages using LLNG portal framework. See SYNOPSIS for
more.

=head1 SEE ALSO

Most of the documentation is available on the website
L<http://lemonldap-ng.org>

=head2 OTHER POD FILES

=over

=item Writing an authentication module: L<Lemonldap::NG::Portal::Auth>

=item Writing a UserDB module: L<Lemonldap::NG::Portal::UserDB>

=item Writing a second factor module: L<Lemonldap::NG::Portal::Main::SecondFactor>

=item Writing an issuer module: L<Lemonldap::NG::Portal::Main::Issuer>

=item Writing another plugin: L<Lemonldap::NG::Portal::Main::Plugin>

=item Request object: L<Lemonldap::NG::Portal::Main::Request>

=item Adding parameters in the manager: L<Lemonldap::NG::Manager::Build>

=back

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
