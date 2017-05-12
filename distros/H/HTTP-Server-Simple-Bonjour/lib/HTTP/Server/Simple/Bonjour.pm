package HTTP::Server::Simple::Bonjour;

use strict;
use 5.8.1;
our $VERSION = '0.02';

use Carp;
use NEXT;

my $publisher = eval {
    require Net::Rendezvous::Publish;
    Net::Rendezvous::Publish->new;
};

sub print_banner {
    my $self = shift;

    unless ($publisher) {
        carp "Publisher backend is not available. Install one of Net::Rendezvous::Publish::Backend modules from CPAN.";
        $self->NEXT::print_banner;
        return;
    }

    $publisher->publish(
        name => $self->service_name,
        type => $self->service_type,
        port => $self->port,
        domain => 'local',
    );

    $self->NEXT::print_banner;
}

sub service_name {
    my $self = shift;
    require Sys::Hostname;
    return Sys::Hostname::hostname();
}


sub service_type { '_http._tcp' }


1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

HTTP::Server::Simple::Bonjour - Bonjour plugin for HTTP::Server::Simple

=head1 SYNOPSIS

  package MyServer;
  # You need to put ::Bonjour first so NEXT can work properly
  use base qw( HTTP::Server::Simple::Bonjour HTTP::Server::Simple::CGI );

  sub service_name { "My awesome webserver" }

  MyServer->new->run;

=head1 DESCRIPTION

HTTP::Server::Simple::Bonjour is an HTTP::Server::Simple plugin to
publish the server name and TCP port via Bonjour so anyone in the
local network can discover your web server.

=head1 METHODS

=head2 service_name 

This method returns the name of the webserver your server wants to advertise

=head2 service_type

This method returns the bonjour service for your application.  Most HTTP 
servers can safely leave this untouched. Override it and return something 
of the form '_http._tcp' if you need to.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@cpan.orgE<gt>

Jesse Vincent

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Server::Simple> L<Net::Rendezvous::Publish>

=cut
