package Hessian::Client;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use Contextual::Return;
use Hessian::Exception;
use Hessian::Translator;
use Class::Std;
{
    my %service : ATTR(:name<service>);
    my %version : ATTR(:get<version> :init_arg<version>);
    my %hessian_translator : ATTR(:get<translator> :set<translator>);

    sub BUILD {    #{{{
        my ( $self, $id, $args ) = @_;
        my $hessian = Hessian::Translator->new( version => $args->{version} );
        $self->set_translator($hessian);
    }

    sub AUTOMETHOD {    #{{{
        my ( $self, $id, @args ) = @_;
        my $method_name = $_;

        return sub {
            my $datastructure = {
                call => {
                    method    => $method_name,
                    arguments => \@args

                },
            };
            return $self->_call_remote($datastructure);
          }

    }

    sub _call_remote {    #{{{
        my ( $self, $datastructure ) = @_;
        my $service = $self->get_service();
        ServiceException->throw( error => "No service defined." )
          unless $service;
        my $request = HTTP::Request->new( 'POST', $service );
        my $hessian = $self->get_translator();
        $hessian->serializer();
        my $hessian_string = $hessian->serialize_message($datastructure);
        $request->content($hessian_string);
        my $agent    = LWP::UserAgent->new();
        my $response = $agent->request($request);

        if ( $response->is_success() ) {
            my $content = $response->content();
            $hessian->input_string($content);
            my $processed = $hessian->process_message();
            return $processed;
        }
        ServiceException->throw( error => "No reponse from " . $service );

    }

}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Client - RPC via Hessian with a remote server.


=head1 SYNOPSIS

 use Hessian::Client;

 my $client = Hessian::Client->new(
    version => 1,
    service => 'http://some.hessian.service/.....'
 );

 # Alternatively
 my $client = Hessian::Client->new(
    version => 2,
    service => 'http://some.hessian.service/.....'
 );

 
 # RPC 
 my $response = $hessian->remoteCall($arg1, $arg2, $arg3, ...);

=head1 DESCRIPTION

The goal of Hessian::Client and all associated classes in this namespace is to
provide support for communication via the Hessian protocol in Perl.  

Hessian is a binary protocol optimized for communication in situations where
it is necessary to preserve bandwidth such as in mobile web services. Due to
the concise nature of the API, implementations of the Hessian protocol can be
found in several languages including Java, Python, Ruby, Erlang and PHP. For some
reason, till now there has been no implementation in Perl.

For a more detailed introduction into the Hessian protocol, see the main
project documentation at http://www.caucho.com/resin-3.1/doc/hessian.xtp and
http://hessian.caucho.com/doc/hessian-ws.html.

Hessian::Client implements basic RPC for Hessian. Although currently only
tested with version 1, communication with version 2.0 servers should also
work. I am currently looking for publicly available or otherwise accesible
Hessian services for testing.


I probably should note that although the package was submitted under the name
L<Hessian::Client>, the real work is actually done in
L<Hessian::Translator|Hessian::Translator> and its associated subclasses and
roles.  In fact, I will most likely change the package name to
C<Hessian::Translator> and submit this as a separate module at
some point in the near future.  


=head1 INTERFACE

=head2 new

=over 2

=item 
Arguments

=over 3


=item
version

B<C<1>> or B<C<2>> representing the respective version of Hessian the client
should speak.  


=item
service

A url representing the location of a Hessian server.

=back

=back

=head2 BUILD

Not part of the public interface. See L<Class::Std|Class::Std/"BUILD"> documentation.

=head2 AUTOMETHOD

Not part of the public interface. See L<Class::Std|Class::Std/"AUTOMETHOD">
documentation.

I<Note:> Any method called on the client that is not defined in the public
interface (so anything other than L</"new">) will be processed into a Hessian
call and posted to the service.



=head1 TODO

=over 2

=item *
Testing with a Hessian 2.0 service. If anyone out there would be interested in
helping with this I would be very grateful.


=item *
Work on messaging. RPC is only part of the Hessian protocol.

=item *
Make a POE filter for this perhaps.



=back
