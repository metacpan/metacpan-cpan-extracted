#!/usr/bin/env perl
package HTTP::Server::Simple::WebDAO;
use strict;
use warnings;
use HTTP::Server::Simple::CGI;
use base qw/HTTP::Server::Simple::CGI/;
use WebDAO;
use WebDAO::Util;
use WebDAO::Engine;
use WebDAO::Session;
use vars qw($VERSION);
$VERSION = '0.04';

=head1 NAME

HTTP::Server::Simple::WebDAO - WebDAO handler for HTTP::Server::Simple

=head1 SYNOPSIS

    HTTP::Server::Simple::WebDAO;

    my $srv = new HTTP::Server::Simple::WebDAO::($port);
    $srv->set_config( wdEngine => "Plosurin::HTTP", wdDebug => 3 );
    $srv->run();

=head1 DESCRIPTION

HTTP::Server::Simple::WebDAO is a HTTP::Server::Simple based HTTP server
that can run WebDAO applications. This module only depends on
L<HTTP::Server::Simple>, which itself doesn't depend on any non-core
modules so it's best to be used as an embedded web server.

=head1 SEE ALSO

L<HTTP::Server::Simple>, L<WebDAO>


=head1 AUTHOR

Zahatski Aliaksandr

=head1 LICENSE

Copyright 2011-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->set_config;
    return $self;
}


sub set_config {
    my $self = shift;
    my %args = @_;
    while ( my ( $k, $v ) = each %args ) {
        $self->{$k} = $v;
    }
    $ENV{wdSession} ||= $args{wdSession};
    $ENV{wdEngine}  ||= $args{wdEngine};
    #preload defaults
    $self->{ini} = WebDAO::Util::get_classes(__env => \%ENV, __preload=>1);
 
    $self;
}

sub handle_request {
    my ( $self, $cgi ) = @_;
    my $ini = $self->{ini};
    my $sess = "$ini->{wdSession}"->new(
        %{ $ini->{wdSessionPar} },
        cv    => HTTP::Server::Simple::WebDAO::CVcgi->new(env=>\%ENV)
    );

    my $eng = "$ini->{wdEngine}"->new(
        %{ $ini->{wdEnginePar} },
        session => $sess,
    );
    $ENV{wdDebug} = $self->{wdDebug} if exists $self->{wdDebug};
    $sess->ExecEngine($eng);
    $sess->destroy;

}
package HTTP::Server::Simple::WebDAO::CVcgi;
use strict;
use warnings;
use WebDAO::CVfcgi;
use WebDAO::Util;
use base qw/WebDAO::CVfcgi/;
use vars qw($VERSION);
$VERSION = '0.01';
sub new {
    my $class = shift;
    return $class->WebDAO::CV::new(@_, writer=> sub {
        my $code = $_[0]->[0];
        my $headers_ref  = $_[0]->[1];
        my $fd = new WebDAO::Fcgi::Writer:: headers=>$headers_ref;
        my $message = $WebDAO::Util::HTTPStatusCode{$code};
        my $header_str= "HTTP/1.0 $code $message\015\012";
        while ( my ($header, $value) = splice( @$headers_ref, 0, 2) ) {
            $header_str .= "$header: $value\015\012"
        }
        $header_str .="\015\012";
        $fd->write($header_str);
        return $fd
    } )
}

package HTTP::Server::Simple::WebDAO;
1;
