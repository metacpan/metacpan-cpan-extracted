package Lemonldap::NG::Handler::PSGI;

use 5.10.0;
use Mouse;

extends 'Lemonldap::NG::Handler::PSGI::Base', 'Lemonldap::NG::Common::PSGI';

our $VERSION = '1.9.1';

sub init {
    my $tmp = $_[0]->Lemonldap::NG::Common::PSGI::init( $_[1] )
      and $_[0]->Lemonldap::NG::Handler::PSGI::Base::init( $_[1] );
    return $tmp;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Handler::PSGI - Base library for protected PSGI applications.

=head1 SYNOPSIS

  package My::PSGI;
  
  use base Lemonldap::NG::Handler;
  
  sub init {
    my ($self,$args) = @_;
    $self->protection('manager');
    # See Lemonldap::NG::Common::PSGI for more
    ...
    # Return a boolean. If false, then error message has to be stored in
    # $self->error
    return 1;
  }
  
  sub handler {
    my ( $self, $req ) = @_;

    # Will be called only if authorisated
    my $userId = $self->userId;
    ...
    $self->sendJSONresponse(...);
  }

This package could then be called as a CGI, using FastCGI,...

  #!/usr/bin/env perl
  
  use My::PSGI;
  use Plack::Handler::FCGI; # or Plack::Handler::CGI

  Plack::Handler::FCGI->new->run( My::PSGI->run() );

=head1 DESCRIPTION

This package provides base class for Lemonldap::NG protected REST API.

=head1 METHODS

See L<Lemonldap::NG::Common::PSGI> for logging methods, content sending,...

=head2 Accessors

See L<Lemonldap::NG::Common::PSGI::Router> for inherited accessors.

=head3 protection

Level of protection. It can be one of:

=over

=item 'none': no protection

=item 'authenticate': all authenticated users are granted

=item 'manager': access is granted following Lemonldap::NG rules

=back

=head2 Running methods

=head3 user

Returns user session datas. If empty (no protection), returns:

  { _whatToTrace => 'anonymous' }

But if page is protected by server (Auth-Basic,...), it will return:

  { _whatToTrace => $REMOTE_USER }

=head3 UserId

Returns user()->{'_whatToTrace'}.

=head3 group

Returns a list of groups to which user belongs.

=head1 SEE ALSO

L<http://lemonldap-ng.org/>, L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Handler>,
L<Plack>, L<PSGI>, L<Lemonldap::NG::Common::PSGI::Router>,
L<Lemonldap::NG::Common::PSGI::Request>, L<HTML::Template>, 

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
