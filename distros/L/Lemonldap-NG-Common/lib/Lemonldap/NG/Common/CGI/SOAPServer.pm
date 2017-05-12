## @file
# SOAP support for Lemonldap::NG::Common::CGI

## @class
# Extend SOAP::Transport::HTTP::Server to be able to use posted datas catched
# by CGI module.
# All Lemonldap::NG cgi inherits from CGI so with this library, they can
# understand both browser and SOAP requests.
package Lemonldap::NG::Common::CGI::SOAPServer;
use SOAP::Transport::HTTP;
use base qw(SOAP::Transport::HTTP::Server);
use bytes;

our $VERSION = '1.9.1';

## @method protected void DESTROY()
# Call SOAP::Trace::objects().
sub DESTROY { SOAP::Trace::objects('()') }

## @cmethod Lemonldap::NG::Common::CGI::SOAPServer new(@param)
# @param @param SOAP::Transport::HTTP::Server::new() parameters
# @return Lemonldap::NG::Common::CGI::SOAPServer object
sub new {
    my $self = shift;
    return $self if ref $self;

    my $class = ref($self) || $self;
    $self = $class->SUPER::new(@_);
    SOAP::Trace::objects('()');

    return $self;
}

## @method void handle(CGI cgi)
# Build SOAP request using CGI->param('POSTDATA') and call
# SOAP::Transport::HTTP::Server::handle() then return the result to the client.
# @param $cgi CGI object
sub handle {
    my $self = shift->new;
    my $cgi  = shift;

    my $content = $cgi->param('POSTDATA');
    my $length  = bytes::length($content);

    if ( !$length ) {
        $self->response( HTTP::Response->new(411) )    # LENGTH REQUIRED
    }
    elsif ( defined $SOAP::Constants::MAX_CONTENT_SIZE
        && $length > $SOAP::Constants::MAX_CONTENT_SIZE )
    {
        $self->response( HTTP::Response->new(413) )   # REQUEST ENTITY TOO LARGE
    }
    else {
        $self->request(
            HTTP::Request->new(
                'POST' => $ENV{'SCRIPT_NAME'},
                HTTP::Headers->new(
                    map {
                        (
                              /^HTTP_(.+)/i
                            ? ( $1 =~ m/SOAPACTION/ )
                                  ? ('SOAPAction')
                                  : ($1)
                            : $_
                          ) => $ENV{$_}
                    } keys %ENV
                ),
                $content,
            )
        );
        $self->SUPER::handle();
    }

    print $cgi->header(
        -status => $self->response->code . " "
          . HTTP::Status::status_message( $self->response->code ),
        -type           => $self->response->header('Content-Type'),
        -Content_Length => $self->response->header('Content-Length'),
        -SOAPServer     => 'Lemonldap::NG CGI',
    );
    binmode( STDOUT, ":bytes" );
    print $self->response->content;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Common::CGI::SOAPServer - Extends L<SOAP::Lite> to be compatible
with L<CGI>.

=head1 SYNOPSIS

  use CGI;
  use Lemonldap::NG::Common::CGI::SOAPServer;
  
  my $cgi = CGI->new();
  Lemonldap::NG::Common::CGI::SOAPServer->dispatch_to('same as SOAP::Lite')
     ->handle($cgi)

=head1 DESCRIPTION

This extension just extend L<SOAP::Lite> handle() method to load datas from
a L<CGI> object instead of STDIN.

=head1 SEE ALSO

L<http://lemonldap-ng.org/>, L<Lemonldap::NG::Common::CGI>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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

=item Copyright (C) 2008-2010 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2010-2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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
